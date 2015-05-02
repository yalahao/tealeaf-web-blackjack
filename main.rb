require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dark_knight_rises'

SUITS = ['club', 'heart', 'spade', 'diamond']
RANKS = %w{ace 2 3 4 5 6 7 8 9 jack queen king}
BET_LIMIT = 100
DECKS_OF_CARDS = 2
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
      else
        total += rank.to_i == 0 ? 10 : rank.to_i
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
    player_score = score(session[:player_cards])
    dealer_score = score(session[:dealer_cards])
    scores_msg = "#{session[:player_name]} scored #{player_score}. Dealer scored #{dealer_score}. "
    if player_score > 21
      @lose_msg = "#{session[:player_name]} busted and lost $#{session[:bet]}..."
    elsif (player_score == 21) && (dealer_score == 21)
      @tie_msg = "#{session[:player_name]} and dealer both hit blackjack. It's a tie."
    elsif player_score == 21
      @win_msg = "#{session[:player_name]} hit blackjack and won $#{session[:bet]}!"
    elsif dealer_score == 21
      @lose_msg = "Dealer hit blackjack! #{session[:player_name]} lost $#{session[:bet]}..."
    elsif dealer_score > 21
      @win_msg = "Dealer busted! #{session[:player_name]} won $#{session[:bet]}!"
    elsif (session[:turn] == "end_result") && (player_score > dealer_score)
      @win_msg = scores_msg + "#{session[:player_name]} won $#{session[:bet]}!"
    elsif (session[:turn] == "end_result") && (player_score < dealer_score)
      @lose_msg = scores_msg + "#{session[:player_name]} lost $#{session[:bet]}!"
    elsif (session[:turn] == "end_result") && (player_score == dealer_score)
      @tie_msg = scores_msg + "It's a tie."
    end
    if (@win_msg || @tie_msg || @lose_msg)
      session[:turn] = "end_result"
    end
    update_bet
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
      @update_msg = "Dealer hit. It's #{description(session[:dealer_cards].last)}."
    elsif score(session[:dealer_cards]) > 21
      session[:turn] == "end_game"
      redirect '/end_result'
    else
      session[:turn] == "end_game"
      redirect '/end_result?msg=dealer_stayed'
    end
  end

  def ending
    money_diff = session[:money] - 1000
    if money_diff > 0
      "After round #{session[:num_rounds]}, #{session[:player_name]} left with $#{money_diff} extra money in the pocket!"
    elsif money_diff == -1000
      "After round #{session[:num_rounds]}, #{session[:player_name]} lost all his money..."
    elsif money_diff < 0
      "After round #{session[:num_rounds]}, #{session[:player_name]} left with $#{money_diff.abs} loss..."
    else
      "After round #{session[:num_rounds]}, #{session[:player_name]} left."
    end
  end

end

before do
  erb :new if !session[:player_name]
end

get '/' do
  if !session[:player_name]
    redirect '/new'
  else
    redirect '/game'
  end
end

get '/new' do
  session[:num_rounds] = 1
  session[:money] = 1000
  session[:bet] = 0
  erb :new
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "You need to enter a name."
    halt erb(:new)
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  session[:deck] = SUITS.product(RANKS).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:bet] = 0
  session[:turn] = "player" #"player", "dealer", 'end_result'
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
  @update_msg = "#{session[:player_name]} hit. It's #{description(session[:player_cards].last)}."
  erb :game, layout: false
end

post '/game/player/double_down' do
  session[:money] -= session[:bet]
  session[:bet] *= 2
  deal_card_to("player")
  @update_msg = "#{session[:player_name]} doubled the bet to $#{session[:bet]} and got #{description(session[:player_cards].last)} ."
  erb :game, layout: false
end

post '/game/player/stay' do
  session[:turn] = "dealer"
  @update_msg = "Dealer's turn."
  erb :game, layout: false
end

post '/game/again' do
  session[:num_rounds] += 1
  redirect "/game"
end

post '/game/dealer/action' do
  check_scores
  if (!@win_msg && !@lose_msg)
    dealer_choice
  else
    redirect '/end_result'
  end
  erb :game, layout: false;
end

get '/end_result' do
  session[:turn] = "end_result"
  check_scores
  if params[:msg] == "dealer_stayed"
    @update_msg = "Dealer stayed."
  end
  erb :game
end

post '/bye' do
  erb :bye
end
