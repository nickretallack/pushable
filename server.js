(function() {
  var Faye, app, b2d, body, box_body_def, box_fixture_def, box_shape_def, express, faye, faye_client, gravity, update, world;

  b2d = require("box2dnode");

  Faye = require('faye');

  express = require('express');

  app = express.createServer();

  app.use(express.static(__dirname));

  app.use(express.errorHandler({
    dumpExceptions: true,
    showStack: true
  }));

  faye = new Faye.NodeAdapter({
    mount: '/faye'
  });

  faye_client = faye.getClient();

  faye.attach(app);

  gravity = new b2d.b2Vec2(0, -10);

  world = new b2d.b2World(gravity, true);

  box_body_def = new b2d.b2BodyDef;

  box_body_def.type = b2d.b2Body.b2_dynamicBody;

  box_shape_def = new b2d.b2PolygonShape;

  box_shape_def.SetAsBox(1.0, 1.0);

  box_fixture_def = new b2d.b2FixtureDef;

  box_fixture_def.shape = box_shape_def;

  box_fixture_def.density = 1.0;

  box_fixture_def.friction = 0.3;

  body = world.CreateBody(box_body_def);

  body.CreateFixture(box_fixture_def);

  update = function() {
    world.Step(1 / 30, 10, 10);
    console.log(body.GetPosition());
    return faye_client.publish('/foo', body.GetPosition());
  };

  setInterval(update, 1000 / 60);

  app.listen(8000);

}).call(this);
