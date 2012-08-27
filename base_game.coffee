V = require('./server_box2d_vector').V
frame_rate = require './frame_rate'
_ = require 'underscore'
UUID = require('./library/uuid').UUID

cardinals =
    left:V(-1,0)
    right:V(1,0)
    up:V(0,1)
    down:V(0,-1)

diagonals = [
    V(1,1)
    V(1,-1)
    V(-1,-1)
    V(-1,1)
]

class AbstractBody
    constructor:(@game, @id=UUID())->
        @game.bodies[@id] = @
        @setup()

    toJSON: ->
        id:@id
        position:@body.GetPosition()
        angle:@body.GetAngle()

    force: (vector, position=@body.GetPosition()) ->
        @body.ApplyForce vector, position

    changes: ->
        id:@id
        position:@body.GetPosition()
        angle:@body.GetAngle()

    remove: ->
        @game.world.DestroyBody @body
        delete @game.bodies[@id]

class AbstractPlayer
    constructor: (@game, @user, @id=UUID()) ->
        @clear_commands()
        @game.players[@id] = @
        @user.player = @
        @name = @id
        @setup()

    press: (command) ->
        @commands[command] = true

    release: (command) ->
        delete @commands[command]

    clear_commands: ->
        @commands = {}

    remove: ->
        delete players[@id]
        @body.remove()

class AbstractGame
    constructor: (@sockets, @id=UUID())->
        _.bindAll @, 'step'
        @channel = "game-#{@id}"
        @players = {}
        @bodies = {}
        @setup()
        @start()

    start: ->
        @timer = setInterval @step, frame_rate.frame_length_milliseconds

    step: ->
        for id, player of @players
            player.control()

        @world.Step frame_rate.frame_length_seconds, 10, 10
        @world.ClearForces()

        changes = (body.changes() for id, body of @bodies when body.body.IsAwake())
        @sockets.in(@channel).volatile.emit 'update', changes

    toJSON: ->
        id:@id
        things:@bodies

    remove: ->
        clearTimeout @timer
        delete games[@id]

exports.cardinals = cardinals
exports.diagonals = diagonals
exports.AbstractBody = AbstractBody
exports.AbstractPlayer = AbstractPlayer
exports.AbstractGame = AbstractGame