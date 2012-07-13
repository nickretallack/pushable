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

$.get '/objects', (things) ->
    for id, thing of things
        new Thing thing
