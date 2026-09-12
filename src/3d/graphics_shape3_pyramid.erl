%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape3_pyramid).
-moduledoc """
3D Pyramid

A 3D pyramid is a filled or wireframe rectangular pyramid that is typically
used for rendering. It constructs a core `graphics:shape3()`.

A pyramid is positioned by its center. `Size` is the full width, height, and
length, matching `graphics_box3:from_center_size/2`. The name is conventional; the base
need not be square. The base lies in XZ at `Y = Cy - Height/2`. The apex is
`{Cx, Cy + Height/2, Cz}`. Y is up.

```erlang
{ok, Shape} = graphics_shape3_pyramid:solid(
    {0.0, 0.0, 0.0},
    {2.0, 3.0, 2.0},
    ?COLOR_RED
).
ok = graphics_surface:draw_shape3(Surface, Shape).
ok = graphics_shape3:destroy(Shape).
```

Generated vertices use UV coordinates `(0.0, 0.0)`. Dispose the shape with
`graphics_shape3:destroy/1`.

Beware that a well-formed 3D pyramid always uses floats, not integers, for
positions, sizes, and colors.
""".

-export([
    solid/3
]).
-export([
    wires/3
]).

-include_lib("beam_graphics/include/graphics.hrl").

-doc """
A solid 3D pyramid.

It constructs a 3D shape that draws a filled rectangular pyramid. `Center` is
the center. `Size` is the full width, height, and length.
""".
-spec solid(
    Center :: graphics:vector3(),
    Size :: graphics:vector3(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
solid({X, Y, Z}, {Width, Height, Length}, Color) ->
    {Apex, B00, B10, B01, B11} = pyramid_points(X, Y, Z, Width, Height, Length),
    V = fun(P) -> ?VERTEX3(P, Color) end,
    shape_from_vertices([
        % Base (-Y)
        V(B00), V(B11), V(B01),
        V(B10), V(B11), V(B00),
        % +Z
        V(B01), V(B11), V(Apex),
        % +X
        V(B11), V(B10), V(Apex),
        % -Z
        V(B10), V(B00), V(Apex),
        % -X
        V(B00), V(B01), V(Apex)
    ], triangles).

-doc """
A 3D pyramid wireframe.

It constructs a 3D shape that draws the four base edges and the four edges to
the apex as lines. `Center` is the center. `Size` is the full width, height,
and length.
""".
-spec wires(
    Center :: graphics:vector3(),
    Size :: graphics:vector3(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
wires({X, Y, Z}, {Width, Height, Length}, Color) ->
    {Apex, B00, B10, B01, B11} = pyramid_points(X, Y, Z, Width, Height, Length),
    V = fun(P) -> ?VERTEX3(P, Color) end,
    shape_from_vertices([
        V(B00), V(B10),
        V(B10), V(B11),
        V(B11), V(B01),
        V(B01), V(B00),
        V(B00), V(Apex),
        V(B10), V(Apex),
        V(B01), V(Apex),
        V(B11), V(Apex)
    ], lines).

pyramid_points(X, Y, Z, Width, Height, Length) ->
    HalfW = Width / 2.0,
    HalfH = Height / 2.0,
    HalfL = Length / 2.0,
    X0 = X - HalfW,
    X1 = X + HalfW,
    Y0 = Y - HalfH,
    Y1 = Y + HalfH,
    Z0 = Z - HalfL,
    Z1 = Z + HalfL,
    Apex = {X, Y1, Z},
    B00 = {X0, Y0, Z0},
    B10 = {X1, Y0, Z0},
    B01 = {X0, Y0, Z1},
    B11 = {X1, Y0, Z1},
    {Apex, B00, B10, B01, B11}.

shape_from_vertices(Vertices, PrimitiveType) ->
    case graphics_mesh3:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, graphics_shape3:with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.
