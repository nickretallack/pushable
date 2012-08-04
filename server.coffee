port = 8000
frames_per_second = 60
speed = 20

interval = 1000.0/frames_per_second
box2d_interval = 1.0/frames_per_second

Faye = require 'faye'
express = require 'express'

UUID = require('./library/uuid').UUID
b2d = require 'box2dnode'
V = require('./server_box2d_vector').V

# Setup app
app = express.createServer()
app.use express.static __dirname
app.use express.errorHandler dumpExceptions:true, showStack: true

# Setup socket
faye = new Faye.NodeAdapter mount:'/faye'
faye_client = faye.getClient()
faye.attach app

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


update = ->
    for id, player of players
        player.control()

    world.Step box2d_interval, 10, 10
    world.ClearForces()
    faye_client.publish '/foo', JSON.stringify things

app.get '/objects', (request, response) ->
    response.writeHead 200,
        'Content-Type':'application/json'
    response.end JSON.stringify things

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

get_player = (id) ->
    if id not of players
        players[id] = new Player id:id
    players[id]


faye_keyboard =
    incoming: (message, callback) ->
        player = get_player message.clientId

        # Eat these messages

        if message.channel is '/commands/activate'
            player.press message.data
            return

        if message.channel is '/commands/deactivate'
            player.release message.data
            return

        callback message



faye.addExtension faye_keyboard



# Get things going
setInterval update, interval
app.listen port
console.log "Listening on #{port}"
