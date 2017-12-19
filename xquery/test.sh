#!/bin/sh
~/work/basex/bin/basex -bsource_url=EU_Registry_converted_Test.gml iedreg-main.xq > out.html && google-chrome-stable out.html