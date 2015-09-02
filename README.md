# TopoJSON Map Generator

This script that generates TopoJSON maps with one command line.

## Usage
You would need to install [TopoJSON](https://www.npmjs.com/package/topojson) using npm: `npm install`

Script usage: `./generate.sh [OPTIONS]`

 * `-r` | `--resolution=<string>` : Map resolution (10m, 50m, 110m) [default: 110m]
 * `-a` | `--skip-antarctica` : Remove Antartica from the map [default: false]
 * `-s` | `--include-states` : Include States/Provinces lakes on the map [default: false]
 * `-l` | `--include-lakes` : Include Great lakes on the map [default: false]
 * `-p` | `--include-projection` : Embed projection into the topojson file
 * `-c` | `--clean` : Remove all generated maps and downloaded assets
 * `-h` | `--help` : Showing this useful message

## World Maps

The dataset comes from [NatualEarth](http://www.naturalearthdata.com/downloads/)

## Projection

At the moment the only projection used on this script, when you add the parameter `-p`, is an equirectangular and a size 960x500:

    width = 960, height = 500, d3.geo.equirectangular().rotate([-11.0, 0.0, 0.0]).scale(width /(2 * Math.PI)).translate([width / 2, height / 2])

You can edit it on the script if you targeting another projection.
Here's [an example](Here's an example of where it's used) of where it has been used


## Contribute

You are welcomed to fork the project and make pull requests.
Be sure to create a branch for each feature!
