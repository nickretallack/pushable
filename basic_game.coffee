base_game = require './base_game'
V = require('./server_box2d_vector').V
b2d = require 'box2dnode'
_ = require 'underscore'

# constants
gravity = V 0, 0
speed = 20
box_size = V 2,2

box_body_def = new b2d.b2BodyDef
box_body_def.type = b2d.b2Body.b2_dynamicBody
#bodyDef.position.Set 0.0, 4.0
box_shape_def = new b2d.b2CircleShape
box_shape_def.m_radius = 1 #SetAsBox box_size.components()...
box_fixture_def = new b2d.b2FixtureDef
box_fixture_def.shape = box_shape_def
box_fixture_def.density = 1.0
box_fixture_def.friction = 0.3
box_body_def.linearDamping = 1

class PlayerBody extends base_game.AbstractBody
    setup: ->
        @body = @game.world.CreateBody box_body_def
        @body.CreateFixture box_fixture_def

    teardown:->
        @game.world.DestroyBody @body

    toJSON: ->
        _.extend super(),
            size:box_size

class Player extends base_game.AbstractPlayer
    setup: ->
        @body = new PlayerBody @game, @id

    control: ->
        for direction, vector of base_game.cardinals
            if @commands[direction]
                @body.force vector.scale speed

class PushableGame extends base_game.AbstractGame
    constructor:(args, sockets, id) ->
        {@challenger, @challengee} = args
        super sockets, id

        @challenger.socket.join @channel
        @challengee.socket.join @channel
        @challenger.socket.emit 'start_game', @
        @challengee.socket.emit 'start_game', @


    setup: ->
        @world = new b2d.b2World gravity, true

        new Player 
            game:@
            user:@challenger
        new Player
            game:@
            user:@challengee

exports.Game = PushableGame