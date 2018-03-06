#!/bin/sh
~/work/basex/bin/basex -bsource_url=2016_14122017_160650.xml iedreg-qa3-main.xq > out.html && google-chrome-stable out.html