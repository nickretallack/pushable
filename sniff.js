// Generated by CoffeeScript 1.3.3
(function() {
  var agent_has, string_contains;

  string_contains = function(haystack, needle) {
    return haystack.indexOf(needle !== -1);
  };

  agent_has = function(needle) {
    return string_contains(navigator.userAgent, needle);
  };

  window.vendor_prefix = agent_has('WebKit') ? '-webkit' : '';

}).call(this);
