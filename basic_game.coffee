
b2d = require 'box2dnode'
V = require('./server_box2d_vector').V
frame_rate = require './frame_rate'
_ = require 'underscore'
UUID = require('./library/uuid').UUID

# constants
gravity = V 0, 0 #-9.8
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
box_body_def

things = {}
class Thing
    constructor:(@game, @id=UUID())->
        @body = @game.world.CreateBody box_body_def
        @body.CreateFixture box_fixture_def
        @game.things[@id] = @

    toJSON: ->
        id:@id
        size:box_size
        position:@body.GetPosition()

    force: (direction) ->
        @body.ApplyForce direction.scale(speed), @body.GetPosition()

    changes: ->
        id:@id
        position:@body.GetPosition()

    remove: ->
        @game.world.DestroyBody @body
        delete things[@id]

players = {}
class Player
    constructor: (@game, @user, @id=UUID()) ->
        @user.player = @
        @physics = new Thing @game, @id
        @clear_commands()
        @game.players[@id] = @
        @name = @id

    press: (command) ->
        @commands[command] = true

    release: (command) ->
        delete @commands[command]

    clear_commands: ->
        @commands = {}

    control: ->
        if @commands.left
            @physics.force V -1, 0
        if @commands.right
            @physics.force V +1, 0
        if @commands.up
            @physics.force V 0, -1
        if @commands.down
            @physics.force V 0, +1

    remove: ->
        delete players[@id]
        @physics.remove()

class Game
    constructor: ({challenger, challengee}, @sockets, @id=UUID())->
        @channel = "game-#{@id}"
        @world = new b2d.b2World gravity, true
        @players = {}
        @things = {}

        new Player @, challenger
        new Player @, challengee

        update = =>
            for id, player of @players
                player.control()

            @world.Step frame_rate.frame_length_seconds, 10, 10
            @world.ClearForces()

            changes = (thing.changes() for id, thing of @things when thing.body.IsAwake())
            @sockets.in(@channel).volatile.emit 'update', changes

        @timer = setInterval update, frame_rate.frame_length_milliseconds

    toJSON: ->
        id:@id
        things:@things

    remove: ->
        clearTimeout @timer
        delete games[@id]

exports.Game = Game