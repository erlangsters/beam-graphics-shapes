%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape2_ring).
-moduledoc """
2D Ring

A 2D ring is a filled, outlined, or wireframe annulus that is typically used
for rendering. It constructs a core `graphics:shape2()`.

A ring is positioned by its center. `InnerRadius` and `OuterRadius` are
first-class radii, not a thickness relative to one radius. That is the
difference from `graphics_shape2:circle_outline/4`. Tessellation defaults to 32
segments. Outline thickness is signed: positive grows into the annulus from
both rims, negative grows away from both rims.

```erlang
{ok, Shape} = graphics_shape2_ring:solid({0.0, 0.0}, 4.0, 8.0, ?COLOR_RED).
ok = graphics_surface:draw_shape2(Surface, Shape).
ok = graphics_shape2:destroy(Shape).
```

Generated vertices use UV coordinates `(0.0, 0.0)`. Dispose the shape with
`graphics_shape2:destroy/1`.

Beware that a well-formed 2D ring always uses floats, not integers, for
positions, radii, thickness, and colors.
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

-define(DEFAULT_SEGMENTS, 32).

-doc """
A solid 2D ring.

It constructs a 2D shape that draws a filled annulus centered at the given
point. The tessellation is 32 segments.

It's equivalent to `solid(Center, InnerRadius, OuterRadius, 32, Color)`.
""".
-spec solid(
    Center :: graphics:vector2(),
    InnerRadius :: float(),
    OuterRadius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
solid(Center, InnerRadius, OuterRadius, Color) ->
    solid(Center, InnerRadius, OuterRadius, ?DEFAULT_SEGMENTS, Color).

-doc """
A solid 2D ring with a segment count.

It constructs a 2D shape that draws a filled annulus centered at the given
point, tessellated with the given number of segments. `Segments` is a positive
integer.
""".
-spec solid(
    Center :: graphics:vector2(),
    InnerRadius :: float(),
    OuterRadius :: float(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
solid({X, Y}, InnerRadius, OuterRadius, Segments, Color) ->
    shape_from_vertices(
        annulus_vertices(X, Y, InnerRadius, OuterRadius, Segments, Color),
        triangle_strip
    ).

-doc """
A 2D ring outline.

It constructs a 2D shape that draws a filled border on both rims of an
annulus. The tessellation is 32 segments. Positive `Thickness` grows into the
annulus (the outer rim stays `OuterRadius` and the inner rim stays
`InnerRadius`). Negative `Thickness` grows away from both rims.

It's equivalent to
`outline(Center, InnerRadius, OuterRadius, 32, Thickness, Color)`.
""".
-spec outline(
    Center :: graphics:vector2(),
    InnerRadius :: float(),
    OuterRadius :: float(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
outline(Center, InnerRadius, OuterRadius, Thickness, Color) ->
    outline(
        Center,
        InnerRadius,
        OuterRadius,
        ?DEFAULT_SEGMENTS,
        Thickness,
        Color
    ).

-doc """
A 2D ring outline with a segment count.

It constructs a 2D shape that draws a filled border on both rims of an
annulus, tessellated with the given number of segments. `Segments` is a
positive integer. Positive `Thickness` grows into the annulus. Negative
`Thickness` grows away from both rims.
""".
-spec outline(
    Center :: graphics:vector2(),
    InnerRadius :: float(),
    OuterRadius :: float(),
    Segments :: pos_integer(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
outline({X, Y}, InnerRadius, OuterRadius, Segments, Thickness, Color) ->
    OuterBand = annulus_vertices(
        X, Y, OuterRadius - Thickness, OuterRadius, Segments, Color
    ),
    InnerBand = annulus_vertices(
        X, Y, InnerRadius + Thickness, InnerRadius, Segments, Color
    ),
    shape_from_vertex_groups([
        {OuterBand, triangle_strip},
        {InnerBand, triangle_strip}
    ]).

-doc """
A 2D ring wireframe.

It constructs a 2D shape that draws the inner and outer circumferences of an
annulus as two line loops. The tessellation is 32 segments.

It's equivalent to `wires(Center, InnerRadius, OuterRadius, 32, Color)`.
""".
-spec wires(
    Center :: graphics:vector2(),
    InnerRadius :: float(),
    OuterRadius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
wires(Center, InnerRadius, OuterRadius, Color) ->
    wires(Center, InnerRadius, OuterRadius, ?DEFAULT_SEGMENTS, Color).

-doc """
A 2D ring wireframe with a segment count.

It constructs a 2D shape that draws the inner and outer circumferences of an
annulus as two line loops, tessellated with the given number of segments.
`Segments` is a positive integer.
""".
-spec wires(
    Center :: graphics:vector2(),
    InnerRadius :: float(),
    OuterRadius :: float(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
wires({X, Y}, InnerRadius, OuterRadius, Segments, Color) ->
    shape_from_vertex_groups([
        {circle_loop(X, Y, OuterRadius, Segments, Color), line_loop},
        {circle_loop(X, Y, InnerRadius, Segments, Color), line_loop}
    ]).

annulus_vertices(X, Y, InnerRadius, OuterRadius, Segments, Color) ->
    AngleStep = (2.0 * math:pi()) / Segments,
    Rim = fun(I, Radius) ->
        Angle = AngleStep * I,
        ?VERTEX2(
            {X + Radius * math:cos(Angle), Y + Radius * math:sin(Angle)},
            Color
        )
    end,
    Pairs = lists:append([
        [Rim(I, OuterRadius), Rim(I, InnerRadius)]
        || I <- lists:seq(0, Segments - 1)
    ]),
    Pairs ++ [Rim(0, OuterRadius), Rim(0, InnerRadius)].

circle_loop(X, Y, Radius, Segments, Color) ->
    AngleStep = (2.0 * math:pi()) / Segments,
    [
        ?VERTEX2(
            {X + Radius * math:cos(AngleStep * I), Y + Radius * math:sin(AngleStep * I)},
            Color
        )
        || I <- lists:seq(0, Segments - 1)
    ].

shape_from_vertices(Vertices, PrimitiveType) ->
    case graphics_mesh2:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, graphics_shape2:with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.

shape_from_vertex_groups(Groups) ->
    shape_from_vertex_groups(Groups, []).

shape_from_vertex_groups([], Acc) ->
    {ok, graphics_shape2:with_meshes(lists:reverse(Acc))};
shape_from_vertex_groups([{Vertices, PrimitiveType} | Rest], Acc) ->
    case graphics_mesh2:with_vertices(Vertices) of
        {ok, Mesh} ->
            Item = {Mesh, PrimitiveType, length(Vertices)},
            shape_from_vertex_groups(Rest, [Item | Acc]);
        out_of_memory ->
            lists:foreach(fun({Created, _, _}) ->
                graphics_mesh2:destroy(Created)
            end, Acc),
            out_of_memory
    end.
