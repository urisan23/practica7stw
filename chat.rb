require 'sinatra'
require 'erb'
set server: 'thin', connections: []

get '/' do
    halt erb(:login) unless params[:user]
    erb :chat, locals: { user: params[:user].gsub(\W/, '') }
end

post '/' do
    settings.connections.each { |out| out << "data: #{params[:msg]\n\n}" }
    204 # response without entity body
end

get '/stream', provides: 'text/event-stream' do
    stream :keep_open do |out|
        settings.connections << out
        out.callback { settings.connections.delete(out) }
    end
end