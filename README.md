# 2D/3D shapes for the BEAM graphics library

> :construction: This project is under active development. Do not used at the
> moment as it's not ready. Consult the `develop` branch for progress.

[![Erlangsters Repository](https://img.shields.io/badge/erlangsters-beam--graphics--shapes-%23a90432)](https://github.com/erlangsters/beam-graphics-shapes)
![Supported Erlang/OTP Versions](https://img.shields.io/badge/erlang%2Fotp-28-%23a90432)
![Current Version](https://img.shields.io/badge/version-0.1.0-%23354052)
![License](https://img.shields.io/github/license/erlangsters/beam-graphics-shapes)
[![Build Status](https://img.shields.io/github/actions/workflow/status/erlangsters/beam-graphics-shapes/workflow.yml)](https://github.com/erlangsters/beam-graphics-shapes/actions/workflows/workflow.yml)
[![Documentation Link](https://img.shields.io/badge/documentation-available-yellow)](http://erlangsters.github.io/beam-graphics-shapes/)

A helper library to complement the [graphics library](https://github.com/erlangsters/beam-graphics)
of the BEAM ecosystem with 2D/3D shapes ready to render.

Those modules construct a core `graphics:shape2()` or `graphics:shape3()`.
Draw and destroy them with the core modules.

```erlang
-include_lib("beam_graphics/include/graphics.hrl").

{ok, Ellipse} = graphics_shape2_ellipse:solid({320.0, 240.0}, {80.0, 40.0}, ?COLOR_RED),
ok = graphics_surface:draw_shape2(Surface, Ellipse),
ok = graphics_shape2:destroy(Ellipse).
```

```erlang
{ok, Cylinder} = graphics_shape3_cylinder:solid(
    {0.0, 0.0, 0.0},
    1.0,
    2.0,
    ?COLOR_RED
),
ok = graphics_surface:draw_shape3(Surface, Cylinder),
ok = graphics_shape3:destroy(Cylinder).
```

2D: `graphics_shape2_ellipse`, `graphics_shape2_ring`,
`graphics_shape2_rounded_rectangle`.

3D: `graphics_shape3_capsule`, `graphics_shape3_cylinder`,
`graphics_shape3_pyramid`, `graphics_shape3_torus`.

```erlang
{deps, [
  {beam_graphics, {git, "https://github.com/erlangsters/beam-graphics.git", {tag, "master"}}},
  {beam_graphics_shapes, {git, "https://github.com/erlangsters/beam-graphics-shapes.git", {tag, "master"}}}
]}.
```

Written by the Erlangsters [community](https://about.erlangsters.org/) and
released under the MIT [license](/https://opensource.org/license/mit).
