%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape2_rounded_rectangle_test).
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
    [{Mesh, PrimitiveType, VertexCount}] = graphics_shape2:meshes(Shape),
    {Mesh, PrimitiveType, VertexCount}.

shape2_rounded_rectangle_solid_test() ->
    ok = run_graphics(),

    Position = {0.0, 0.0},
    Size = {100.0, 50.0},
    Radius = 8.0,
    {ok, Default} = graphics_shape2_rounded_rectangle:solid(
        Position, Size, Radius, ?COLOR_RED
    ),
    {_Mesh0, triangle_fan, 38} = shape_mesh(Default),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Default),
    no_texture = graphics_shape2:texture(Default),

    {ok, Shape} = graphics_shape2_rounded_rectangle:solid(
        Position, Size, Radius, 8, ?COLOR_RED
    ),
    {Mesh, triangle_fan, 38} = shape_mesh(Shape),
    [Center | Rim] = positions(graphics_mesh2:remote_vertices(Mesh)),
    true = graphics_vector2:is_equal_to(Center, {50.0, 25.0}, ?EPS),
    true = graphics_vector2:is_equal_to(hd(Rim), lists:last(Rim), ?EPS),
    true = graphics_vector2:is_equal_to(hd(Rim), {0.0, 8.0}, ?EPS),
    true = lists:any(fun(P) ->
        graphics_vector2:is_equal_to(P, {8.0, 0.0}, ?EPS)
    end, Rim),
    true = lists:any(fun(P) ->
        graphics_vector2:is_equal_to(P, {100.0, 8.0}, ?EPS)
    end, Rim),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, graphics_mesh2:remote_vertices(Mesh)),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_rounded_rectangle_outline_test() ->
    ok = run_graphics(),

    {ok, Default} = graphics_shape2_rounded_rectangle:outline(
        {0.0, 0.0}, {100.0, 50.0}, 8.0, 1.0, ?COLOR_RED
    ),
    {_Mesh0, triangle_strip, 74} = shape_mesh(Default),

    {ok, Inward} = graphics_shape2_rounded_rectangle:outline(
        {0.0, 0.0}, {100.0, 50.0}, 8.0, 8, 1.0, ?COLOR_RED
    ),
    {Mesh1, triangle_strip, 74} = shape_mesh(Inward),
    [Outer0, Inner0 | _] = positions(graphics_mesh2:remote_vertices(Mesh1)),
    true = graphics_vector2:is_equal_to(Outer0, {0.0, 8.0}, ?EPS),
    true = graphics_vector2:is_equal_to(Inner0, {1.0, 8.0}, ?EPS),

    {ok, Outward} = graphics_shape2_rounded_rectangle:outline(
        {0.0, 0.0}, {100.0, 50.0}, 8.0, 8, -1.0, ?COLOR_RED
    ),
    {Mesh2, triangle_strip, 74} = shape_mesh(Outward),
    [Outer1, Inner1 | _] = positions(graphics_mesh2:remote_vertices(Mesh2)),
    true = graphics_vector2:is_equal_to(Outer1, {0.0, 8.0}, ?EPS),
    true = graphics_vector2:is_equal_to(Inner1, {-1.0, 8.0}, ?EPS),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Inward),
    ok = graphics_shape2:destroy(Outward),
    ok.

shape2_rounded_rectangle_wires_test() ->
    ok = run_graphics(),

    {ok, Default} = graphics_shape2_rounded_rectangle:wires(
        {0.0, 0.0}, {100.0, 50.0}, 8.0, ?COLOR_RED
    ),
    {_Mesh0, line_loop, 36} = shape_mesh(Default),

    {ok, Shape} = graphics_shape2_rounded_rectangle:wires(
        {0.0, 0.0}, {100.0, 50.0}, 8.0, 4, ?COLOR_RED
    ),
    {Mesh, line_loop, 20} = shape_mesh(Shape),
    true = graphics_vector2:is_equal_to(
        hd(positions(graphics_mesh2:remote_vertices(Mesh))),
        {0.0, 8.0},
        ?EPS
    ),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Shape),
    ok.
