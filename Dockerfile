FROM rust:1.65-slim-buster as builder

WORKDIR /usr/src/app

COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

# Build only the dependencies to cache them
RUN cargo build --release
RUN rm src/*.rs

# 4. Now that the dependency is built, copy your source code
COPY . /usr/src/app/rcproxy
RUN rm ./target/release/deps/holodeck*
RUN cargo install --path .