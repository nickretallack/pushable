port = 8003
speed = 20

_ = require 'underscore'
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
io.set 'log level', 1


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

things = {}
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

    remove: ->
        world.DestroyBody @body
        delete things[@id]

update = ->
    for id, player of players
        player.control()

    world.Step frame_rate.frame_length_seconds, 10, 10
    world.ClearForces()

    changes = (thing.changes() for id, thing of things when thing.body.IsAwake())
    for id, player of players
        player.socket.volatile.emit 'update', changes

    #console.log frame_rate.get_frame_delta()

app.get '/state', (request, response) ->
    response.writeHead 200,
        'Content-Type':'application/json'
    response.end JSON.stringify
        things:things
        frame_rate:frame_rate.frames_per_second

app.get '/room/:room', (request, response) ->
    response.writeHead 200
    response.end 

json_response = (response, object) ->
    response.writeHead 200,
        'Content-Type':'application/json'
    response.end JSON.stringify object

players = {}
class Player
    constructor: (@id=UUID()) ->
        @physics = new Thing @id
        @clear_commands()
        players[@id] = @
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

users = {}
class User
    constructor: (@id=UUID()) ->
        @name = @id
        users[@id] = @

    remove: ->
        delete users[@id]

    toJSON: ->
        id:@id
        name:@name

app.get '/users/', (request, response) ->
    json_response response, _.values users

games = {}
class Game
    constructor: ({@challenger, @challengee}, @id=UUID())->
        games[@id] = @

    remove: ->
        delete games[@id]

challenges = {}
class Challenge
    constructor: (@challenger, @challengee, @id=UUID()) ->
        challenges[@id] = @

    toJSON: ->
        id:@id
        challenger_id:@challenger.id
        challengee_id:@challengee.id

io.sockets.on 'connection', (socket) ->
    user = new User
    user.socket = socket
    socket.broadcast.emit 'user_join', user
    socket.emit 'user_identity', user

    socket.on 'chat', (text) ->
        socket.broadcast.emit 'chat',
            user:user
            text:text

    socket.on 'disconnect', ->
        socket.broadcast.emit 'user_leave', user.id
        user.remove()

    socket.on 'send_challenge', (challengee_id) ->
        console.log "sent challenge to #{challengee_id} when users is #{_.keys(users)}"
        challengee = users[challengee_id]
        challenge = new Challenge user, challengee
        challengee.socket.emit 'got_challenge', challenge

    socket.on 'accept_challenge', (challenge_id) ->
        challenge = challenges[challenge_id]
        new Game challenge



    ###
    socket.on 'command_activate', (command) ->
        player.press command
    socket.on 'command_deactivate', (command) ->
        player.release command
    socket.on 'command_clear', ->
        player.clear_commands()

    socket.on 'disconnect', ->
        socket.broadcast.emit 'player_leave', player.physics.id
        player.remove()
    ###

# Get things going
#frame_rate.get_frame_delta()
setInterval update, frame_rate.frame_length_milliseconds
console.log "Listening on #{port}"
