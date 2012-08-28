module = angular.module 'game', []

module.factory 'networking', ($rootScope) ->
    ui = (procedure) -> $rootScope.$apply procedure

    state =
        game:null
        user:null
        users:{}
        messages:[]

    # Models

    bless_list = (list, type) -> (new type data for data in list)
    bless_and_map = (list, type) ->
        result = {}
        for item in list
            result[item.id] = new type item
        result

    class User
        constructor:({@id, @name}) ->
            state.users[@id] = @

    class Challenge
        constructor: ({@id, challenger_id, challengee_id}) ->
            @challenger = state.users[challenger_id]
            @challengee = state.users[challengee_id]

    class Message
        constructor: ({@text, @user, user_id}) ->
            @user ?= state.users[user_id]

    # Connect

    socket = io.connect()
    socket.on 'connect', ->
        socket.emit 'join_chat'

    socket.on 'user_identity', (user_data) -> ui ->
        state.user = new User user_data

    # Chat Stuff

    socket.on 'user_list', (user_list) -> ui ->
        bless_and_map user_list, User

    socket.on 'user_join', (user) -> ui ->
        state.users[user.id] = new User user

    socket.on 'user_leave', (user_id) -> ui ->
        delete state.users[user_id]
        #state.users = (user for user in all_users when user.id isnt user_id) #_.filter all_users, (user) -> user.id is user_id

    socket.on 'chat_history', (messages) -> ui ->
        state.messages = bless_list messages, Message

    socket.on 'chat', (message) -> ui ->
        message = new Message message
        state.messages.push message

    socket.on 'got_challenge', (challenge) -> ui ->
        state.messages.push new Challenge challenge

    socket.on 'start_game', (game) -> ui ->
        if state.game?
            state.game.remove()
        new Game game

    send_chat = (text) ->
        socket.emit 'chat', text

    send_challenge = (user) ->
        socket.emit 'send_challenge', user.id

    accept_challenge = (challenge) ->
        socket.emit 'accept_challenge', challenge.id

    # This is the keyboard bindings.  These are game specific.
    commands =
        left:'left'
        right:'right'
        up:'up'
        down:'down'

    # Keyboarding for games

    active_commands = {}
    get_key_name = (event) -> special_keys[event.which] or String.fromCharCode(event.which).toLowerCase()
    get_command = (event) ->
        key = get_key_name event
        commands[key]

    blur_handler = ->
        socket.emit 'command_clear'
        active_commands = {}

    keydown_handler = (event) ->
        command = get_command event
        if command? and command not of active_commands
            active_commands[command] = true
            socket.emit 'command_activate', command

    keyup_handler = (event) ->
            command = get_command event
            if command? and command of active_commands
                delete active_commands[command]
                socket.emit 'command_deactivate', command

    set_keyboard_events = (action) ->
        $(window)[action] 'blur', blur_handler
        $(document)[action] 'keydown', keydown_handler
        $(document)[action] 'keyup', keyup_handler

    bind_keyboard = -> set_keyboard_events 'on'
    unbind_keyboard = -> set_keyboard_events 'off'

    # game specific stuff

    socket.on 'update', (things) ->
        state.game.update things

    socket.on 'player_join', (thing) ->
        new Thing _.extend thing, state.game

    socket.on 'player_leave', (id) ->
        state.game.things[id].remove()

    meters_to_pixels = (meters) -> meters * 20
    screen_coordinates = (position,size) ->
        left: (meters_to_pixels position.x - size.x / 2) + window.innerWidth / 2
        top: window.innerHeight / 2 - (meters_to_pixels position.y + size.y / 2)

    class Game
        constructor:({@id, things}) ->
            state.game = @
            bind_keyboard()
            @node = $ '<div></div>'
            @things = {}
            for id, thing of things
                type = switch thing.type
                    when 'arena' then Arena
                    when 'player' then Player
                    else Thing

                new type _.extend thing,
                    game:@

        update: (things) ->
            for thing in things
                @things[thing.id].update thing

        remove: ->
            state.game = null
            unbind_keyboard()
            @node.remove()

    class Thing
        constructor: ({@size, @position, @angle, @id, @game, @type}) ->
            @game.things[@id] = @
            @node = @make_node()
            css = @position_css()
            css["#{vendor_prefix}-transition"] = "left #{frame_rate.frame_length_seconds}s, top #{frame_rate.frame_length_seconds}s, #{vendor_prefix}-transform #{frame_rate.frame_length_seconds}s"
            css["#{vendor_prefix}-transform-origin"] = "50% 50%"
            @node.css _.extend css,
                width:meters_to_pixels @size.x
                height:meters_to_pixels @size.y
            @game.node.append @node

        make_node: ->
            node = $ '<div class="#{@type}"></div>'
            node.css
                'background-color':"##{@id[...6]}"
            node

        position_css: ->
            css = screen_coordinates(@position,@size)
            css["#{vendor_prefix}-transform"] = "rotate(#{@angle}rad)"
            css

        update: ({@position, @angle}) ->
            css = @position_css()
            @node.css css

        remove: ->
            @node.remove()
            delete @game.things[@id]

    class Player extends Thing
        make_node: ->
            node = $ """
                <div class="bound-players">
                    <div class="player1 shape"></div>
                    <div class="player2 shape"></div>
                    <div class="rope"></div>
                </div>"""

    class Arena extends Thing
        make_node: ->
            @node = $ '<div class="arena"></div>'

    state:state
    send_chat:send_chat
    send_challenge:send_challenge
    accept_challenge:accept_challenge
    models:
        Challenge:Challenge
        Message:Message
        User:User

