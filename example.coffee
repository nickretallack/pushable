b2d = require "box2dnode"

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
    console.log body.GetPosition()

setInterval update, 1000/60

