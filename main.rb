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
SUITS = [CLUB, HEART, SPADE, DIAMOND]
RANKS = %w{A 2 3 4 5 6 7 8 9 J Q K}
MAX_BET = 100
DECKS_OF_CARDS = 2
BLACKJACK = 21
DELAY = 1

helpers do
  def display(card)
    "[ #{card[0]} #{card[1]} ]"
  end

  def score(hand)
    arr = []
    hand.each {|card| arr << card[1]}
    total = 0
    num_a =0
    arr.each do |rank|
      if rank == 'A'
        total += 11
        num_a += 1
      elsif %w{J Q K}.include?(rank)
        total += 10
      else
        total += rank.to_i
      end
    end
    #correct for Aces
    num_a.times do
      break if total <= 21
      total -= 10
    end
    total
  end

  def deal_card_to(person)
    session[:player_cards] << session[:deck].pop if person == "player"
    session[:dealer_cards] << session[:deck].pop if person == "dealer"
  end

end

before do

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
  session[:deck] = SUITS.product(RANKS).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  2.times {deal_card_to("player")}
  2.times {deal_card_to("dealer")}
  erb :game
end

post '/game/player/hit' do
  session

end

post '/game/player/double_down' do

end

post '/game/player/stay' do

end
