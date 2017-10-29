# thelowerroad

The Lower Road (a Minetest Mod)
====================

Adds a long road from -Z to +Z to the world, during world-generation.

The road partially follows the terrain and tunnels through higher ground otherwise.

The road materials depend on the environment. 

Small amounts of loot can be found in little buildings beside the road.

Per default the road will be generated at around x = 100.


Version: 1.2

License: The MIT License (MIT)

Dependencies: default, stairs, farming (found in minetest_game)
Optional Dependencies: lualandmg?

Download from: https://github.com/Distributed-DeadLock/thelowerroad

Compatibility with Mapgens:
generally works with all mapgens which provide a heightmap via minetest.get_mapgen_object
works better when a heatmap is provided as well.

Fully compatible with : v5, v7, flat, fractal, valleys, lualandmg

Compatible with slightly different behaviour with: v6

Not compatible with singlenode unless you provide at least a heightmap in the corresponding lua-mapgenerator, 
see https://github.com/SmallJoker/lualandmg/blob/b72ef91/init.lua#L97-L109 for an example on how to provide heightmap and heatmap properly.

Installation
------------
Unzip the archive, (optionally rename the folder to thelowerroad) and
place it in minetest/mods/

Activate this mod when generating a new world.
The road is generated during world-generation, so
activating it on already existing worlds might not generate one.

Check the advanced configuration-section of Minetest to change the configurable parameters.

For further information or help see:
http://wiki.minetest.com/wiki/Installing_Mods
