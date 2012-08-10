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
        game_node.append @element

    update: (@position) ->
        css = 
            left:meters_to_pixels(@position.x) + 200
            top:meters_to_pixels(@position.y) + 200
        css["#{vendor_prefix}-transition"] = "left #{frame_rate.frame_length_seconds}s, top #{frame_rate.frame_length_seconds}s"
        @element.css css

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

$ ->
    game_node = $ '#game'
    faye = new Faye.Client '/faye'
    ready = false
    subscription = faye.subscribe '/update', (message) ->

        # calculate frame rate
        console.log frame_rate.get_frame_delta()
        #console.log get_average_deviation frame_length_milliseconds

        # update things
        things = JSON.parse message
        for thing in things
            all_things[thing.id].update thing.position

    subscription = faye.subscribe '/player/join', (message) ->
        thing = JSON.parse message
        new Thing thing

    subscription.callback ->
        frame_rate.get_frame_delta()
        $.get '/state', (state) ->

            for id, thing of state.things
                new Thing thing

    subscription.errback (error) -> console.log "Error: #{error}"

    $(document).on 'keydown', (event) ->
        command = get_command event
        if command? and command not of active_commands
            active_commands[command] = true
            faye.publish '/commands/activate', command

    $(document).on 'keyup', (event) ->
        command = get_command event
        if command? and command of active_commands
            delete active_commands[command]
            faye.publish '/commands/deactivate', command

    #$(document).bind "keydown", (event) -> pressed_keys[key_name(event)] = true
    #$(document).bind "keyup", (event) -> delete pressed_keys[key_name(event)]
