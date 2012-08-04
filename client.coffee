$ ->
    faye = new Faye.Client '/faye'
    subscription = faye.subscribe '/foo', (message) ->
        console.log message

    subscription.callback ->
        console.log "subscription is now active"
    subscription.errback (error) -> console.log "Error: #{error}"

    all_things = {}

    this_frame = {}
    next_frame = {}

    all_things = {}
    class Thing
        constructor: ({@size, @id}) ->
            all_things[@id] = @
            @element = $ '<div class="player"></div>'
                


    $.get '/objects', (things) ->
        for id, thing of things
            new Thing thing

    commands =
        left:'left'
        right:'right'

    active_commands = {}
    get_key_name = (event) -> special_keys[event.which] or String.fromCharCode(event.which).toLowerCase()
    get_command = (event) ->
        key = get_key_name event
        commands[key]

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
