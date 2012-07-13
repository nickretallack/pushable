faye = new Faye.Client '/faye'
subscription = faye.subscribe '/foo', (message) ->
    console.log JSON.parse message

subscription.callback ->
    console.log "subscription is now active"
subscription.errback (error) -> console.log "Error: #{error}"

all_things = {}

this_frame = {}
next_frame = {}

class Thing
    constructor: ({@size, @id}) ->
        things[@id] = @

$.get '/objects', (things) ->
    for id, thing of things
        new Thing thing
