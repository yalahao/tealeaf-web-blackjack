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
    update_bet
  end

  def check_scores_end_game
    player_score = score(session[:player_cards])
    dealer_score = score(session[:dealer_cards])
    scores_msg = "#{session[:player_name]} scored #{player_score}. Dealer scored #{dealer_score}. "
    if dealer_score > 21
      @win_msg = "Dealer busted! #{session[:player_name]} won $#{session[:bet]}!"
    elsif player_score > dealer_score
      @win_msg = scores_msg + "#{session[:player_name]} won $#{session[:bet]}!"
    elsif player_score < dealer_score
      @lose_msg = scores_msg + "#{session[:player_name]} lost $#{session[:bet]}!"
    else
      @tie_msg = scores_msg + "It's a tie."
    end
    update_bet
  end

  def reset_msg
    @lose_msg = nil
    @tie_msg = nil
    @win_msg = nil
    @update_msg = nil
  end

  def update_bet
    if @win_msg
      session[:money] += (session[:bet] * 2)
    elsif @tie_msg
      session[:money] += session[:bet]
    end
  end


  def dealer_choice
    if score(session[:dealer_cards]) < [17, score(session[:player_cards])].max
      deal_card_to("dealer")
      dealer_choice
      erb :game
    else
      @update_msg = "Dealer stayed."
      session[:turn] = "end_game"
      redirect "/end_game"
    end
  end

  def ending
    money_diff = session[:money] - 1000
    if money_diff > 0
      "After round #{session[:num_rounds]}, #{session[:player_name]} left with $#{money_diff} extra money in the pocket!"
    elsif money_diff < 0
      "After round #{session[:num_rounds]}, #{session[:player_name]} left with $#{money_diff.abs} loss..."
    elsif money_diff == 1000
      "After round #{session[:num_rounds]}, #{session[:player_name]} lost all his money..."
    else
      "After round #{session[:num_rounds]}, #{session[:player_name]} left."
    end
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
  session[:bet] = 0
  session[:turn] = "player" #"player", "dealer", 'end_game'
  reset_msg
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
  reset_msg
  redirect "/game"
end

get '/end_game' do
  check_scores_end_game
  erb :game
end

post '/bye' do
  reset_msg
  erb :bye
end
