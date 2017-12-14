#!/bin/bash

TWD=`pwd`

CLASSPATH="$TWD/basex/*:$TWD/basex/lib/*"

java -cp $CLASSPATH org.basex.BaseXGUI
