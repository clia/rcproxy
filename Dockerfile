FROM redis as builder 

FROM debian

COPY --from=builder /usr/local/bin/redis-cli /usr/local/bin/redis-cli
COPY target/x86_64-unknown-linux-musl/release/rcproxy /app/rcproxy
# COPY --from=builder /usr/src/rcproxy/target/x86_64-unknown-linux-musl/release/rcproxy /app/rcproxy
COPY default.toml /configs/default/default.toml
COPY cli.yml /app/cli.yml
COPY bootstrap.sh /app/bootstrap.sh
WORKDIR /app
CMD ls /app/
RUN chmod u+x /app/rcproxy && \
    chmod u+x bootstrap.sh
# RUN cat /configs/default.toml
CMD ./bootstrap.sh