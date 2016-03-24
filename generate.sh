#!/bin/bash

function usage
{
    echo "Usage: ./generate.sh "
    echo "  * -r | --resolution=<string> : Map resolution (10m, 50m, 110m) [default: 110m]"
    echo "  * -a | --skip-antarctica : Remove Antarctica from the map [default: false]"
    echo "  * -s | --include-states : Include States/Provinces lakes on the map [default: false]"
    echo "  * -l | --include-lakes : Include Great lakes on the map [default: false]"
    echo "  * -p | --include-projection : Embed projection into the topojson file"
    echo "  * -c | --clean : Remove all generated maps and downloaded assets"
    echo "  * -h | --help : Showing this useful message"
}

function clean
{
    rm -rf assets
    rm -rf json
    echo "Cleaned!"
}

# OPTIONS
RESOLUTION="110m"
SKIP_ANTARCTICA=0
INCLUDE_STATES=0
INCLUDE_LAKES=0
INCLUDE_PROJECTION=0

while [ "$1" != "" ]; do
    case $1 in
        -r | --resolution )        shift
                                   RESOLUTION=$1
                                   ;;
        -a | --skip-antarctica )    SKIP_ANTARCTICA=1
                                   ;;
        -p | --include-projection )INCLUDE_PROJECTION=1
                                   ;;
        -l | --include-lakes )     INCLUDE_LAKES=1
                                   ;;
        -s | --include-states )    INCLUDE_STATES=1
                                   ;;
        -c | --clean )             clean
                                   exit
                                   ;;
        -h | --help )              usage
                                   exit
                                   ;;
        * )                        usage
                                   exit 1
    esac
    shift
done

# STARTING HERE

if [ "$INCLUDE_STATES" -eq 1 ]; then
	BASEMAP="admin_1_states_provinces"
else
	BASEMAP="admin_0_countries"
fi

if [ "$INCLUDE_LAKES" -eq 1 ]; then
	BASEMAP="$BASEMAP""_lakes"
fi


BASEMAP_URL="http://naciscdn.org/naturalearth/""$RESOLUTION""/cultural/ne_""$RESOLUTION""_""$BASEMAP"".zip"

TOPOJSON="node_modules/.bin/topojson"
TOPOJSON_MERGE="node_modules/.bin/topojson-merge"

# Check whether topojson was installed globally
which topojson > /dev/null
if [ "$?" -eq 0 ]; then
	# It was
	TOPOJSON=$(which topojson)
fi

# Do the same for topojson-merge
which topojson-merge > /dev/null
if [ "$?" -eq 0 ]; then
	TOPOJSON_MERGE=$(which topojson-merge)
fi


BASEMAP_DIR="assets/""$BASEMAP"
JSON_DIR="maps"
mkdir -p "$BASEMAP_DIR"
mkdir -p "$JSON_DIR"


if [ ! -f assets/sphere.json ]; then
	echo '{"type": "Sphere"}' > assets/sphere.json
fi

if [ ! -f "$BASEMAP_DIR""/""ne_""$RESOLUTION""_""$BASEMAP"".shp" ]; then
	echo "Downloading Basemap"
	curl -o "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP"".zip" "$BASEMAP_URL" --progress-bar
	unzip -q -d "$BASEMAP_DIR" "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP"".zip"
	rm -rf "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP.zip"
	rm -rf "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP.README.html"
	rm -rf "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP.VERSION.txt"

fi

if [ ! -f "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP""_wo_antarctica.shp" ]; then
  if which ogr2ogr >/dev/null; then
    # Thanks: https://github.com/dwtkns/gdal-cheat-sheet
    ogr2ogr -where 'ISO_A2 != "AQ"' "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP""_wo_antarctica.shp" \
  	 "$BASEMAP_DIR""/ne_""$RESOLUTION""_""$BASEMAP"".shp"
  else
    echo "ogr2ogr not found. Please install GDAL before executing this command. (brew install gdal)"
    exit
  fi
fi

if [ "$SKIP_ANTARCTICA" -eq 1 ]; then
	SHP_TO_USE="ne_""$RESOLUTION""_""$BASEMAP""_wo_antarctica"
else
	SHP_TO_USE="ne_""$RESOLUTION""_""$BASEMAP"
fi

if [ "$INCLUDE_PROJECTION" -eq 1 ]; then
    TOPOJSON_PARAMS="--projection='width = 960, height = 500, \
d3.geo.equirectangular().rotate([-11.0, 0.0, 0.0]).scale(width /(2 * Math.PI)).translate([width / 2, height / 2])' \
--width=960 --height=500"
    OUTPUT_SUFFIX="_projected"
else
    TOPOJSON_PARAMS=""
    OUTPUT_SUFFIX=""
fi

# Thanks Mike Bostock: https://gist.github.com/mbostock/c1c0426d50ca8a9f4c97
TOPOJSON_CMD="$TOPOJSON --quantization 1e5 ""$TOPOJSON_PARAMS"" --id-property=iso_a2 -p iso_a2 "\
"-p iso_a3 -p continent -p name -- countries=\"""$BASEMAP_DIR""/""$SHP_TO_USE"".shp\" sphere=assets/sphere.json "\
"| $TOPOJSON_MERGE --io countries --oo land -o \"""$JSON_DIR""/""$SHP_TO_USE""$OUTPUT_SUFFIX"".json\""

eval "$TOPOJSON_CMD"
