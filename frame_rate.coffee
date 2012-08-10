m = if typeof exports is 'object' then exports else window.frame_rate = {}

now = -> (new Date).valueOf()

last_frame_time = null
frame_delta = null

deviation_history = []

m.get_frame_delta = ->
    this_frame_time = now()
    frame_delta = this_frame_time - last_frame_time
    last_frame_time = this_frame_time
    frame_delta

m.get_average_deviation = ->
    # update
    delta = get_frame_delta m.frame_length
    deviation_history.push Math.abs norm - frame_delta

    sum = 0
    for value in deviation_history[-20..-1]
        sum += value
    sum / deviation_history.length

m.set_frame_rate = (rate) ->
    m.frames_per_second = rate
    m.frame_length_seconds = 1.0/m.frames_per_second
    m.frame_length_milliseconds = 1000.0/m.frames_per_second

m.set_frame_rate 20