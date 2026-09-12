%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape2_ring_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

positions(Vertices) ->
    [Position || {Position, _Color, _U, _V} <- Vertices].

shape_mesh(Shape) ->
    [{Mesh, PrimitiveType, VertexCount}] = shape2:meshes(Shape),
    {Mesh, PrimitiveType, VertexCount}.

shape2_ring_solid_test() ->
    ok = run_graphics(),

    {ok, Default} = shape2_ring:solid({0.0, 0.0}, 4.0, 8.0, ?COLOR_RED),
    {_Mesh0, triangle_strip, 66} = shape_mesh(Default),
    ?MATRIX3_IDENTITY = shape2:matrix(Default),
    no_texture = shape2:texture(Default),

    {ok, Shape} = shape2_ring:solid({0.0, 0.0}, 3.0, 10.0, 8, ?COLOR_RED),
    {Mesh, triangle_strip, 18} = shape_mesh(Shape),
    [Outer0, Inner0 | _] = positions(mesh2:remote_vertices(Mesh)),
    true = vector2:is_equal_to(Outer0, {10.0, 0.0}, ?EPS),
    true = vector2:is_equal_to(Inner0, {3.0, 0.0}, ?EPS),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, mesh2:remote_vertices(Mesh)),

    ok = shape2:destroy(Default),
    ok = shape2:destroy(Shape),
    ok.

shape2_ring_outline_test() ->
    ok = run_graphics(),

    {ok, Default} = shape2_ring:outline({0.0, 0.0}, 4.0, 8.0, 1.0, ?COLOR_RED),
    [{_, triangle_strip, 66}, {_, triangle_strip, 66}] = shape2:meshes(Default),

    {ok, Inward} = shape2_ring:outline({0.0, 0.0}, 4.0, 10.0, 8, 1.0, ?COLOR_RED),
    [
        {OuterMesh, triangle_strip, 18},
        {InnerMesh, triangle_strip, 18}
    ] = shape2:meshes(Inward),
    [Outer0, OuterInner0 | _] = positions(mesh2:remote_vertices(OuterMesh)),
    true = vector2:is_equal_to(Outer0, {10.0, 0.0}, ?EPS),
    true = vector2:is_equal_to(OuterInner0, {9.0, 0.0}, ?EPS),
    [Inner0, InnerOuter0 | _] = positions(mesh2:remote_vertices(InnerMesh)),
    true = vector2:is_equal_to(Inner0, {4.0, 0.0}, ?EPS),
    true = vector2:is_equal_to(InnerOuter0, {5.0, 0.0}, ?EPS),

    {ok, Outward} = shape2_ring:outline({0.0, 0.0}, 4.0, 10.0, 8, -1.0, ?COLOR_RED),
    [
        {OuterMesh2, triangle_strip, 18},
        {InnerMesh2, triangle_strip, 18}
    ] = shape2:meshes(Outward),
    [Outer1, OuterInner1 | _] = positions(mesh2:remote_vertices(OuterMesh2)),
    true = vector2:is_equal_to(Outer1, {10.0, 0.0}, ?EPS),
    true = vector2:is_equal_to(OuterInner1, {11.0, 0.0}, ?EPS),
    [Inner1, InnerOuter1 | _] = positions(mesh2:remote_vertices(InnerMesh2)),
    true = vector2:is_equal_to(Inner1, {4.0, 0.0}, ?EPS),
    true = vector2:is_equal_to(InnerOuter1, {3.0, 0.0}, ?EPS),

    ok = shape2:destroy(Default),
    ok = shape2:destroy(Inward),
    ok = shape2:destroy(Outward),
    ok.

shape2_ring_wires_test() ->
    ok = run_graphics(),

    {ok, Default} = shape2_ring:wires({0.0, 0.0}, 4.0, 8.0, ?COLOR_RED),
    [{_, line_loop, 32}, {_, line_loop, 32}] = shape2:meshes(Default),

    {ok, Shape} = shape2_ring:wires({0.0, 0.0}, 3.0, 10.0, 8, ?COLOR_RED),
    [{OuterMesh, line_loop, 8}, {InnerMesh, line_loop, 8}] = shape2:meshes(Shape),
    true = vector2:is_equal_to(
        hd(positions(mesh2:remote_vertices(OuterMesh))),
        {10.0, 0.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        hd(positions(mesh2:remote_vertices(InnerMesh))),
        {3.0, 0.0},
        ?EPS
    ),

    ok = shape2:destroy(Default),
    ok = shape2:destroy(Shape),
    ok.
