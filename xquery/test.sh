#!/bin/sh
~/work/basex/bin/basex -bsource_url=inputs/EU_Registry_2019_WI.gml iedreg-main.xq > out.html && google-chrome-stable out.html