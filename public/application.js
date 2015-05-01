$(document).ready(function() {

  player_hit();
  player_double_down();
  player_stay();
  dealer_stay();

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

}