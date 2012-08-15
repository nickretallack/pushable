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


module.factory 'socket', -> io.connect()


module.directive 'chat', ->
    template:"""
    <div>
        <ul>
            <li ng-repeat="message in messages">
                {{message.user_name}}: {{message.text}}
            </li>
        </ul>
        <form ng-submit="chat()">
            <input ng-model="chat_message">
        </form>
    </div>
    """
    replace:true
    link: ->
        console.log 'wtf'
    controller: ($scope, socket) ->
        $scope.messages = []
        $scope.chat = ->
            socket.emit 'chat', $scope.chat_message
            $scope.messages.push
                text:$scope.chat_message
                user_name:'me'
            $scope.chat_message = ''

        socket.on 'chat', (message) -> $scope.$apply ->
            $scope.messages.push message


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