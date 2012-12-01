# coding: utf-8
require 'sinatra'
require 'thin'

set server: 'thin', connections: [], priv: {}

get '/' do
   halt erb(:login) unless params[:user]
   erb :chat, locals: { user: params[:user].gsub(/\W/, '') }
end

get '/stream/:user', provides: 'text/event-stream' do
  stream :keep_open do |out|
    settings.connections << out
    settings.priv.store(params[:user].to_s.to_sym, out.__id__)
    settings.connections.each { |out| out << "data: #{Time.now.strftime("%H:%M:%S")} > [#{params[:user]}] ha entrado al chat \n\n" }
    out.callback{ user_to_del = out.__id__
                  settings.connections.delete(out)
                  settings.connections.each { |channel| channel << "data: #{Time.now.strftime("%H:%M:%S")} > [#{settings.priv.key(user_to_del)}] ha salido del chat \n\n"}
                  settings.priv.delete(settings.priv.key(user_to_del))
                 }


  end
end

post '/' do

  message = params[:msg].split
  if !(message[1].to_s =~ /^\/.+:$/)
    settings.connections.each { |out| out << "data: #{Time.now.strftime("%H:%M:%S")} > #{params[:msg]}\n\n" }
  else
     sender = message[0].to_s.delete ":"
     receiver = message[1].to_s.delete "/:"
     id_receiver = settings.priv[receiver.to_sym]
     id_sender = settings.priv[sender.to_sym]
     index_receiver, index_sender = nil, nil
     settings.connections.each { |x| if x.__id__ == id_receiver
                                        index_receiver = settings.connections.index(x)
                                     else if x.__id__ == id_sender
                                        index_sender = settings.connections.index(x)
                                     end
                                  end}
     message.delete_at(0)
     message.delete_at(0)
     settings.connections[index_receiver] << "data: #{Time.now.strftime("%H:%M:%S")} > #{sender}: #{message.join(" ")} (mensaje privado)\n\n"
     settings.connections[index_sender] << "data: #{Time.now.strftime("%H:%M:%S")} > #Mensaje privado para #{receiver}: #{message.join(" ")}\n\n"
   end
  204 # response without entity body
end
