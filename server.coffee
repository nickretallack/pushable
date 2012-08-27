port = 8003

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


_ = require 'underscore'
UUID = require('./library/uuid').UUID

BasicGame = require('./basic_game').Game
SpinBashersGame = require('./spin_bashers_server').Game
DefaultGame = BasicGame

json_response = (response, object) ->
    response.writeHead 200,
        'Content-Type':'application/json'
    response.end JSON.stringify object

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
challenges = {}
class Challenge
    constructor: (@challenger, @challengee, @id=UUID()) ->
        challenges[@id] = @

    toJSON: ->
        id:@id
        challenger_id:@challenger.id
        challengee_id:@challengee.id

chat_history = []
max_chat_history_length = 1000
add_to_chat_history = (message) ->
    chat_history.push message
    if chat_history.length > 1000
        chat_history = chat_history[max_chat_history_length/2..]

io.sockets.on 'connection', (socket) ->
    user = new User
    user.socket = socket
    socket.emit 'user_identity', user

    socket.on 'join_chat', ->
        channel = 'chat'
        socket.join channel
        socket.broadcast.to(channel).emit 'user_join', user
        socket.emit 'user_list', _.values users
        socket.emit 'chat_history', chat_history

    socket.on 'chat', (text) ->
        message = 
            user:user
            text:text
        add_to_chat_history message
        io.sockets.in('chat').emit 'chat', message

    socket.on 'disconnect', ->
        socket.broadcast.emit 'user_leave', user.id
        user.remove()
        player?.remove()
        #socket.broadcast.emit 'player_leave', player.physics.id

    socket.on 'send_challenge', (challengee_id) ->
        console.log "sent challenge to #{challengee_id} when users is #{_.keys(users)}"
        challengee = users[challengee_id]
        challenge = new Challenge user, challengee
        challengee.socket.emit 'got_challenge', challenge

    socket.on 'accept_challenge', (challenge_id) ->
        challenge = challenges[challenge_id]
        game = new DefaultGame challenge, io.sockets
        games[game.id] = game

        challenge.challenger.socket.join game.channel
        challenge.challengee.socket.join game.channel
        challenge.challenger.socket.emit 'start_game', game, 0
        challenge.challengee.socket.emit 'start_game', game, 1

    socket.on 'command_activate', (command) ->
        user.player?.press command
    socket.on 'command_deactivate', (command) ->
        user.player?.release command
    socket.on 'command_clear', ->
        user.player?.clear_commands()

# Get things going
#frame_rate.get_frame_delta()
console.log "Listening on #{port}"
