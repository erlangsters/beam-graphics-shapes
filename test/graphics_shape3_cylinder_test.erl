%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape3_cylinder_test).
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
    [{Mesh, PrimitiveType, VertexCount}] = graphics_shape3:meshes(Shape),
    {Mesh, PrimitiveType, VertexCount}.

has_point(Positions, Point) ->
    lists:any(fun(Position) ->
        graphics_vector3:is_equal_to(Position, Point, ?EPS)
    end, Positions).

no_zero_segments([]) ->
    true;
no_zero_segments([A, B | Rest]) ->
    (not graphics_vector3:is_equal_to(A, B, ?EPS)) andalso no_zero_segments(Rest).

shape3_cylinder_solid_test() ->
    ok = run_graphics(),

    Center = {1.0, 2.0, 3.0},
    Radius = 4.0,
    Height = 6.0,
    {ok, Default} = graphics_shape3_cylinder:solid(Center, 1.0, 2.0, ?COLOR_RED),
    {_Mesh0, triangles, 192} = shape_mesh(Default),
    ?MATRIX4_IDENTITY = graphics_shape3:matrix(Default),
    no_texture = graphics_shape3:texture(Default),

    Slices = 8,
    {ok, Shape} = graphics_shape3_cylinder:solid(Center, Radius, Height, Slices, ?COLOR_RED),
    {Mesh, triangles, 96} = shape_mesh(Shape),
    Vertices = graphics_mesh3:remote_vertices(Mesh),
    96 = length(Vertices),
    Positions = positions(Vertices),
    true = has_point(Positions, {1.0, 5.0, 3.0}),
    true = has_point(Positions, {1.0, -1.0, 3.0}),
    true = has_point(Positions, {1.0, -1.0, 7.0}),
    true = has_point(Positions, {1.0, 5.0, 7.0}),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, Vertices),

    ok = graphics_shape3:destroy(Default),
    ok = graphics_shape3:destroy(Shape),
    ok.

shape3_cylinder_wires_test() ->
    ok = run_graphics(),

    {ok, Default} = graphics_shape3_cylinder:wires({0.0, 0.0, 0.0}, 1.0, 2.0, ?COLOR_RED),
    {_Mesh0, lines, 96} = shape_mesh(Default),

    Center = {1.0, 2.0, 3.0},
    {ok, Shape} = graphics_shape3_cylinder:wires(Center, 4.0, 6.0, 8, ?COLOR_RED),
    {Mesh, lines, 48} = shape_mesh(Shape),
    Positions = positions(graphics_mesh3:remote_vertices(Mesh)),
    48 = length(Positions),
    true = has_point(Positions, {1.0, -1.0, 7.0}),
    true = has_point(Positions, {1.0, 5.0, 7.0}),
    true = no_zero_segments(Positions),

    ok = graphics_shape3:destroy(Default),
    ok = graphics_shape3:destroy(Shape),
    ok.
