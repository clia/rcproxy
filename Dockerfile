FROM ubuntu

COPY target/release/rcproxy /app/rcproxy
COPY default.toml /configs/default.toml

WORKDIR /app
# CMD ls /app/rcproxy
RUN chmod u+x /app/rcproxy
RUN chmod u+x /configs/default.toml
RUN cat /configs/default.toml
CMD /app/rcproxy /configs/default.toml