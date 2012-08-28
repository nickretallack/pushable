# dependencies
b2d = require 'box2dnode'
V = require('./server_box2d_vector').V
frame_rate = require './frame_rate'
_ = require 'underscore'
UUID = require('./library/uuid').UUID
base_game = require './base_game'

# constants
origin = V 0,0
[player_type, crate_type] = [0..1]
use_joint = true
time_step = 1.0/60.0
constraint_iterations = 10
gravity = V 0.0, -10.0
player_friction = 20
default_friction = 5
torque = 50
max_angular_velocity = 10
default_size = V 1,1
default_color = 0xff0000
damaging_impulse = 2
force = 25
force_angle = 45
do_sleep = true

world_size = V 2000, 2000
world_padding = 50
gravity = origin

# Shape
player_radius = 1
player_shape_def = new b2d.b2CircleShape(player_radius)

# Body definition
players_body_def = new b2d.b2BodyDef
players_body_def.type = b2d.b2Body.b2_dynamicBody
players_body_def.linearDamping = 1

# Fixture definition
player_fixture_def = new b2d.b2FixtureDef
player_fixture_def.shape = player_shape_def
player_fixture_def.density = 1.0
player_fixture_def.restitution = 1.0

player_distance = 6
half_player_distance = player_distance / 2
player1_position = V -half_player_distance, 0
player2_position = V half_player_distance, 0

make_players = (world, position) ->
    players_body_def.position = position
    body = world.CreateBody players_body_def

    # fix both player shapes to it

    player_shape_def.SetLocalPosition player1_position
    fixture1 = body.CreateFixture player_fixture_def

    player_shape_def.SetLocalPosition player2_position
    fixture2 = body.CreateFixture player_fixture_def

    player1:fixture1
    player2:fixture2
    body:body

################

make_damped_body_def = ->
    def = new b2d.b2BodyDef
    def.type = b2d.b2Body.b2_dynamicBody
    def.linearDamping = 1
    return def

crate_diameter = 2
crate_shape_def = new b2d.b2PolygonShape
crate_shape_def.SetAsBox crate_diameter, crate_diameter

crate_body_def = make_damped_body_def()

crate_fixture_def = new b2d.b2FixtureDef
crate_fixture_def.shape = crate_shape_def
crate_fixture_def.density = 1.0
crate_fixture_def.restitution = 1.0

make_crate = (world, position) ->
    crate_body_def.position = position
    body = world.CreateBody crate_body_def
    fixture = body.CreateFixture crate_fixture
    fixture

################

arena_size = 30
arena_edge_fixtures = []
for index in [0...base_game.diagonals.length]
    point1 = base_game.diagonals[index]
    point2 = base_game.diagonals[(index+1) % base_game.diagonals.length]
    edge = new b2d.b2EdgeShape point1, point2
    #debugger
    #edge.Set point1, point2
    fixture_def = b2d.b2FixtureDef
    fixture_def.shape = edge
    arena_edge_fixtures.push

#arena_shape_def = new b2d.b2ChainShape
#arena_coordinates = (diagonal.scale arena_size for diagonal in base_game.diagonals)
#arena_shape_def = new b2d.b2EdgeShape 
#arena_shape_def.CreateChain arena_coordinates

arena_body_def = new b2d.b2BodyDef
arena_body_def.type = b2d.b2Body.b2_staticBody
#arena_body_def.position = origin

#arena_fixture_def = b2d.b2FixtureDef
#arena_fixture_def.shape = arena_shape_def

make_arena = (world) ->
    body = world.CreateBody arena_body_def
    for fixture in arena_edge_fixtures
        body.CreateFixture fixture
    body

##############################

class Arena extends base_game.AbstractBody
    type:'arena'
    setup: ->
        @body = make_arena @game.world
        @size = V arena_size, arena_size

class PlayerPhysics extends base_game.AbstractBody
    type:'player'
    setup: ->
        {@player1, @player2, @body} = make_players @game.world, origin
        @size = V 8,8

class Player extends base_game.AbstractPlayer
    constructor: (args) ->
        {@shape} = args
        super args

    remove: ->
        delete players[@id]
        @physics.remove()

class Game extends base_game.AbstractGame
    constructor:(args, sockets, id) ->
        {@challenger, @challengee} = args
        super sockets, id

        @challenger.socket.join @channel
        @challengee.socket.join @channel
        @challenger.socket.emit 'start_game', @
        @challengee.socket.emit 'start_game', @

    setup: ->
        @world = new b2d.b2World gravity, true
        @arena = new Arena @
        @player_body = new PlayerPhysics @

        new Player 
            game:@
            user:@challenger 
            shape:@player_body.player1

        new Player
            game:@
            user:@challengee
            shape:@player_body.player2

    control_players: ->
    ###
        player1_position = player1.body.GetPosition()
        player2_position = player2.body.GetPosition()
        player1_direction = player2_position.minus(player1_position).normalize()
        center = player1_position.plus player2_position.minus(player1_position).scale(0.5)

        player1_controls = controls[current_controls].player1
        player2_controls = controls[current_controls].player2
        player1_clockwise = pressed_keys[player1_controls.clockwise] or false
        player2_clockwise = pressed_keys[player2_controls.clockwise] or false
        player1_counter_clockwise = pressed_keys[player1_controls.counter_clockwise] or false
        player2_counter_clockwise = pressed_keys[player2_controls.counter_clockwise] or false

        for key, direction of base_game.cardinals
            if pressed_keys[player1_controls[key]]
                player1.body.ApplyForce direction.scale(force), player1_position
            if pressed_keys[player2_controls[key]]
                player2.body.ApplyForce direction.scale(force), player2_position

        player1_rotation_commitment = if player1_clockwise is player1_counter_clockwise then 0 else if player1_clockwise then 1 else -1
        player2_rotation_commitment = if player2_clockwise is player2_counter_clockwise then 0 else if player2_clockwise then 1 else -1

        if player1_rotation_commitment isnt -player2_rotation_commitment
            if player1_rotation_commitment isnt 0
                force_direction = player1_direction.scale(-1).rotate force_angle * player1_rotation_commitment
                player2.body.ApplyForce force_direction.scale(force), player2_position
            
            if player2_rotation_commitment isnt 0
                force_direction2 = player1_direction.rotate force_angle * player2_rotation_commitment
                player1.body.ApplyForce force_direction2.scale(force), player1_position



        if @commands.left
            @physics.force V -1, 0
        if @commands.right
            @physics.force V +1, 0
        if @commands.up
            @physics.force V 0, -1
        if @commands.down
            @physics.force V 0, +1
    ###
    teardown: ->
        @player_body.remove()



###

get_type = (shape) -> shape.GetBody().GetUserData().type
get_data = (shape) -> shape.GetBody().GetUserData()

# contact listener
contact_listener = new b2ContactListener()
contact_listener.Result = (contact) ->
    if contact.normalImpulse > damaging_impulse
        shapes = [contact.shape1, contact.shape2]
        shapes.sort (a,b) -> get_type(a) - get_type(b)
        type1 = get_type shapes[0]
        type2 = get_type shapes[1]

        if type1 is player_type and type2 is crate_type
            player_data = get_data contact.shape1
            player = if player_data.which is 1 then player1 else player2
            hurt_player(player, contact.normalImpulse)

world.SetContactListener contact_listener

player1 = make_square
    position:V(-2, 2)
    color:0x0000ff
    data:
        type:player_type
        which:1
player2 = make_square
    position:V(2, -2)
    data:
        type:player_type
        which:2

player1.hit_points = player2.hit_points = 100
player1.name = "Blue Player"
player2.name = "Red Player"
player1.which = 1
player2.which = 2

players = [player1, player2]
other_player = (player) ->
    if player is players[0] then players[1] else players[0]

if use_joint
    joint_definition = new b2DistanceJointDef()
    joint_definition.Initialize player1.body, player2.body,
        player1.body.GetPosition(), player2.body.GetPosition()
    joint = world.CreateJoint joint_definition

make_heap = (location) ->
    size = 1
    elevation = 3
    for index in [0..10]
        make_square
            position:V(location, index*2)

make_level = ->
    make_heap 2

hurt_player = (player, damage) ->
    player.hit_points -= damage
    #console.log "#{player.name} was hit for #{damage}. #{player.hit_points} HP remaining. #{Date()}"
    $("#player#{player.which}_hit_points").text Math.round player.hit_points
    if player.hit_points < 0
        winner = other_player player
        game_over = true
        #console.log "#{winner.name} wins!"
        $("#winner").text("#{winner.name} wins!").addClass("player#{winner.which}")
###

exports.Game = Game
