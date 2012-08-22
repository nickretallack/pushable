server = require 'server'
b2d = require 'box2dnode'
V = require('./server_box2d_vector').V


class SpinBashersServer extends server.Game
        


# make the world
gravity = V 0,0
world = new b2d.b2World gravity, true

