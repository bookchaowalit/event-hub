#!/bin/sh
set -eu
# Runtime copies let the broker own its private config without modifying binds.
cp /bootstrap/mosquitto.conf /mosquitto/config/mosquitto.conf
cp /bootstrap/acl /mosquitto/config/acl
cp /bootstrap/passwords /mosquitto/config/passwords
chown mosquitto:mosquitto /mosquitto/config/mosquitto.conf /mosquitto/config/acl /mosquitto/config/passwords /mosquitto/data
chmod 0600 /mosquitto/config/mosquitto.conf /mosquitto/config/acl /mosquitto/config/passwords
exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf
