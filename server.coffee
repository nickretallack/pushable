b2d = require "box2dnode"
Faye = require 'faye'
express = require 'express'
vectors = require './common/vector_compatibility'
V = vectors.V
Vector = vectors.Vector
UUID = require('./common/uuid').UUID

app = express.createServer()
app.use express.static __dirname
app.use express.errorHandler dumpExceptions:true, showStack: true

faye = new Faye.NodeAdapter mount:'/faye'
faye_client = faye.getClient()
faye.attach app

# registry
things = {}

# make the world
gravity = V 0, -10
world = new b2d.b2World gravity, true

box_size = V 1,1
box_body_def = new b2d.b2BodyDef
box_body_def.type = b2d.b2Body.b2_dynamicBody
#bodyDef.position.Set 0.0, 4.0
box_shape_def = new b2d.b2PolygonShape
box_shape_def.SetAsBox box_size.components()...
box_fixture_def = new b2d.b2FixtureDef
box_fixture_def.shape = box_shape_def
box_fixture_def.density = 1.0
box_fixture_def.friction = 0.3

class Thing
    constructor:(@id=UUID())->
        @body = world.CreateBody box_body_def
        @body.CreateFixture box_fixture_def
        things[@id] = @

    toJSON: ->
        id:@id
        size:box_size
        position:@body.GetPosition()


update = ->
    world.Step 1/30, 10, 10
    faye_client.publish '/foo', JSON.stringify things

app.get '/things', (request, response) ->
    response.writeHead 200,
        'Content-Type':'application/json'
    response.end JSON.stringify things

new Thing
setInterval update, 1000/60
app.listen 8000
