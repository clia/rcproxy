# RCProxy

RCProxy [![LOC](https://tokei.rs/b1/github/clia/rcproxy)](https://github.com/clia/rcproxy)

Forked from [https://github.com/wayslog/aster](https://github.com/wayslog/aster). Thanks!

======================

RCProxy is a lightweight, fast but powerful Redis Cluster Proxy written in Rust.

It supports memcache/redis singleton/redis cluster protocol all in one. RCProxy can proxy with two models:

1. proxy mode: the same as [twemproxy](https://github.com/twitter/twemproxy).
2. cluster mode: proxy for redis cluster. You can use non-cluster redis client access the redis cluster.(Inspired with [Corvus](https://github.com/eleme/corvus))

## Usage

### Build

```bash
cargo build --all --release
```

### Run

```bash
./target/release/rcproxy default.toml
```

### Install

```bash
sudo cp ./target/release/rcproxy /usr/local/bin/
sudo mkdir /etc/rcproxy
sudo cp default.toml /etc/rcproxy/
sudo mkdir /var/log/rcproxy
sudo cp service/systemd/rcproxy.service /lib/systemd/system/
sudo systemctl enable rcproxy
sudo systemctl start rcproxy
```

## Configuration

```Toml
[log]
level = "libaster=info" # "trace" "debug" "info" "warn" "error"
ansi = true  # support ANSI colors
stdout = false # print logs to stdout, not to log files
directory = "/var/log/rcproxy" # log file directory
file_name = "rcproxy.log" # log file name

[metrics]
# change port config, to run multiple instance in one machine.
port = 2110

[[clusters]]
# name of the cluster. Each cluster means one front-end port.
name="test-redis-cluster"

# listen_addr means the cluster front end server address.
listen_addr="0.0.0.0:9001"

# cache_type only support memcache|redis|redis_cluster
cache_type="redis_cluster"

# servers means cache backend. support two format:
# for cache_type is memcache or redis, you can set it as:
#
#   servers = [
#       "127.0.0.1:7001:10 redis-1",
#       "127.0.0.1:7002:10 redis-2",
#       "127.0.0.1:7003:10 redis-3"]
#
# as you can see, the format is consisted with:
#
#       "${addr}:hash_weight ${node_alias}"
#
# And, for redis_cluster you can set the item as:
#
# servers = ["127.0.0.1:7000", "127.0.0.1:7001"]
#
# which means the seed nodes to connect to redis cluster.
servers = ["127.0.0.1:7000", "127.0.0.1:7001", "127.0.0.1:7002", "127.0.0.1:7003", "127.0.0.1:7004", "127.0.0.1:7005"]

# Work thread number, it's suggested as the number of your cpu(hyper-thread) number.
thread = 1

# ReadTimeout is the socket read timeout which effects all in the socket in millisecond
read_timeout = 2000

# WriteTimeout is the socket write timeout which effects all in the socket in millisecond
write_timeout = 2000

############################# Cluster Mode Special #######################################################
# fetch means fetch interval for backend cluster to keep cluster info become newer.
# default 10 * 60 seconds
fetch = 600


# read_from_slave is the feature make slave balanced readed by client and ignore side effects.
read_from_slave = true

############################# Proxy Mode Special #######################################################
# ping_fail_limit means when ping fail reach the limit number, the node will be ejected from the cluster
# until the ping is ok in future.
# if ping_fali_limit == 0, means that close the ping eject feature.
ping_fail_limit=3

# ping_interval means the interval of each ping was send into backend node in millisecond.
ping_interval=10000

# Configure password for backend server. It will send this password to backend server on connect.
# Empty value will be ignored.
auth = "" # mypassw

```

## changelog

see [CHANGELOG.md](/CHANGELOG.md)