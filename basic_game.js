// Generated by CoffeeScript 1.3.3
(function() {
  var Player, PlayerBody, PushableGame, V, b2d, base_game, box_body_def, box_fixture_def, box_shape_def, box_size, gravity, speed, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  base_game = require('./base_game');

  V = require('./server_box2d_vector').V;

  b2d = require('box2dnode');

  _ = require('underscore');

  gravity = V(0, 0);

  speed = 20;

  box_size = V(2, 2);

  box_body_def = new b2d.b2BodyDef;

  box_body_def.type = b2d.b2Body.b2_dynamicBody;

  box_shape_def = new b2d.b2CircleShape;

  box_shape_def.m_radius = 1;

  box_fixture_def = new b2d.b2FixtureDef;

  box_fixture_def.shape = box_shape_def;

  box_fixture_def.density = 1.0;

  box_fixture_def.friction = 0.3;

  box_body_def.linearDamping = 1;

  PlayerBody = (function(_super) {

    __extends(PlayerBody, _super);

    function PlayerBody() {
      return PlayerBody.__super__.constructor.apply(this, arguments);
    }

    PlayerBody.prototype.setup = function() {
      this.body = this.game.world.CreateBody(box_body_def);
      return this.body.CreateFixture(box_fixture_def);
    };

    PlayerBody.prototype.toJSON = function() {
      return _.extend(PlayerBody.__super__.toJSON.call(this), {
        size: box_size
      });
    };

    return PlayerBody;

  })(base_game.AbstractBody);

  Player = (function(_super) {

    __extends(Player, _super);

    function Player() {
      return Player.__super__.constructor.apply(this, arguments);
    }

    Player.prototype.setup = function() {
      return this.body = new PlayerBody(this.game, this.id);
    };

    Player.prototype.control = function() {
      var direction, vector, _ref, _results;
      _ref = base_game.cardinals;
      _results = [];
      for (direction in _ref) {
        vector = _ref[direction];
        if (this.commands[direction]) {
          _results.push(this.body.force(vector.scale(speed)));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return Player;

  })(base_game.AbstractPlayer);

  PushableGame = (function(_super) {

    __extends(PushableGame, _super);

    function PushableGame(args, sockets, id) {
      this.challenger = args.challenger, this.challengee = args.challengee;
      PushableGame.__super__.constructor.call(this, sockets, id);
    }

    PushableGame.prototype.setup = function() {
      this.world = new b2d.b2World(gravity, true);
      new Player(this, this.challenger);
      return new Player(this, this.challengee);
    };

    return PushableGame;

  })(base_game.AbstractGame);

  exports.Game = PushableGame;

}).call(this);
