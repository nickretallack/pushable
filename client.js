// Generated by CoffeeScript 1.3.3
(function() {
  var module;

  module = angular.module('game', []);

  module.factory('networking', function($rootScope) {
    var Challenge, Message, Thing, User, active_commands, all_things, bind_keyboard, bless_and_map, bless_list, blur_handler, commands, get_command, get_key_name, keydown_handler, keyup_handler, meters_to_pixels, send_challenge, send_chat, set_keyboard_events, socket, state, ui, unbind_keyboard;
    ui = function(procedure) {
      return $rootScope.$apply(procedure);
    };
    state = {
      user: null,
      users: {},
      messages: []
    };
    bless_list = function(list, type) {
      var data, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        data = list[_i];
        _results.push(new type(data));
      }
      return _results;
    };
    bless_and_map = function(list, type) {
      var item, result, _i, _len;
      result = {};
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        item = list[_i];
        result[item.id] = new type(item);
      }
      return result;
    };
    User = (function() {

      function User(_arg) {
        this.id = _arg.id, this.name = _arg.name;
        state.users[this.id] = this;
      }

      return User;

    })();
    Challenge = (function() {

      function Challenge(_arg) {
        var challengee_id, challenger_id;
        this.id = _arg.id, challenger_id = _arg.challenger_id, challengee_id = _arg.challengee_id;
        this.challenger = users.get(challenger_id);
        this.challengee = users.get(challengee_id);
      }

      return Challenge;

    })();
    Message = (function() {

      function Message(_arg) {
        var user_id, _ref;
        this.text = _arg.text, this.user = _arg.user, user_id = _arg.user_id;
        if ((_ref = this.user) == null) {
          this.user = users.get(user_id);
        }
      }

      return Message;

    })();
    socket = io.connect();
    socket.on('connect', function() {
      console.log('connected');
      return socket.emit('join_chat');
    });
    socket.on('user_identity', function(user_data) {
      return ui(function() {
        return state.user = new User(user_data);
      });
    });
    socket.on('user_list', function(user_list) {
      return ui(function() {
        return bless_and_map(user_list, User);
      });
    });
    socket.on('user_join', function(user) {
      return ui(function() {
        return state.users.push(new User(user));
      });
    });
    socket.on('user_leave', function(user_id) {
      return ui(function() {
        var user;
        return state.users = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = all_users.length; _i < _len; _i++) {
            user = all_users[_i];
            if (user.id !== user_id) {
              _results.push(user);
            }
          }
          return _results;
        })();
      });
    });
    socket.on('chat', function(message) {
      return ui(function() {
        message = new Message(message);
        return state.messages.push(message);
      });
    });
    socket.on('got_challenge', function(challenge) {
      return ui(function() {
        return $scope.messages.push(new Challenge(challenge));
      });
    });
    socket.on('start_game', function(game) {
      return ui(function() {
        return $location.updateHash({
          path: "/room/" + game.id
        });
      });
    });
    send_chat = function(text) {
      return socket.emit('chat', text);
    };
    send_challenge = function(user) {
      return socket.emit('send_challenge', user.id);
    };
    commands = {
      left: 'left',
      right: 'right',
      up: 'up',
      down: 'down'
    };
    active_commands = {};
    get_key_name = function(event) {
      return special_keys[event.which] || String.fromCharCode(event.which).toLowerCase();
    };
    get_command = function(event) {
      var key;
      key = get_key_name(event);
      return commands[key];
    };
    blur_handler = function() {
      socket.emit('command_clear');
      return active_commands = {};
    };
    keydown_handler = function(event) {
      var command;
      command = get_command(event);
      if ((command != null) && !(command in active_commands)) {
        active_commands[command] = true;
        return socket.emit('command_activate', command);
      }
    };
    keyup_handler = function(event) {
      var command;
      command = get_command(event);
      if ((command != null) && command in active_commands) {
        delete active_commands[command];
        return socket.emit('command_deactivate', command);
      }
    };
    set_keyboard_events = function(action) {
      $(window)[action]('blur', blur_handler);
      $(document)[action]('keydown', keydown_handler);
      return $(document)[action]('keyup', keyup_handler);
    };
    bind_keyboard = function() {
      return set_keyboard_events('on');
    };
    unbind_keyboard = function() {
      return set_keyboard_events('off');
    };
    all_things = {};
    socket.on('update', function(things) {
      var thing, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = things.length; _i < _len; _i++) {
        thing = things[_i];
        _results.push(all_things[thing.id].update(thing.position));
      }
      return _results;
    });
    socket.on('player_join', function(thing) {
      return new Thing(thing);
    });
    socket.on('player_leave', function(id) {
      return all_things[id].remove();
    });
    meters_to_pixels = function(meters) {
      return meters * 20;
    };
    Thing = (function() {

      function Thing(_arg) {
        this.size = _arg.size, this.position = _arg.position, this.id = _arg.id;
        all_things[this.id] = this;
        this.element = $('<div class="player"></div>');
        this.element.css({
          width: meters_to_pixels(this.size.x),
          height: meters_to_pixels(this.size.y),
          left: meters_to_pixels(this.position.x) + 200,
          top: meters_to_pixels(this.position.y) + 200,
          'background-color': "#" + this.id.slice(0, 6)
        });
        game_node.append(this.element);
      }

      Thing.prototype.update = function(position) {
        var css;
        this.position = position;
        css = {
          left: meters_to_pixels(this.position.x) + 200,
          top: meters_to_pixels(this.position.y) + 200
        };
        css["" + vendor_prefix + "-transition"] = "left " + frame_rate.frame_length_seconds + "s, top " + frame_rate.frame_length_seconds + "s";
        return this.element.css(css);
      };

      Thing.prototype.remove = function() {
        this.element.remove();
        return delete all_things[this.id];
      };

      return Thing;

    })();
    return {
      state: state,
      send_chat: send_chat,
      send_challenge: send_challenge,
      models: {
        Challenge: Challenge,
        Message: Message,
        User: User
      }
    };
  });

  module.config(function($routeProvider) {
    $routeProvider.when('/', {
      templateUrl: 'home',
      controller: 'home'
    });
    return $routeProvider.when('/room/:room_id', {
      templateUrl: 'game',
      controller: 'game'
    });
  });

  module.controller('home', function($scope, $location) {});

  module.controller('game', function($scope) {});

  module.directive('userList', function() {
    return {
      template: "<ul>\n    <li ng-repeat=\"user in get_users()\">\n        <div ng-switch=\"is_you(user)\">\n            <div ng-switch-when=\"true\">{{user.name}} (you)</div>\n            <div ng-switch-when=\"false\">\n                <a ng-click=\"challenge(user)\">challenge {{user.name}}</a>\n            </div>\n        </div>\n    </li>\n</ul>",
      replace: true,
      controller: function($scope, networking) {
        $scope.get_users = function() {
          return _.values(networking.state.users);
        };
        $scope.state = networking.state;
        $scope.is_you = function(user) {
          return user.id === networking.state.user.id;
        };
        return $scope.challenge = function(user) {
          return networking.send_challenge(user);
        };
      }
    };
  });

  module.filter('isa', function(networking) {
    return function(object, type) {
      return object instanceof networking.models[type];
    };
  });

  module.filter('messagetype', function(networking) {
    return function(object) {
      if (object instanceof networking.models.Message) {
        return 'message';
      } else if (object instanceof networking.models.Challenge) {
        return 'challenge';
      }
    };
  });

  module.directive('chat', function() {
    return {
      template: "<div>\n    <ul>\n        <li ng-repeat=\"message in messages\">\n            <div ng-switch=\"message|messagetype\">\n                <div ng-switch-when=\"message\">\n                    <a ng-click=\"select_user(message.user)\">{{message.user.name}}</a>: {{message.text}}\n                </div>\n                <div ng-switch-when=\"challenge\">\n                    {{message.challenger.name}} has challenged you to a game.\n                    <a ng-click=\"accept_challenge(message)\">Accept?</a>\n                </div>\n            </div>\n        </li>\n    </ul>\n    <form ng-submit=\"chat()\">\n        <input ng-model=\"chat_message\">\n    </form>\n</div>",
      replace: true,
      controller: function($scope, networking) {
        $scope.messages = networking.state.messages;
        $scope.chat = function() {
          networking.send_chat($scope.chat_message);
          return $scope.chat_message = '';
        };
        return $scope.select_user = function(user) {
          return $scope.$emit('select-user', user);
        };
      }
    };
  });

}).call(this);
