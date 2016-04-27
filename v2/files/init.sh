#!/bin/sh

echo "starting udhcpc"
udhcpc

echo "run systeminfo"
./bin/systeminfo

exec /bin/sh
