now = -> (new Date).valueOf()

last_frame_time = null

get_frame_delta = ->
    this_frame_time = now()
    frame_delta = this_frame_time - last_frame_time
    last_frame_time = this_frame_time
    frame_delta

if typeof exports is 'object'
    exports.get_frame_delta = get_frame_delta
else
    window.get_frame_delta = get_frame_delta
