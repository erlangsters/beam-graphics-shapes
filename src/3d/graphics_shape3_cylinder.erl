%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape3_cylinder).
-moduledoc """
3D Cylinder

A 3D cylinder is a filled or wireframe circular cylinder that is typically
used for rendering. It constructs a core `graphics:shape3()`.

A cylinder is positioned by its center. The axis is Y. `Height` is the full Y
extent, so the body occupies `Y` in `[Cy - Height/2, Cy + Height/2]`. Both
ends are capped with disks. Tessellation defaults to 16 slices. Y is up.

```erlang
{ok, Shape} = graphics_shape3_cylinder:solid(
    {0.0, 0.0, 0.0},
    1.0,
    2.0,
    ?COLOR_RED
).
ok = graphics_surface:draw_shape3(Surface, Shape).
ok = graphics_shape3:destroy(Shape).
```

Generated vertices use UV coordinates `(0.0, 0.0)`. Dispose the shape with
`graphics_shape3:destroy/1`.

Beware that a well-formed 3D cylinder always uses floats, not integers, for
positions, radii, heights, and colors.
""".

-export([
    solid/4, solid/5
]).
-export([
    wires/4, wires/5
]).

-include_lib("beam_graphics/include/graphics.hrl").

-define(DEFAULT_SLICES, 16).

-doc """
A solid 3D cylinder.

It constructs a 3D shape that draws a filled circular cylinder centered at the
given point, with disk caps. The tessellation is 16 slices.

It's equivalent to `solid(Center, Radius, Height, 16, Color)`.
""".
-spec solid(
    Center :: graphics:vector3(),
    Radius :: float(),
    Height :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
solid(Center, Radius, Height, Color) ->
    solid(Center, Radius, Height, ?DEFAULT_SLICES, Color).

-doc """
A solid 3D cylinder with a slice count.

It constructs a 3D shape that draws a filled circular cylinder centered at the
given point, with disk caps, tessellated with the given number of slices.
`Slices` is a positive integer. The axis is Y.
""".
-spec solid(
    Center :: graphics:vector3(),
    Radius :: float(),
    Height :: float(),
    Slices :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
solid({X, Y, Z}, Radius, Height, Slices, Color) ->
    Y0 = Y - Height / 2.0,
    Y1 = Y + Height / 2.0,
    Side = lists:append([
        side_quad(X, Z, Radius, Y0, Y1, J, Slices, Color)
        || J <- lists:seq(0, Slices - 1)
    ]),
    Top = lists:append([
        cap_triangle({X, Y1, Z}, X, Z, Radius, Y1, J, J + 1, Slices, Color)
        || J <- lists:seq(0, Slices - 1)
    ]),
    Bottom = lists:append([
        cap_triangle({X, Y0, Z}, X, Z, Radius, Y0, J + 1, J, Slices, Color)
        || J <- lists:seq(0, Slices - 1)
    ]),
    shape_from_vertices(Side ++ Top ++ Bottom, triangles).

-doc """
A 3D cylinder wireframe.

It constructs a 3D shape that draws the two rims and the vertical edges of a
circular cylinder as lines. The tessellation is 16 slices.

It's equivalent to `wires(Center, Radius, Height, 16, Color)`.
""".
-spec wires(
    Center :: graphics:vector3(),
    Radius :: float(),
    Height :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
wires(Center, Radius, Height, Color) ->
    wires(Center, Radius, Height, ?DEFAULT_SLICES, Color).

-doc """
A 3D cylinder wireframe with a slice count.

It constructs a 3D shape that draws the two rims and the vertical edges of a
circular cylinder as lines, tessellated with the given number of slices.
`Slices` is a positive integer.
""".
-spec wires(
    Center :: graphics:vector3(),
    Radius :: float(),
    Height :: float(),
    Slices :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
wires({X, Y, Z}, Radius, Height, Slices, Color) ->
    Y0 = Y - Height / 2.0,
    Y1 = Y + Height / 2.0,
    Bottom = ring_edges(X, Z, Radius, Y0, Slices, Color),
    Top = ring_edges(X, Z, Radius, Y1, Slices, Color),
    Verticals = lists:append([
        begin
            P0 = rim_point(X, Z, Radius, Y0, J, Slices),
            P1 = rim_point(X, Z, Radius, Y1, J, Slices),
            [?VERTEX3(P0, Color), ?VERTEX3(P1, Color)]
        end
        || J <- lists:seq(0, Slices - 1),
           Y0 =/= Y1
    ]),
    shape_from_vertices(Bottom ++ Top ++ Verticals, lines).

side_quad(X, Z, Radius, Y0, Y1, J, Slices, Color) ->
    B0 = rim_point(X, Z, Radius, Y0, J, Slices),
    B1 = rim_point(X, Z, Radius, Y0, J + 1, Slices),
    T0 = rim_point(X, Z, Radius, Y1, J, Slices),
    T1 = rim_point(X, Z, Radius, Y1, J + 1, Slices),
    [
        ?VERTEX3(B0, Color), ?VERTEX3(B1, Color), ?VERTEX3(T1, Color),
        ?VERTEX3(B0, Color), ?VERTEX3(T1, Color), ?VERTEX3(T0, Color)
    ].

cap_triangle(Center, X, Z, Radius, Y, J0, J1, Slices, Color) ->
    [
        ?VERTEX3(Center, Color),
        ?VERTEX3(rim_point(X, Z, Radius, Y, J0, Slices), Color),
        ?VERTEX3(rim_point(X, Z, Radius, Y, J1, Slices), Color)
    ].

ring_edges(X, Z, Radius, Y, Slices, Color) ->
    lists:append([
        [
            ?VERTEX3(rim_point(X, Z, Radius, Y, J, Slices), Color),
            ?VERTEX3(rim_point(X, Z, Radius, Y, J + 1, Slices), Color)
        ]
        || J <- lists:seq(0, Slices - 1)
    ]).

rim_point(X, Z, Radius, Y, J, Slices) ->
    Phi = (2.0 * math:pi()) * J / Slices,
    {X + Radius * math:sin(Phi), Y, Z + Radius * math:cos(Phi)}.

shape_from_vertices(Vertices, PrimitiveType) ->
    case graphics_mesh3:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, graphics_shape3:with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.
