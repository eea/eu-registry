#!/bin/sh

BASEX_VERSION="8.6.7"
JETTY_RUNNER_VERSION="9.4.8.v20171121"

BASEX_WAR="BaseX$(echo $BASEX_VERSION | sed 's/\.//g').war"
BASEX_URL="http://files.basex.org/releases/$BASEX_VERSION/$BASEX_WAR"

JETTY_RUNNER_JAR="jetty-runner-${JETTY_RUNNER_VERSION}.jar"
JETTY_RUNNER_URL="http://central.maven.org/maven2/org/eclipse/jetty/jetty-runner/$JETTY_RUNNER_VERSION/$JETTY_RUNNER_JAR"

if [ ! -s BaseX.war ]; then
	wget -qO BaseX.war "$BASEX_URL"
fi

if [ ! -s jetty-runner.jar ]; then
	wget -qO jetty-runner.jar "$JETTY_RUNNER_URL"
fi
