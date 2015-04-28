require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dark_knight_rises'
helpers do

end


get '/' do
  redirect '/new'
end

get '/new' do
  erb :new
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  session[:num_rounds] = 1
  session[:money] = 1000
  session[:bet] = 0
  redirect '/game'
end

get '/game' do
  session[:deck] = [['C', 2], ['D', 3]]
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop

  erb :game
end
