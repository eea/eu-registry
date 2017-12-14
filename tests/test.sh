#!/bin/bash

TWD=`pwd`

if [ -s "$1" ]; then
	INPUT="$TWD/$1"
	echo "Loaded $INPUT"
else
	INPUT="$1"
	echo "Fetching $INPUT"
fi

CLASSPATH="$TWD/basex/*:$TWD/basex/lib/*"

cd ../xquery

java -cp $CLASSPATH org.basex.BaseXServer -zS

java -cp $CLASSPATH org.basex.BaseXClient -w -U admin -P admin -b "source_url=$INPUT" iedreg-main.xq > "$TWD"/result.html

java -cp $CLASSPATH org.basex.BaseXServer stop

cd "$TWD"

if [ -s result.html ]; then
  ls -alh result.html
#  webbrowser-app "file://`pwd`/result.html" 2>/dev/null
fi
