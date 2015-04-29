require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dark_knight_rises'

SUITS = ['club', 'heart', 'spade', 'diamond']
RANKS = %w{ace 2 3 4 5 6 7 8 9 jack queen king}
BET_LIMIT = 100
DECKS_OF_CARDS = 2
BLACKJACK = 21
DELAY = 1

helpers do

  def display(card)
    suit = card[0]
    rank = card[1]
    url= "/images/cards/" + suit + "s_" + rank +".jpg"
    "<img src='#{url}' class='card'/>"
  end

  def description(card)
    suit = card[0]
    rank = card[1]
    "#{rank} of #{suit}s"
  end

  def score(hand)
    arr = []
    hand.each {|card| arr << card[1]}
    total = 0
    num_a =0
    arr.each do |rank|
      if rank == 'ace'
        total += 11
        num_a += 1
      elsif %w{jack queen king}.include?(rank)
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
    check_scores
  end

  def check_scores
    if score(session[:player_cards]) > 21
      @lose_msg = "#{session[:player_name]} busted and lost $#{session[:bet]}..."
    elsif (score(session[:player_cards]) == 21) && (score(session[:dealer_cards]) == 21)
      @tie_msg = "#{session[:player_name]} and dealer both hit blackjack. It's a tie."
    elsif score(session[:player_cards]) == 21
      @win_msg = "#{session[:player_name]} hit blackjack and won $#{session[:bet]}!"
    elsif score(session[:dealer_cards]) == 21
      @lose_msg = "Dealer hit blackjack! #{session[:player_name]} lost $#{session[:bet]}..."
    end
  end

  def end_game
    redirect '/end_game'
  end

  def reset_round
    @lose_msg = nil
    @tie_msg = nil
    @win_msg = nil
    @update_msg = nil
  end

  def dealer_choice
    if score(session[:dealer_cards]) < [17, score(session[:player_cards])].max
      deal_card_to("dealer")
      dealer_choice
      erb :game
    else
      @update_msg = "Dealer stayed."
      redirect "/end_game"
    end
  end

end

before do
  check_scores
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
  session[:bet] = 0
  session[:turn] = "player"
  reset_round
  @set_bet = true
  @max_bet = [BET_LIMIT, session[:money]].min
  erb :game
end

post '/game/player/set_bet' do
  session[:bet] = params[:bet].to_i
  session[:money] -= session[:bet]
  2.times {deal_card_to("player")}
  2.times {deal_card_to("dealer")}
  erb :game
end

post '/game/player/hit' do
  deal_card_to("player")
  @update_msg = "#{session[:player_name]} hit. It's #{description(session[:player_cards].last)} ."
  erb :game
end

post '/game/player/double_down' do
  session[:money] -= session[:bet]
  session[:bet] *= 2
  deal_card_to("player")
  @update_msg = "#{session[:player_name]} doubled the bet to $#{session[:bet]} and got #{description(session[:player_cards].last)} ."
  erb :game
end

post '/game/player/stay' do
  session[:turn] = "dealer"
  erb :game
end

post '/game/again' do
  session[:num_rounds] += 1
  reset_round
  redirect "/game"
end

get '/end_game' do
  reset_round
  erb :game
end
