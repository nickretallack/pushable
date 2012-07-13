radians_factor = Math.PI / 180.0

b2d = require 'box2dnode'
Vector = b2d.b2Vec2

Vector::components = -> [@x, @y]

# These methods are slow because they construct new vectors.
# I'm adding them for my own convenience, but any uses of them could be replaced
# with in-place operations.

# The convention is that lower-case methods copy, while upper-case ones act in place.

Vector::scale = (scalar) -> new Vector @x*scalar, @y*scalar
Vector::Scale = (scalar) ->
    @x *= scalar
    @y *= scalar

Vector::add = (other) -> @Copy().Add other
Vector::subtract = (other) -> @Copy().Subtract other

Vector::Rotate = (angle) -> @MulM new b2Mat22 angle * radians_factor
Vector::rotate = (angle) -> @Copy().Rotate angle

# Handles the 'new' part for you
V = -> new Vector arguments...

exports.V = V
exports.radians_factor = radians_factor
exports.Vector = Vector