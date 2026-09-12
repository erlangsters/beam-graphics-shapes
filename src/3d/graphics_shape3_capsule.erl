%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape3_capsule).
-moduledoc """
3D Capsule

A 3D capsule is a filled or wireframe cylinder with hemispherical caps that is
typically used for rendering. It constructs a core `graphics:shape3()`.

A capsule is positioned by its center. The axis is Y. `Height` is the full Y
extent including the hemispheres. The cylindrical mid-section length is
`Height - 2*Radius`. Hemisphere rings are derived from `Slices`. Tessellation
defaults to 16 slices. Y is up.

```erlang
{ok, Shape} = graphics_shape3_capsule:solid(
    {0.0, 0.0, 0.0},
    1.0,
    4.0,
    ?COLOR_RED
).
ok = graphics_surface:draw_shape3(Surface, Shape).
ok = graphics_shape3:destroy(Shape).
```

Generated vertices use UV coordinates `(0.0, 0.0)`. Dispose the shape with
`graphics_shape3:destroy/1`.

Beware that a well-formed 3D capsule always uses floats, not integers, for
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
A solid 3D capsule.

It constructs a 3D shape that draws a filled capsule centered at the given
point. The tessellation is 16 slices.

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
A solid 3D capsule with a slice count.

It constructs a 3D shape that draws a filled capsule centered at the given
point, tessellated with the given number of slices. `Slices` is a positive
integer. The axis is Y. Hemisphere rings are derived from `Slices`.
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
    {TopCenter, BotCenter, Rings, EquatorI} = capsule_params(
        {X, Y, Z}, Radius, Height, Slices
    ),
    Top = hemi_solid(TopCenter, Radius, Rings, Slices, 0, EquatorI, Color),
    Bottom = hemi_solid(BotCenter, Radius, Rings, Slices, EquatorI, Rings, Color),
    Side = cylinder_side(TopCenter, BotCenter, Radius, Slices, Color),
    shape_from_vertices(Top ++ Side ++ Bottom, triangles).

-doc """
A 3D capsule wireframe.

It constructs a 3D shape that draws the latitude rings, meridians, and
mid-section edges of a capsule as lines. The tessellation is 16 slices.

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
A 3D capsule wireframe with a slice count.

It constructs a 3D shape that draws the latitude rings, meridians, and
mid-section edges of a capsule as lines, tessellated with the given number of
slices. `Slices` is a positive integer.
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
    {TopCenter, BotCenter, Rings, EquatorI} = capsule_params(
        {X, Y, Z}, Radius, Height, Slices
    ),
    TopLat = hemi_latitudes(TopCenter, Radius, Rings, Slices, 1, EquatorI, Color),
    TopMer = hemi_meridians(TopCenter, Radius, Rings, Slices, 0, EquatorI, Color),
    BotLat = hemi_latitudes(
        BotCenter, Radius, Rings, Slices, EquatorI + 1, Rings - 1, Color
    ),
    BotMer = hemi_meridians(
        BotCenter, Radius, Rings, Slices, EquatorI, Rings, Color
    ),
    Verticals = cylinder_verticals(TopCenter, BotCenter, Radius, Slices, Color),
    shape_from_vertices(
        TopLat ++ TopMer ++ BotLat ++ BotMer ++ Verticals,
        lines
    ).

capsule_params({X, Y, Z}, Radius, Height, Slices) ->
    Half = Height / 2.0,
    TopCenter = {X, Y + Half - Radius, Z},
    BotCenter = {X, Y - Half + Radius, Z},
    Rings = max(2, Slices),
    EquatorI = Rings div 2,
    {TopCenter, BotCenter, Rings, EquatorI}.

