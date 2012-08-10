port = 8002
speed = 20

b2d = require 'box2dnode'
UUID = require('./library/uuid').UUID
V = require('./server_box2d_vector').V
frame_rate = require './frame_rate'

socket_io = require 'socket.io'
express = require 'express'
http = require 'http'

# Create an express/socket.io/http thingy
app = express()
server = http.createServer app
io = socket_io.listen server
server.listen port

# Setup app
app.use express.static __dirname
app.use express.errorHandler dumpExceptions:true, showStack: true

# registry
things = {}

# make the world
gravity = V 0, 0 #-9.8
world = new b2d.b2World gravity, true

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

class Thing
    constructor:(@id=UUID())->
        @body = world.CreateBody box_body_def
        @body.CreateFixture box_fixture_def
        things[@id] = @

    toJSON: ->
        id:@id
        size:box_size
        position:@body.GetPosition()

    force: (direction) ->
        @body.ApplyForce direction.scale(speed), @body.GetPosition()

    changes: ->
        id:@id
        position:@body.GetPosition()


update = ->
    for id, player of players
        player.control()

    world.Step frame_rate.frame_length_seconds, 10, 10
    world.ClearForces()

    changes = (thing.changes() for id, thing of things when thing.body.IsAwake())
    for id, player of players
        player.socket.volatile.emit 'update', changes

    console.log frame_rate.get_frame_delta()

app.get '/state', (request, response) ->
    response.writeHead 200,
        'Content-Type':'application/json'
    response.end JSON.stringify
        things:things
        frame_rate:frame_rate.frames_per_second

players = {}

class Player
    constructor: ({@id}) ->
        @commands = {}
        @physics = new Thing @id

    press: (command) ->
        @commands[command] = true

    release: (command) ->
        delete @commands[command]

    control: ->
        if @commands.left
            @physics.force V -1, 0
        if @commands.right
            @physics.force V +1, 0
        if @commands.up
            @physics.force V 0, -1
        if @commands.down
            @physics.force V 0, +1

io.sockets.on 'connection', (socket) ->
    id = UUID()
    player = new Player id
    players[id] = player
    player.socket = socket

    socket.broadcast.emit 'player_join', JSON.stringify player.physics

    socket.on 'command_activate', (command) ->
        player.press command
    socket.on 'command_deactivate', (command) ->
        player.release command


# Get things going
frame_rate.get_frame_delta()
setInterval update, frame_rate.frame_length_milliseconds
console.log "Listening on #{port}"
