(function() {
  var Thing, all_things, faye, next_frame, subscription, this_frame;

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

  all_things = {};

  this_frame = {};

  next_frame = {};

  Thing = (function() {

    function Thing(_arg) {
      this.size = _arg.size, this.id = _arg.id;
      things[this.id] = this;
    }

    return Thing;

  })();

  $.get('/objects', function(things) {
    var id, thing, _results;
    _results = [];
    for (id in things) {
      thing = things[id];
      _results.push(new Thing(thing));
    }
    return _results;
  });

}).call(this);
