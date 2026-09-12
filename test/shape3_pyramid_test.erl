%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape3_pyramid_test).
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

shape3_pyramid_solid_test() ->
    ok = run_graphics(),

    Center = {1.0, 2.0, 3.0},
    Size = {2.0, 4.0, 6.0},
    {ok, Shape} = shape3_pyramid:solid(Center, Size, ?COLOR_RED),
    {Mesh, triangles, 18} = shape_mesh(Shape),
    ?MATRIX4_IDENTITY = shape3:matrix(Shape),
    no_texture = shape3:texture(Shape),
    Vertices = mesh3:remote_vertices(Mesh),
    18 = length(Vertices),
    Positions = positions(Vertices),
    {{X0, Y0, Z0}, {_X1, Y1, _Z1}} = box3:from_center_size(Center, Size),
    Apex = {1.0, Y1, 3.0},
    Base = [
        {X0, Y0, Z0}, {1.0 + 1.0, Y0, Z0},
        {X0, Y0, 3.0 + 3.0}, {1.0 + 1.0, Y0, 3.0 + 3.0}
    ],
    true = has_point(Positions, Apex),
    lists:foreach(fun(Corner) ->
        true = has_point(Positions, Corner)
    end, Base),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, Vertices),

    [A, B, C | _] = Positions,
    Normal = vector3:cross_product(
        vector3:subtract(B, A),
        vector3:subtract(C, A)
    ),
    true = vector3:y(Normal) < 0.0,

    ok = shape3:destroy(Shape),
    ok.

shape3_pyramid_wires_test() ->
    ok = run_graphics(),

    Center = {0.0, 0.0, 0.0},
    Size = {2.0, 4.0, 6.0},
    {ok, Shape} = shape3_pyramid:wires(Center, Size, ?COLOR_RED),
    {Mesh, lines, 16} = shape_mesh(Shape),
    Positions = positions(mesh3:remote_vertices(Mesh)),
    16 = length(Positions),
    true = has_point(Positions, {0.0, 2.0, 0.0}),
    {{X0, Y0, Z0}, {X1, _Y1, Z1}} = box3:from_center_size(Center, Size),
    lists:foreach(fun(Corner) ->
        true = has_point(Positions, Corner)
    end, [{X0, Y0, Z0}, {X1, Y0, Z0}, {X0, Y0, Z1}, {X1, Y0, Z1}]),
    true = no_zero_segments(Positions),

    ok = shape3:destroy(Shape),
    ok.
