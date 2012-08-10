// Generated by CoffeeScript 1.3.3
(function() {
  var deviation_history, frame_delta, last_frame_time, m, now;

  m = typeof exports === 'object' ? exports : window.frame_rate = {};

  now = function() {
    return (new Date).valueOf();
  };

  last_frame_time = null;

  frame_delta = null;

  deviation_history = [];

  m.get_frame_delta = function() {
    var this_frame_time;
    this_frame_time = now();
    frame_delta = this_frame_time - last_frame_time;
    last_frame_time = this_frame_time;
    return frame_delta;
  };

  m.get_average_deviation = function() {
    var delta, sum, value, _i, _len, _ref;
    delta = get_frame_delta(m.frame_length);
    deviation_history.push(Math.abs(norm - frame_delta));
    sum = 0;
    _ref = deviation_history.slice(-20);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      value = _ref[_i];
      sum += value;
    }
    return sum / deviation_history.length;
  };

  m.set_frame_rate = function(rate) {
    m.frames_per_second = rate;
    m.frame_length_seconds = 1.0 / m.frames_per_second;
    return m.frame_length_milliseconds = 1000.0 / m.frames_per_second;
  };

  m.set_frame_rate(5);

}).call(this);
