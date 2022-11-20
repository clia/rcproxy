FROM rust:1.65.0-slim-buster as builder

RUN apt update && apt install -y musl-tools

WORKDIR /usr/src

# Create blank project
RUN USER=root cargo new rcproxy

# We want dependencies cached, so copy those first.
COPY Cargo.toml Cargo.lock /usr/src/rcproxy/

COPY benches /usr/src/rcproxy/benches

COPY src /usr/src/rcproxy/src/

# Set the working directory
WORKDIR /usr/src/rcproxy

## Install target platform (Cross-Compilation) --> Needed for Alpine
RUN rustup target add x86_64-unknown-linux-musl

# This is a dummy build to get the dependencies cached.
RUN cargo build --target x86_64-unknown-linux-musl --release

# Now copy in the rest of the sources

# This is the actual application build.
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM ubuntu

COPY --from=builder /usr/src/rcproxy/target/x86_64-unknown-linux-musl/release/rcproxy /app/rcproxy
COPY default.toml /app/default.toml
COPY cli.yml /app/cli.yml
WORKDIR /app
# CMD ls /app/rcproxy
# RUN chmod u+x /app/rcproxy
RUN chmod u+x default.toml
# RUN cat /configs/default.toml
CMD /app/rcproxy default.toml