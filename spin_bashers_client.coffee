controls =
    dvorak:
        player1:
            left:'left'
            right:'right'
            down:'down'
            up:'up'
            clockwise:'shift'
            counter_clockwise:'z'
        player2:
            left:'a'
            right:'e'
            down:'o'
            up:','
            clockwise:'.'
            counter_clockwise:'\''
    normal:
        player1:
            left:'left'
            right:'right'
            down:'down'
            up:'up'
            clockwise:'shift'
            counter_clockwise:'/'
        player2:
            left:'a'
            right:'d'
            down:'s'
            up:'w'
            clockwise:'e'
            counter_clockwise:'q'

current_controls = 'normal'
###
dvorak_checkbox = $('#use_dvorak')
if localStorage.controls == 'dvorak'
    current_controls = 'dvorak'
    dvorak_checkbox.attr('checked','checked')
else
    current_controls = 'normal'
dvorak_checkbox.change (event) ->
    setTimeout ->
        enabled = dvorak_checkbox.is ':checked'
        current_controls = if enabled then 'dvorak' else 'normal'
        localStorage.controls = current_controls
###
