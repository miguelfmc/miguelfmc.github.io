#!/bin/bash
find . -type f -name "*.jpg" -exec sh -c 'sips -Z 640 "$1" -o "${1%.*}_resized.jpg"' _ {} \;
