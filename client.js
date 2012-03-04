(function() {
  var faye, subscription;

  faye = new Faye.Client('/faye');

  subscription = faye.subscribe('/foo', function(message) {
    return console.log(JSON.parse(message));
  });

  subscription.callback(function() {
    return console.log("subscription is now active");
  });

  subscription.errback(function(error) {
    return console.log("Error: " + error);
  });

}).call(this);
