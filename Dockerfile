FROM redis as builder 

FROM debian

COPY --from=builder /usr/local/bin/redis-cli /usr/local/bin/redis-cli
COPY target/x86_64-unknown-linux-musl/release/rcproxy /app/rcproxy
COPY default.toml /configs/default/default.toml
COPY cli.yml /app/cli.yml
WORKDIR /app
RUN chmod u+x /app/rcproxy
CMD ["/app/rcproxy" "/configs/default/default.toml"]