hemi_solid(Center, Radius, Rings, Slices, FromI, ToI, Color) ->
    North = case FromI =:= 0 of
        true ->
            lists:append([
                [
                    hemi_vertex(Center, Radius, 0, 0, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, 1, J, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, 1, J + 1, Rings, Slices, Color)
                ]
                || J <- lists:seq(0, Slices - 1)
            ]);
        false ->
            []
    end,
    Start = max(FromI, 1),
    End = min(ToI - 1, Rings - 2),
    Middle = case Start =< End of
        true ->
            lists:append([
                [
                    hemi_vertex(Center, Radius, I, J, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, I + 1, J, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, I + 1, J + 1, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, I, J, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, I + 1, J + 1, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, I, J + 1, Rings, Slices, Color)
                ]
                || I <- lists:seq(Start, End),
                   J <- lists:seq(0, Slices - 1)
            ]);
        false ->
            []
    end,
    South = case ToI =:= Rings of
        true ->
            lists:append([
                [
                    hemi_vertex(Center, Radius, Rings - 1, J, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, Rings, 0, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, Rings - 1, J + 1, Rings, Slices, Color)
                ]
                || J <- lists:seq(0, Slices - 1)
            ]);
        false ->
            []
    end,
    North ++ Middle ++ South.

hemi_latitudes(Center, Radius, Rings, Slices, FromI, ToI, Color) ->
    case FromI =< ToI of
        true ->
            lists:append([
                [
                    hemi_vertex(Center, Radius, I, J, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, I, J + 1, Rings, Slices, Color)
                ]
                || I <- lists:seq(FromI, ToI),
                   J <- lists:seq(0, Slices - 1)
            ]);
        false ->
            []
    end.

hemi_meridians(Center, Radius, Rings, Slices, FromI, ToI, Color) ->
    case FromI =< ToI - 1 of
        true ->
            lists:append([
                [
                    hemi_vertex(Center, Radius, I, J, Rings, Slices, Color),
                    hemi_vertex(Center, Radius, I + 1, J, Rings, Slices, Color)
                ]
                || J <- lists:seq(0, Slices - 1),
                   I <- lists:seq(FromI, ToI - 1)
            ]);
        false ->
            []
    end.

cylinder_side({_, Y1, _} = TopCenter, {_, Y0, _} = BotCenter, Radius, Slices, Color) ->
    case Y0 =:= Y1 of
        true ->
            [];
        false ->
            lists:append([
                begin
                    B0 = equator_point(BotCenter, Radius, J, Slices),
                    B1 = equator_point(BotCenter, Radius, J + 1, Slices),
                    T0 = equator_point(TopCenter, Radius, J, Slices),
                    T1 = equator_point(TopCenter, Radius, J + 1, Slices),
                    [
                        ?VERTEX3(B0, Color), ?VERTEX3(B1, Color), ?VERTEX3(T1, Color),
                        ?VERTEX3(B0, Color), ?VERTEX3(T1, Color), ?VERTEX3(T0, Color)
                    ]
                end
                || J <- lists:seq(0, Slices - 1)
            ])
    end.

cylinder_verticals({_, Y1, _} = TopCenter, {_, Y0, _} = BotCenter, Radius, Slices, Color) ->
    case Y0 =:= Y1 of
        true ->
            [];
        false ->
            lists:append([
                [
                    ?VERTEX3(equator_point(BotCenter, Radius, J, Slices), Color),
                    ?VERTEX3(equator_point(TopCenter, Radius, J, Slices), Color)
                ]
                || J <- lists:seq(0, Slices - 1)
            ])
    end.

equator_point({X, Y, Z}, Radius, J, Slices) ->
    Phi = (2.0 * math:pi()) * J / Slices,
    {X + Radius * math:sin(Phi), Y, Z + Radius * math:cos(Phi)}.

hemi_vertex(Center, Radius, I, J, Rings, Slices, Color) ->
    {X, Y, Z} = unit_sphere_point(I, J, Rings, Slices),
    {Cx, Cy, Cz} = Center,
    ?VERTEX3({Cx + Radius * X, Cy + Radius * Y, Cz + Radius * Z}, Color).

unit_sphere_point(0, _J, _Rings, _Slices) ->
    {0.0, 1.0, 0.0};
unit_sphere_point(I, _J, Rings, _Slices) when I =:= Rings ->
    {0.0, -1.0, 0.0};
unit_sphere_point(I, J, Rings, Slices) ->
    Theta = math:pi() * I / Rings,
    Phi = (2.0 * math:pi()) * J / Slices,
    SinTheta = math:sin(Theta),
    {
        SinTheta * math:sin(Phi),
        math:cos(Theta),
        SinTheta * math:cos(Phi)
    }.

shape_from_vertices(Vertices, PrimitiveType) ->
    case graphics_mesh3:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, graphics_shape3:with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.
