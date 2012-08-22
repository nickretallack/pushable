module = angular.module 'game', []

module.config ($routeProvider) ->
    $routeProvider.when '/', templateUrl:'home', controller:'home'
    $routeProvider.when '/room/:room_id', templateUrl:'game', controller:'game'

module.run ($rootScope, socket) ->
    $scope = $rootScope
    $scope.new_game = ->
        $location.path "#/room/#{UUID()}"


module.controller 'home', ($scope, $location) ->

module.controller 'game', ($scope) ->


module.factory 'socket', ($q, $rootScope) ->
    # Currently overloaded to handle the current user.
    # In the future this may be handled elsewhere
    socket = io.connect()
    deferred_identity = $q.defer()
    socket.identity_promise = deferred_identity.promise
    socket.on 'user_identity', (user_data) -> $rootScope.$apply ->
        user =  new User user_data
        deferred_identity.resolve user
        socket.identity = user
    socket


class User
    constructor:({@id, @name}) ->

module.factory 'you', (socket) ->
    -> socket.identity

module.factory 'users', ($http, socket, $rootScope) ->
    all_users = []
    request = $http.get '/users/'
    request.success (users) ->
        all_users = (new User user for user in users)

    socket.on 'user_join', (user) -> $rootScope.$apply ->
        all_users.push new User user

    socket.on 'user_leave', (user_id) -> $rootScope.$apply ->
        all_users = (user for user in all_users when user.id isnt user_id) #_.filter all_users, (user) -> user.id is user_id

    socket.identity_promise.then (user) ->
        all_users.push user

    get: -> all_users

module.directive 'userList', ->
    template:"""
    <ul>
        <li ng-repeat="user in get_users()">
            <div ng-switch="is_you(user)">
                <div ng-switch-when="true">{{user.name}} (you)</div>
                <div ng-switch-when="false"><a>{{user.name}}</a></div>
            </div>
        </li>
    </ul>
    """
    replace:true
    controller: ($scope, users, socket) ->
        $scope.get_users = users.get
        $scope.is_you = (user) ->
            user is socket.identity

module.directive 'chat', ->
    template:"""
    <div>
        <ul>
            <li ng-repeat="message in messages">
                <a ng-click="select_user(message.user)">{{message.user.name}}</a>: {{message.text}}
            </li>
        </ul>
        <form ng-submit="chat()">
            <input ng-model="chat_message">
        </form>
    </div>
    """
    replace:true
    controller: ($scope, socket, users) ->
        $scope.messages = []
        $scope.chat = ->
            socket.emit 'chat', $scope.chat_message
            $scope.messages.push
                text:$scope.chat_message
                user:
                    name:'me'
                    id:'me'
            $scope.chat_message = ''

        socket.on 'chat', (message) -> $scope.$apply ->
            message.user = new User message.user
            $scope.messages.push message

        $scope.select_user = (user) ->
            $scope.$emit 'select-user', user



game_node = null

meters_to_pixels = (meters) -> meters * 20

class Thing
    constructor: ({@size, @position, @id}) ->
        all_things[@id] = @
        @element = $ '<div class="player"></div>'
        @element.css
            width:meters_to_pixels @size.x
            height:meters_to_pixels @size.y
            left:meters_to_pixels(@position.x) + 200
            top:meters_to_pixels(@position.y) + 200
            'background-color':"##{@id[...6]}"
        game_node.append @element

    update: (@position) ->
        css = 
            left:meters_to_pixels(@position.x) + 200
            top:meters_to_pixels(@position.y) + 200
        css["#{vendor_prefix}-transition"] = "left #{frame_rate.frame_length_seconds}s, top #{frame_rate.frame_length_seconds}s"
        @element.css css

    remove: ->
        @element.remove()
        delete all_things[@id]

all_things = {}
    
commands =
    left:'left'
    right:'right'
    up:'up'
    down:'down'

active_commands = {}
get_key_name = (event) -> special_keys[event.which] or String.fromCharCode(event.which).toLowerCase()
get_command = (event) ->
    key = get_key_name event
    commands[key]

socket = null
###
$ ->
    game_node = $ '#game'
    socket = io.connect()
    socket.on 'connect', ->
        frame_rate.get_frame_delta()
        $.get '/state', (state) ->
            for id, thing of state.things
                new Thing thing
            ready()
###
ready = ->
    socket.on 'update', (things) ->
        for thing in things
            all_things[thing.id].update thing.position

        #console.log frame_rate.get_frame_delta()
        #console.log get_average_deviation frame_length_milliseconds

    socket.on 'player_join', (thing) ->
        new Thing thing

    socket.on 'player_leave', (id) ->
        all_things[id].remove()

    $(document).on 'keydown', (event) ->
        command = get_command event
        if command? and command not of active_commands
            active_commands[command] = true
            socket.emit 'command_activate', command

    $(document).on 'keyup', (event) ->
        command = get_command event
        if command? and command of active_commands
            delete active_commands[command]
            socket.emit 'command_deactivate', command

    $(window).on 'blur', (event) ->
        socket.emit 'command_clear'