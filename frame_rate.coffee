now = -> (new Date).valueOf()

last_frame_time = null
frame_delta = null

deviation_history = []

get_frame_delta = ->
    this_frame_time = now()
    frame_delta = this_frame_time - last_frame_time
    last_frame_time = this_frame_time
    frame_delta

get_average_deviation = (norm) ->
    # update
    delta = get_frame_delta norm
    deviation_history.push Math.abs norm - frame_delta

    sum = 0
    for value in deviation_history[-20..-1]
        sum += value
    sum / deviation_history.length

if typeof exports is 'object'
    exports.get_frame_delta = get_frame_delta
    exports.get_average_deviation = get_average_deviation
else
    window.get_frame_delta = get_frame_delta
    window.get_average_deviation = get_average_deviation
