$(document).ready(function() {

  player_hit();
  player_double_down();
  player_stay();
  dealer_action();

});

function player_hit() {
  $(document).on("click", "form#player_hit input", function() {
    $.ajax({
      type: "POST",
      url: "/game/player/hit"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });
    return false;
  });
};

function player_double_down() {
  $(document).on("click", "form#player_double_down input", function() {
    $.ajax({
      type:  "POST",
      url: "/game/player/double_down"
    }).done(function(msg) {
      $("#game").replaceWith(msg);
    });
    return false;
  });
};

function player_stay() {
  $(document).on("click", "form#player_stay input", function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/stay'
    }).done(function(msg) {
      $("#game").replaceWith(msg);
    });
    return false;
  });
};

function dealer_action() {
  $(document).on('click', 'form#dealer_action', function() {
    $.ajax({
      type: 'POST',
      url: '/game/dealer/action'
    }).done(function(msg) {
      $("#game").replaceWith(msg);
    });
    return false;
  });
}