// Generated by CoffeeScript 1.3.3
(function() {
  var BasicGame, Challenge, SpinBashersGame, UUID, User, add_to_chat_history, app, challenges, chat_history, express, games, http, io, json_response, max_chat_history_length, port, server, socket_io, users, _;

  port = 8003;

  socket_io = require('socket.io');

  express = require('express');

  http = require('http');

  app = express();

  server = http.createServer(app);

  io = socket_io.listen(server);

  server.listen(port);

  app.use(express["static"](__dirname));

  app.use(express.errorHandler({
    dumpExceptions: true,
    showStack: true
  }));

  io.set('log level', 1);

  _ = require('underscore');

  UUID = require('./library/uuid').UUID;

  BasicGame = require('./basic_game').Game;

  SpinBashersGame = require('./spin_bashers_server').Game;

  json_response = function(response, object) {
    response.writeHead(200, {
      'Content-Type': 'application/json'
    });
    return response.end(JSON.stringify(object));
  };

  users = {};

  User = (function() {

    function User(id) {
      this.id = id != null ? id : UUID();
      this.name = this.id;
      users[this.id] = this;
    }

    User.prototype.remove = function() {
      return delete users[this.id];
    };

    User.prototype.toJSON = function() {
      return {
        id: this.id,
        name: this.name
      };
    };

    return User;

  })();

  app.get('/users/', function(request, response) {
    return json_response(response, _.values(users));
  });

  games = {};

  challenges = {};

  Challenge = (function() {

    function Challenge(challenger, challengee, id) {
      this.challenger = challenger;
      this.challengee = challengee;
      this.id = id != null ? id : UUID();
      challenges[this.id] = this;
    }

    Challenge.prototype.toJSON = function() {
      return {
        id: this.id,
        challenger_id: this.challenger.id,
        challengee_id: this.challengee.id
      };
    };

    return Challenge;

  })();

  chat_history = [];

  max_chat_history_length = 1000;

  add_to_chat_history = function(message) {
    chat_history.push(message);
    if (chat_history.length > 1000) {
      return chat_history = chat_history.slice(max_chat_history_length / 2);
    }
  };

  io.sockets.on('connection', function(socket) {
    var user;
    user = new User;
    user.socket = socket;
    socket.emit('user_identity', user);
    socket.on('join_chat', function() {
      var channel;
      channel = 'chat';
      socket.join(channel);
      socket.broadcast.to(channel).emit('user_join', user);
      socket.emit('user_list', _.values(users));
      return socket.emit('chat_history', chat_history);
    });
    socket.on('chat', function(text) {
      var message;
      message = {
        user: user,
        text: text
      };
      add_to_chat_history(message);
      return io.sockets["in"]('chat').emit('chat', message);
    });
    socket.on('disconnect', function() {
      socket.broadcast.emit('user_leave', user.id);
      user.remove();
      return typeof player !== "undefined" && player !== null ? player.remove() : void 0;
    });
    socket.on('send_challenge', function(challengee_id) {
      var challenge, challengee;
      console.log("sent challenge to " + challengee_id + " when users is " + (_.keys(users)));
      challengee = users[challengee_id];
      challenge = new Challenge(user, challengee);
      return challengee.socket.emit('got_challenge', challenge);
    });
    socket.on('accept_challenge', function(challenge_id) {
      var challenge, game;
      challenge = challenges[challenge_id];
      game = new SpinBashersGame(challenge, io.sockets);
      games[game.id] = game;
      challenge.challenger.socket.join(game.channel);
      challenge.challengee.socket.join(game.channel);
      challenge.challenger.socket.emit('start_game', game, 0);
      return challenge.challengee.socket.emit('start_game', game, 1);
    });
    socket.on('command_activate', function(command) {
      var _ref;
      return (_ref = user.player) != null ? _ref.press(command) : void 0;
    });
    socket.on('command_deactivate', function(command) {
      var _ref;
      return (_ref = user.player) != null ? _ref.release(command) : void 0;
    });
    return socket.on('command_clear', function() {
      var _ref;
      return (_ref = user.player) != null ? _ref.clear_commands() : void 0;
    });
  });

  console.log("Listening on " + port);

}).call(this);