module.config ($routeProvider) ->
    $routeProvider.when '/', templateUrl:'home', controller:'home'
    $routeProvider.when '/room/:room_id', templateUrl:'game', controller:'game'

module.controller 'home', ($scope, $location, networking) ->
    $scope.get_game = -> networking.state.game

module.controller 'game', ($scope) ->




module.directive 'userList', ->
    template:"""
    <ul>
        <li ng-repeat="user in get_users()">
            <div ng-switch="is_you(user)">
                <div ng-switch-when="true">{{user.name}} (you)</div>
                <div ng-switch-when="false">
                    <a ng-click="challenge(user)">challenge {{user.name}}</a>
                </div>
            </div>
        </li>
    </ul>
    """
    replace:true
    controller: ($scope, networking) ->
        $scope.get_users = -> _.values networking.state.users
        $scope.state = networking.state
        $scope.is_you = (user) ->
            user.id is networking.state.user.id
        $scope.challenge = (user) ->
            networking.send_challenge user


module.filter 'isa', (networking) ->
    (object, type) -> object instanceof networking.models[type]

module.filter 'messagetype', (networking) ->
    (object) ->
        if object instanceof networking.models.Message then 'message'
        else if object instanceof networking.models.Challenge then 'challenge'

module.directive 'chat', ->
    template:"""
    <div>
        <ul>
            <li ng-repeat="message in get_messages()">
                <div ng-switch="message|messagetype">
                    <div ng-switch-when="message">
                        <a ng-click="select_user(message.user)">{{message.user.name}}</a>: {{message.text}}
                    </div>
                    <div ng-switch-when="challenge">
                        {{message.challenger.name}} has challenged you to a game.
                        <a ng-click="accept_challenge(message)">Accept?</a>
                    </div>
                </div>
            </li>
        </ul>
        <form ng-submit="chat()">
            <input ng-model="chat_message">
        </form>
    </div>
    """
    replace:true
    controller: ($scope, networking) ->
        $scope.get_messages = -> networking.state.messages
        $scope.chat = ->
            networking.send_chat $scope.chat_message
            $scope.chat_message = ''

        $scope.select_user = (user) ->
            $scope.$emit 'select-user', user

        $scope.accept_challenge = (challenge) ->
            networking.accept_challenge challenge

module.directive 'game', (networking) ->
    link:(scope, element) ->
        element.append(networking.state.game.node)