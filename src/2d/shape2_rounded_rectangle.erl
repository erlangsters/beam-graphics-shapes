%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape2_rounded_rectangle).
-moduledoc """
2D Rounded Rectangle

A 2D rounded rectangle is a filled, outlined, or wireframe axis-aligned
rectangle with rounded corners that is typically used for rendering. It
constructs a core `graphics:shape2()`.

A rounded rectangle is positioned by its minimum corner. `Size` is the full
width and height. The rectangle extends in `+X` and `+Y`, matching
`shape2:rectangle/3`. `Radius` is the corner radius in world units, clamped to
half the shorter side. `Segments` is the tessellation of each corner quarter;
it defaults to 8. Outline thickness is signed: positive grows inwards,
negative grows outwards.

```erlang
{ok, Shape} = shape2_rounded_rectangle:solid(
    {0.0, 0.0},
    {100.0, 50.0},
    8.0,
    ?COLOR_RED
).
ok = surface:draw_shape2(Surface, Shape).
ok = shape2:destroy(Shape).
```

Generated vertices use UV coordinates `(0.0, 0.0)`. Dispose the shape with
`shape2:destroy/1`.

Beware that a well-formed 2D rounded rectangle always uses floats, not
integers, for positions, sizes, radii, thickness, and colors.
""".

-export([
    solid/4, solid/5
]).
-export([
    outline/5, outline/6
]).
-export([
    wires/4, wires/5
]).

-include_lib("beam_graphics/include/graphics.hrl").

-define(DEFAULT_CORNER_SEGMENTS, 8).

-doc """
A solid 2D rounded rectangle.

It constructs a 2D shape that draws a filled axis-aligned rectangle with
rounded corners. `Position` is the minimum corner. `Size` is the full width
and height. The tessellation is 8 segments per corner.

It's equivalent to `solid(Position, Size, Radius, 8, Color)`.
""".
-spec solid(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Radius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
solid(Position, Size, Radius, Color) ->
    solid(Position, Size, Radius, ?DEFAULT_CORNER_SEGMENTS, Color).

-doc """
A solid 2D rounded rectangle with a corner segment count.

It constructs a 2D shape that draws a filled axis-aligned rectangle with
rounded corners, tessellated with the given number of segments per corner.
`Segments` is a positive integer.
""".
-spec solid(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Radius :: float(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
solid({X, Y} = Position, {Width, Height} = Size, Radius, Segments, Color) ->
    Rim = rim_vertices(Position, Size, Radius, Segments, Color),
    Center = ?VERTEX2({X + Width / 2.0, Y + Height / 2.0}, Color),
    shape_from_vertices([Center | Rim ++ [hd(Rim)]], triangle_fan).

-doc """
A 2D rounded rectangle outline.

It constructs a 2D shape that draws a filled border of an axis-aligned
rectangle with rounded corners. `Position` is the minimum corner. `Size` is
the full width and height. The tessellation is 8 segments per corner. Positive
`Thickness` grows inwards (the outer edge stays the original rounded
rectangle). Negative `Thickness` grows outwards.

It's equivalent to `outline(Position, Size, Radius, 8, Thickness, Color)`.
""".
-spec outline(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Radius :: float(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
outline(Position, Size, Radius, Thickness, Color) ->
    outline(Position, Size, Radius, ?DEFAULT_CORNER_SEGMENTS, Thickness, Color).

-doc """
A 2D rounded rectangle outline with a corner segment count.

It constructs a 2D shape that draws a filled border of an axis-aligned
rectangle with rounded corners, tessellated with the given number of segments
per corner. `Segments` is a positive integer. Positive `Thickness` grows
inwards. Negative `Thickness` grows outwards.
""".
-spec outline(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Radius :: float(),
    Segments :: pos_integer(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
outline({X, Y}, {Width, Height}, Radius, Segments, Thickness, Color) ->
    Outer = rim_vertices({X, Y}, {Width, Height}, Radius, Segments, Color),
    Inner = rim_vertices(
        {X + Thickness, Y + Thickness},
        {Width - 2.0 * Thickness, Height - 2.0 * Thickness},
        Radius - Thickness,
        Segments,
        Color
    ),
    Pairs = lists:append([
        [OuterVertex, InnerVertex]
        || {OuterVertex, InnerVertex} <- lists:zip(Outer, Inner)
    ]),
    Vertices = Pairs ++ [hd(Outer), hd(Inner)],
    shape_from_vertices(Vertices, triangle_strip).

-doc """
A 2D rounded rectangle wireframe.

It constructs a 2D shape that draws the outline of an axis-aligned rectangle
with rounded corners as a line loop. `Position` is the minimum corner. `Size`
is the full width and height. The tessellation is 8 segments per corner.

It's equivalent to `wires(Position, Size, Radius, 8, Color)`.
""".
-spec wires(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Radius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
wires(Position, Size, Radius, Color) ->
    wires(Position, Size, Radius, ?DEFAULT_CORNER_SEGMENTS, Color).

-doc """
A 2D rounded rectangle wireframe with a corner segment count.

It constructs a 2D shape that draws the outline of an axis-aligned rectangle
with rounded corners as a line loop, tessellated with the given number of
segments per corner. `Segments` is a positive integer.
""".
-spec wires(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Radius :: float(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
wires(Position, Size, Radius, Segments, Color) ->
    shape_from_vertices(
        rim_vertices(Position, Size, Radius, Segments, Color),
        line_loop
    ).

rim_vertices({X, Y}, {Width, Height}, Radius, Segments, Color) ->
    R = min(Radius, min(Width, Height) / 2.0),
    lists:append([
        corner_arc({X + R, Y + R}, R, math:pi(), math:pi() * 1.5, Segments, Color),
        corner_arc(
            {X + Width - R, Y + R},
            R,
            math:pi() * 1.5,
            math:pi() * 2.0,
            Segments,
            Color
        ),
        corner_arc(
            {X + Width - R, Y + Height - R},
            R,
            0.0,
            math:pi() * 0.5,
            Segments,
            Color
        ),
        corner_arc(
            {X + R, Y + Height - R},
            R,
            math:pi() * 0.5,
            math:pi(),
            Segments,
            Color
        )
    ]).

corner_arc({Cx, Cy}, Radius, StartAngle, EndAngle, Segments, Color) ->
    [
        begin
            T = I / Segments,
            Angle = StartAngle + (EndAngle - StartAngle) * T,
            ?VERTEX2(
                {Cx + Radius * math:cos(Angle), Cy + Radius * math:sin(Angle)},
                Color
            )
        end
        || I <- lists:seq(0, Segments)
    ].

shape_from_vertices(Vertices, PrimitiveType) ->
    case mesh2:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, shape2:with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.
