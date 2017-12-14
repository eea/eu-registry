#!/bin/bash

if [ ! -s BaseX867.zip ]; then
	wget -q http://files.basex.org/releases/8.6.7/BaseX867.zip
fi

unzip -qn BaseX867.zip basex/BaseX.jar
unzip -qn BaseX867.zip basex/lib/basex-api-8.6.7.jar
unzip -qn BaseX867.zip basex/lib/jts-1.13.jar
