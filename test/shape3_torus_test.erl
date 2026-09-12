%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape3_torus_test).
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
    [{Mesh, PrimitiveType, VertexCount}] = shape3:meshes(Shape),
    {Mesh, PrimitiveType, VertexCount}.

has_point(Positions, Point) ->
    lists:any(fun(Position) ->
        vector3:is_equal_to(Position, Point, ?EPS)
    end, Positions).

no_zero_segments([]) ->
    true;
no_zero_segments([A, B | Rest]) ->
    (not vector3:is_equal_to(A, B, ?EPS)) andalso no_zero_segments(Rest).

shape3_torus_solid_test() ->
    ok = run_graphics(),

    {ok, Default} = shape3_torus:solid({0.0, 0.0, 0.0}, 2.0, 0.5, ?COLOR_RED),
    {_Mesh0, triangles, 1536} = shape_mesh(Default),
    ?MATRIX4_IDENTITY = shape3:matrix(Default),
    no_texture = shape3:texture(Default),

    Center = {1.0, 2.0, 3.0},
    Radius = 4.0,
    TubeRadius = 1.0,
    Rings = 8,
    Slices = 8,
    {ok, Shape} = shape3_torus:solid(
        Center, Radius, TubeRadius, Rings, Slices, ?COLOR_RED
    ),
    ExpectedCount = 6 * Rings * Slices,
    {Mesh, triangles, ExpectedCount} = shape_mesh(Shape),
    Vertices = mesh3:remote_vertices(Mesh),
    ExpectedCount = length(Vertices),
    Positions = positions(Vertices),
    true = has_point(Positions, {1.0, 2.0, 3.0 + Radius + TubeRadius}),
    true = has_point(Positions, {1.0, 2.0 + TubeRadius, 3.0 + Radius}),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, Vertices),

    ok = shape3:destroy(Default),
    ok = shape3:destroy(Shape),
    ok.

shape3_torus_wires_test() ->
    ok = run_graphics(),

    {ok, Default} = shape3_torus:wires({0.0, 0.0, 0.0}, 2.0, 0.5, ?COLOR_RED),
    {_Mesh0, lines, 1024} = shape_mesh(Default),

    Center = {1.0, 2.0, 3.0},
    Radius = 4.0,
    TubeRadius = 1.0,
    Rings = 8,
    Slices = 8,
    {ok, Shape} = shape3_torus:wires(
        Center, Radius, TubeRadius, Rings, Slices, ?COLOR_RED
    ),
    ExpectedCount = 4 * Rings * Slices,
    {Mesh, lines, ExpectedCount} = shape_mesh(Shape),
    Positions = positions(mesh3:remote_vertices(Mesh)),
    ExpectedCount = length(Positions),
    true = has_point(Positions, {1.0, 2.0, 3.0 + Radius + TubeRadius}),
    true = no_zero_segments(Positions),

    ok = shape3:destroy(Default),
    ok = shape3:destroy(Shape),
    ok.
