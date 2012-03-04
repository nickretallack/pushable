var b2d = require("box2dnode");

var world = new b2d.b2World(
        new b2d.b2Vec2(0, -10), // gravity
        true                // dosleep
    );

var bodyDef = new b2d.b2BodyDef;
bodyDef.type = b2d.b2Body.b2_dynamicBody;
bodyDef.position.Set(0.0, 4.0);

var body = world.CreateBody(bodyDef);

var dynamicBox = new b2d.b2PolygonShape;
dynamicBox.SetAsBox(1.0, 1.0);

var fixtureDef = new b2d.b2FixtureDef;
fixtureDef.shape = dynamicBox;
fixtureDef.density = 1.0;
fixtureDef.friction = 0.3;

body.CreateFixture(fixtureDef);

function update() {
    world.Step(1/30, 10, 10);
    console.log(body.GetPosition());
}
setInterval(update, 1000/60);

