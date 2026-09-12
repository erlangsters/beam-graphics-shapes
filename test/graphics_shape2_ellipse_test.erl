%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape2_ellipse_test).
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

shape2_ellipse_solid_test() ->
    ok = run_graphics(),

    Center = {2.0, 3.0},
    Radii = {5.0, 2.0},
    {ok, Default} = graphics_shape2_ellipse:solid(Center, Radii, ?COLOR_RED),
    {_Mesh0, triangle_fan, 34} = shape_mesh(Default),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Default),
    no_texture = graphics_shape2:texture(Default),

    {ok, Shape} = graphics_shape2_ellipse:solid(Center, Radii, 8, ?COLOR_RED),
    {Mesh, triangle_fan, 10} = shape_mesh(Shape),
    [CenterVertex | Rim] = positions(graphics_mesh2:remote_vertices(Mesh)),
    true = graphics_vector2:is_equal_to(CenterVertex, Center, ?EPS),
    true = graphics_vector2:is_equal_to(hd(Rim), lists:last(Rim), ?EPS),
    true = graphics_vector2:is_equal_to(hd(Rim), {2.0 + 5.0, 3.0}, ?EPS),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, graphics_mesh2:remote_vertices(Mesh)),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_ellipse_outline_test() ->
    ok = run_graphics(),

    {ok, Default} = graphics_shape2_ellipse:outline({0.0, 0.0}, {5.0, 3.0}, 1.0, ?COLOR_RED),
    {_Mesh0, triangle_strip, 66} = shape_mesh(Default),

    {ok, Inward} = graphics_shape2_ellipse:outline({0.0, 0.0}, {10.0, 4.0}, 8, 2.0, ?COLOR_RED),
    {Mesh1, triangle_strip, 18} = shape_mesh(Inward),
    [Outer0, Inner0 | _] = positions(graphics_mesh2:remote_vertices(Mesh1)),
    true = graphics_vector2:is_equal_to(Outer0, {10.0, 0.0}, ?EPS),
    true = graphics_vector2:is_equal_to(Inner0, {8.0, 0.0}, ?EPS),

    {ok, Outward} = graphics_shape2_ellipse:outline({0.0, 0.0}, {10.0, 4.0}, 8, -2.0, ?COLOR_RED),
    {Mesh2, triangle_strip, 18} = shape_mesh(Outward),
    [Outer1, Inner1 | _] = positions(graphics_mesh2:remote_vertices(Mesh2)),
    true = graphics_vector2:is_equal_to(Outer1, {10.0, 0.0}, ?EPS),
    true = graphics_vector2:is_equal_to(Inner1, {12.0, 0.0}, ?EPS),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Inward),
    ok = graphics_shape2:destroy(Outward),
    ok.

shape2_ellipse_wires_test() ->
    ok = run_graphics(),

    {ok, Default} = graphics_shape2_ellipse:wires({0.0, 0.0}, {1.0, 0.5}, ?COLOR_RED),
    {_Mesh0, line_loop, 32} = shape_mesh(Default),

    {ok, Shape} = graphics_shape2_ellipse:wires({0.0, 0.0}, {4.0, 2.0}, 8, ?COLOR_RED),
    {Mesh, line_loop, 8} = shape_mesh(Shape),
    true = graphics_vector2:is_equal_to(
        hd(positions(graphics_mesh2:remote_vertices(Mesh))),
        {4.0, 0.0},
        ?EPS
    ),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Shape),
    ok.
