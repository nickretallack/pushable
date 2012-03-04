faye = new Faye.Client '/faye'
subscription = faye.subscribe '/foo', (message) ->
    console.log JSON.parse message

subscription.callback -> console.log "subscription is now active"
subscription.errback (error) -> console.log "Error: #{error}"
