#!/bin/sh
set -e

CONFIG_DIR="/app/server/config"

# If no server.yaml exists (not mounted at runtime, not baked into the
# image) but an example ships in the image, seed one so the container
# doesn't crash on a missing file. This never errors if neither file
# is present - that's a real misconfiguration and server.py should
# surface it, not this script.
if [ ! -f "$CONFIG_DIR/server.yaml" ] && [ -f "$CONFIG_DIR/server.example.yaml" ]; then
    echo "entrypoint: no config/server.yaml found, seeding from server.example.yaml"
    cp "$CONFIG_DIR/server.example.yaml" "$CONFIG_DIR/server.yaml"
fi

exec "$@"