game_node = null

class Thing
    constructor: ({@size, @id}) ->
        all_things[@id] = @
        @element = $ '<div class="player"></div>'
        game_node.append @element

    update: (position) ->
        @element.css
            left:position.x + 200
            top:position.y + 200
        #console.log "position: x:#{position.x}, y:#{position.y}"

all_things = {}

this_frame = {}
next_frame = {}
    
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


$ ->
    game_node = $ '#game'
    faye = new Faye.Client '/faye'
    ready = false
    subscription = faye.subscribe '/foo', (message) ->
        things = JSON.parse message
        for id, thing of things
            all_things[id].update thing.position

    subscription.callback ->
        console.log "subscription is now active"
        $.get '/objects', (things) ->
            for id, thing of things
                new Thing thing
    subscription.errback (error) -> console.log "Error: #{error}"

    $(document).on 'keydown', (event) ->
        command = get_command event
        if command? and command not of active_commands
            active_commands[command] = true
            console.log 'publishing'
            faye.publish '/commands/activate', command

    $(document).on 'keyup', (event) ->
        command = get_command event
        if command? and command of active_commands
            delete active_commands[command]
            faye.publish '/commands/deactivate', command

    #$(document).bind "keydown", (event) -> pressed_keys[key_name(event)] = true
    #$(document).bind "keyup", (event) -> delete pressed_keys[key_name(event)]
