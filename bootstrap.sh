#! /usr/bin/env sh

ls /app
echo "/app/rcproxy default.toml"
RUST_BACKTRACE=1
exec /app/rcproxy /configs/default/default.toml