%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape3_torus).
-moduledoc """
3D Torus

A 3D torus is a filled or wireframe ring solid that is typically used for
rendering. It constructs a core `graphics:shape3()`.

A torus is positioned by its center. `Radius` is the major radius, from the
center to the tube center. `TubeRadius` is the minor radius of the tube. The
hole is along Y and the major circle lies in XZ. Tessellation defaults to 16
rings and 16 slices. Y is up.

```erlang
{ok, Shape} = shape3_torus:solid(
    {0.0, 0.0, 0.0},
    2.0,
    0.5,
    ?COLOR_RED
).
ok = surface:draw_shape3(Surface, Shape).
ok = shape3:destroy(Shape).
```

Generated vertices use UV coordinates `(0.0, 0.0)`. Dispose the shape with
`shape3:destroy/1`.

Beware that a well-formed 3D torus always uses floats, not integers, for
positions, radii, and colors.
""".

-export([
    solid/4, solid/6
]).
-export([
    wires/4, wires/6
]).

-include_lib("beam_graphics/include/graphics.hrl").

-define(DEFAULT_RINGS, 16).
-define(DEFAULT_SLICES, 16).

-doc """
A solid 3D torus.

It constructs a 3D shape that draws a filled torus centered at the given
point. The tessellation is 16 rings and 16 slices.

It's equivalent to `solid(Center, Radius, TubeRadius, 16, 16, Color)`.
""".
-spec solid(
    Center :: graphics:vector3(),
    Radius :: float(),
    TubeRadius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
solid(Center, Radius, TubeRadius, Color) ->
    solid(Center, Radius, TubeRadius, ?DEFAULT_RINGS, ?DEFAULT_SLICES, Color).

-doc """
A solid 3D torus with ring and slice counts.

It constructs a 3D shape that draws a filled torus centered at the given
point, tessellated with the given number of rings around the hole and slices
around the tube. `Rings` and `Slices` are positive integers. Y is up.
""".
-spec solid(
    Center :: graphics:vector3(),
    Radius :: float(),
    TubeRadius :: float(),
    Rings :: pos_integer(),
    Slices :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
solid(Center, Radius, TubeRadius, Rings, Slices, Color) ->
    Vertices = lists:append([
        [
            torus_vertex(Center, Radius, TubeRadius, I, J, Rings, Slices, Color),
            torus_vertex(Center, Radius, TubeRadius, I + 1, J, Rings, Slices, Color),
            torus_vertex(Center, Radius, TubeRadius, I + 1, J + 1, Rings, Slices, Color),
            torus_vertex(Center, Radius, TubeRadius, I, J, Rings, Slices, Color),
            torus_vertex(Center, Radius, TubeRadius, I + 1, J + 1, Rings, Slices, Color),
            torus_vertex(Center, Radius, TubeRadius, I, J + 1, Rings, Slices, Color)
        ]
        || I <- lists:seq(0, Rings - 1),
           J <- lists:seq(0, Slices - 1)
    ]),
    shape_from_vertices(Vertices, triangles).

-doc """
A 3D torus wireframe.

It constructs a 3D shape that draws the major rings and the tube slices of a
torus as lines. The tessellation is 16 rings and 16 slices.

It's equivalent to `wires(Center, Radius, TubeRadius, 16, 16, Color)`.
""".
-spec wires(
    Center :: graphics:vector3(),
    Radius :: float(),
    TubeRadius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
wires(Center, Radius, TubeRadius, Color) ->
    wires(Center, Radius, TubeRadius, ?DEFAULT_RINGS, ?DEFAULT_SLICES, Color).

-doc """
A 3D torus wireframe with ring and slice counts.

It constructs a 3D shape that draws the major rings and the tube slices of a
torus as lines, tessellated with the given number of rings and slices.
`Rings` and `Slices` are positive integers.
""".
-spec wires(
    Center :: graphics:vector3(),
    Radius :: float(),
    TubeRadius :: float(),
    Rings :: pos_integer(),
    Slices :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
wires(Center, Radius, TubeRadius, Rings, Slices, Color) ->
    Major = lists:append([
        [
            torus_vertex(Center, Radius, TubeRadius, I, J, Rings, Slices, Color),
            torus_vertex(Center, Radius, TubeRadius, I + 1, J, Rings, Slices, Color)
        ]
        || J <- lists:seq(0, Slices - 1),
           I <- lists:seq(0, Rings - 1)
    ]),
    Tube = lists:append([
        [
            torus_vertex(Center, Radius, TubeRadius, I, J, Rings, Slices, Color),
            torus_vertex(Center, Radius, TubeRadius, I, J + 1, Rings, Slices, Color)
        ]
        || I <- lists:seq(0, Rings - 1),
           J <- lists:seq(0, Slices - 1)
    ]),
    shape_from_vertices(Major ++ Tube, lines).

torus_vertex({Cx, Cy, Cz}, Radius, TubeRadius, I, J, Rings, Slices, Color) ->
    Alpha = (2.0 * math:pi()) * I / Rings,
    Beta = (2.0 * math:pi()) * J / Slices,
    CosBeta = math:cos(Beta),
    SinBeta = math:sin(Beta),
    Tube = Radius + TubeRadius * CosBeta,
    ?VERTEX3(
        {
            Cx + Tube * math:sin(Alpha),
            Cy + TubeRadius * SinBeta,
            Cz + Tube * math:cos(Alpha)
        },
        Color
    ).

shape_from_vertices(Vertices, PrimitiveType) ->
    case mesh3:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, shape3:with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.
