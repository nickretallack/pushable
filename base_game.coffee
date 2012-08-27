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
    type:'body'
    constructor:(@game, @id=UUID())->
        @game.bodies[@id] = @
        @setup()

    remove: ->
        delete @game.bodies[@id]
        @teardown()

    setup:->
    teardown:->

    toJSON: ->
        _.extend @changes(), @unchanges()

    force: (vector, position=@body.GetPosition()) ->
        @body.ApplyForce vector, position

    changes: ->
        id:@id
        position:@body.GetPosition()
        angle:@body.GetAngle()

    unchanges: ->
        type:@type
        size:@size


class AbstractPlayer
    constructor: ({@game, @user, @id}) ->
        @id ?= UUID()
        @clear_commands()
        @game.players[@id] = @
        @user.player = @
        @name = @id
        @setup()

    remove: ->
        delete players[@id]
        @teardown()

    setup:->
    teardown:->
    control:->

    other_player: ->
        # Useful for two-player games
        for id, player of @game.players
            return player if id != @id

    press: (command) ->
        @commands[command] = true

    release: (command) ->
        delete @commands[command]

    clear_commands: ->
        @commands = {}

class AbstractGame
    constructor: (@sockets, @id=UUID()) ->
        _.bindAll @, 'step'
        @channel = "game-#{@id}"
        @players = {}
        @bodies = {}
        @setup()
        @start()

    remove: ->
        clearTimeout @timer
        @teardown()

    setup:->
    teardown:->

    start: ->
        @timer = setInterval @step, frame_rate.frame_length_milliseconds

    step: ->
        @control_players()
        @step_world()
        @broadcast_changes()

    control_players: ->
        for id, player of @players
            player.control()

    step_world: ->
        @world.Step frame_rate.frame_length_seconds, 10, 10
        @world.ClearForces()

    broadcast_changes: ->
        changes = (body.changes() for id, body of @bodies when body.body.IsAwake())
        @sockets.in(@channel).volatile.emit 'update', changes

    toJSON: ->
        id:@id
        things:@bodies

exports.cardinals = cardinals
exports.diagonals = diagonals
exports.AbstractBody = AbstractBody
exports.AbstractPlayer = AbstractPlayer
exports.AbstractGame = AbstractGame