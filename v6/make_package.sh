#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <control_file> <root_dir> <package_name>"
    exit 1
fi

CONTROL_FILE=$1
ROOT_DIR=$2
PACKAGE_NAME=$3

tmp_dir=$(mktemp -d)
mkdir "$tmp_dir/control"
cp "$CONTROL_FILE" "$tmp_dir/control"
echo "2.0" > "$tmp_dir/debian-binary"

(cd "$ROOT_DIR" && tar -czf "$tmp_dir/data.tar.gz" *)
tar -C "$tmp_dir" -czf "$tmp_dir/control.tar.gz" control
tar -C "$tmp_dir" -czf "$PACKAGE_NAME" control.tar.gz data.tar.gz debian-binary
