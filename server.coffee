b2d = require "box2dnode"
Faye = require 'faye'
express = require 'express'
app = express.createServer()
app.use express.static __dirname
app.use express.errorHandler dumpExceptions:true, showStack: true

faye = new Faye.NodeAdapter mount:'/faye'
faye_client = faye.getClient()
faye.attach app

gravity = new b2d.b2Vec2 0, -10
world = new b2d.b2World gravity, true

bodyDef = new b2d.b2BodyDef
bodyDef.type = b2d.b2Body.b2_dynamicBody
bodyDef.position.Set 0.0, 4.0

body = world.CreateBody bodyDef

dynamicBox = new b2d.b2PolygonShape
dynamicBox.SetAsBox 1.0, 1.0

fixtureDef = new b2d.b2FixtureDef
fixtureDef.shape = dynamicBox
fixtureDef.density = 1.0
fixtureDef.friction = 0.3

body.CreateFixture fixtureDef

update = ->
    world.Step 1/30, 10, 10
    faye_client.publish '/foo', body.GetPosition()

setInterval update, 1000/60

app.listen 8000
