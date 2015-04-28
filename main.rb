require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dark_knight_rises'

CLUB = "\u2664 ".encode('utf-8')
HEART = "\u2661 ".encode('utf-8')
SPADE = "\u2667 ".encode('utf-8')
DIAMOND= "\u2662 ".encode('utf-8')

helpers do

end


get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new'
  end
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
  session[:deck] = [[DIAMOND, 2], [CLUB, 3]]
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop

  erb :game
end
