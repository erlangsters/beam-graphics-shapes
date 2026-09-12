%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape2_ellipse).
-moduledoc """
2D Ellipse

A 2D ellipse is a filled, outlined, or wireframe oval that is typically used
for rendering. It constructs a core `graphics:shape2()`.

An ellipse is positioned by its center. `Radii` is `{RadiusX, RadiusY}`.
Tessellation defaults to 32 segments. Outline thickness is signed: positive
grows inwards, negative grows outwards. Inset is per-axis, matching
`graphics_shape2:circle_outline/4`.

```erlang
{ok, Shape} = graphics_shape2_ellipse:solid({0.0, 0.0}, {20.0, 10.0}, ?COLOR_RED).
ok = graphics_surface:draw_shape2(Surface, Shape).
ok = graphics_shape2:destroy(Shape).
```

Generated vertices use UV coordinates `(0.0, 0.0)`. Dispose the shape with
`graphics_shape2:destroy/1`.

Beware that a well-formed 2D ellipse always uses floats, not integers, for
positions, radii, thickness, and colors.
""".

-export([
    solid/3, solid/4
]).
-export([
    outline/4, outline/5
]).
-export([
    wires/3, wires/4
]).

-include_lib("beam_graphics/include/graphics.hrl").

-define(DEFAULT_SEGMENTS, 32).

-doc """
A solid 2D ellipse.

It constructs a 2D shape that draws a filled ellipse centered at the given
point. The tessellation is 32 segments.

It's equivalent to `solid(Center, Radii, 32, Color)`.
""".
-spec solid(
    Center :: graphics:vector2(),
    Radii :: graphics:vector2(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
solid(Center, Radii, Color) ->
    solid(Center, Radii, ?DEFAULT_SEGMENTS, Color).

-doc """
A solid 2D ellipse with a segment count.

It constructs a 2D shape that draws a filled ellipse centered at the given
point, tessellated with the given number of segments. `Segments` is a positive
integer.
""".
-spec solid(
    Center :: graphics:vector2(),
    Radii :: graphics:vector2(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
solid({X, Y}, {RadiusX, RadiusY}, Segments, Color) ->
    AngleStep = (2.0 * math:pi()) / Segments,
    Vertices = [
        ?VERTEX2({X, Y}, Color)
        | [
            ?VERTEX2(ellipse_point(X, Y, RadiusX, RadiusY, AngleStep * I), Color)
            || I <- lists:seq(0, Segments)
        ]
    ],
    shape_from_vertices(Vertices, triangle_fan).

-doc """
A 2D ellipse outline.

It constructs a 2D shape that draws a filled elliptical ring centered at the
given point. The tessellation is 32 segments. Positive `Thickness` grows
inwards (the outer radii stay `Radii`). Negative `Thickness` grows outwards.

It's equivalent to `outline(Center, Radii, 32, Thickness, Color)`.
""".
-spec outline(
    Center :: graphics:vector2(),
    Radii :: graphics:vector2(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
outline(Center, Radii, Thickness, Color) ->
    outline(Center, Radii, ?DEFAULT_SEGMENTS, Thickness, Color).

-doc """
A 2D ellipse outline with a segment count.

It constructs a 2D shape that draws a filled elliptical ring centered at the
given point, tessellated with the given number of segments. `Segments` is a
positive integer. Positive `Thickness` grows inwards. Negative `Thickness`
grows outwards.
""".
-spec outline(
    Center :: graphics:vector2(),
    Radii :: graphics:vector2(),
    Segments :: pos_integer(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
outline({X, Y}, {RadiusX, RadiusY}, Segments, Thickness, Color) ->
    InnerX = RadiusX - Thickness,
    InnerY = RadiusY - Thickness,
    AngleStep = (2.0 * math:pi()) / Segments,
    Rim = fun(I, Rx, Ry) ->
        ?VERTEX2(ellipse_point(X, Y, Rx, Ry, AngleStep * I), Color)
    end,
    Pairs = lists:append([
        [Rim(I, RadiusX, RadiusY), Rim(I, InnerX, InnerY)]
        || I <- lists:seq(0, Segments - 1)
    ]),
    Vertices = Pairs ++ [Rim(0, RadiusX, RadiusY), Rim(0, InnerX, InnerY)],
    shape_from_vertices(Vertices, triangle_strip).

-doc """
A 2D ellipse wireframe.

It constructs a 2D shape that draws the circumference of an ellipse as a line
loop. The tessellation is 32 segments.

It's equivalent to `wires(Center, Radii, 32, Color)`.
""".
-spec wires(
    Center :: graphics:vector2(),
    Radii :: graphics:vector2(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
wires(Center, Radii, Color) ->
    wires(Center, Radii, ?DEFAULT_SEGMENTS, Color).

-doc """
A 2D ellipse wireframe with a segment count.

It constructs a 2D shape that draws the circumference of an ellipse as a line
loop, tessellated with the given number of segments. `Segments` is a positive
integer.
""".
-spec wires(
    Center :: graphics:vector2(),
    Radii :: graphics:vector2(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
wires({X, Y}, {RadiusX, RadiusY}, Segments, Color) ->
    AngleStep = (2.0 * math:pi()) / Segments,
    Vertices = [
        ?VERTEX2(ellipse_point(X, Y, RadiusX, RadiusY, AngleStep * I), Color)
        || I <- lists:seq(0, Segments - 1)
    ],
    shape_from_vertices(Vertices, line_loop).

ellipse_point(X, Y, RadiusX, RadiusY, Angle) ->
    {X + RadiusX * math:cos(Angle), Y + RadiusY * math:sin(Angle)}.

shape_from_vertices(Vertices, PrimitiveType) ->
    case graphics_mesh2:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, graphics_shape2:with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.
