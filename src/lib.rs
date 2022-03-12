// #![deny(warnings)]
#[macro_use]
extern crate log;
#[macro_use]
extern crate lazy_static;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate failure;
#[macro_use]
extern crate clap;

#[macro_use]
extern crate prometheus;

pub mod metrics;

use clap::App;

pub const ASTER_VERSION: &str = env!("CARGO_PKG_VERSION");

pub mod com;
pub mod protocol;
pub mod proxy;
pub(crate) mod utils;

use std::thread::{self, Builder, JoinHandle};
use std::time::Duration;
// use std::io::Write;
use std::env;

use failure::Error;
// use chrono::Local;

use com::meta::{load_meta, meta_init};
use com::ClusterConfig;
use metrics::thread_incr;
use tracing_appender::non_blocking::WorkerGuard;
use tracing_subscriber::fmt::time::OffsetTime;
use time::macros::format_description;
use time::UtcOffset;
use clia_time::UtcOffset as CliaUtcOffset;

pub fn run() -> Result<(), Error> {
    // env_logger::Env::default().filter_or(env_logger::DEFAULT_FILTER_ENV, "info");
    // env_logger::builder()
    //     .format(|buf, r| {
    //         writeln!(
    //             buf,
    //             "{} {} [{}:{}] {}",
    //             Local::now().format("%Y-%m-%d %H:%M:%S"),
    //             r.level(),
    //             r.module_path().unwrap_or("<unnamed>"),
    //             r.line().unwrap_or(0),
    //             r.args(),
    //         )
    //     })
    //     .init();

    let yaml = load_yaml!("cli.yml");
    let matches = App::from_yaml(yaml).version(ASTER_VERSION).get_matches();
    let config = matches.value_of("config").unwrap_or("default.toml");
    let watch_file = config.to_string();
    let ip = matches.value_of("ip").map(|x| x.to_string());
    let enable_reload = matches.is_present("reload");
    println!("[rcproxy-{}] loading config from {}", ASTER_VERSION, config);
    let cfg = com::Config::load(&config)?;
    // println!("use config : {:?}", cfg);
    assert!(
        !cfg.clusters.is_empty(),
        "clusters is absent of config file"
    );
    assert!(
        !cfg.log.level.is_empty(),
        "log level is absent of config file"
    );
    assert!(
        !cfg.log.directory.is_empty(),
        "log directory is absent of config file"
    );
    assert!(
        !cfg.log.file_name.is_empty(),
        "log file_name is absent of config file"
    );
    assert!(
        cfg.metrics.port != 0,
        "metrics port is absent of config file"
    );
    crate::proxy::standalone::reload::init(&watch_file, cfg.clone(), enable_reload)?;

    let _guard = init_tracing(
        &cfg.log.level,
        cfg.log.ansi,
        cfg.log.stdout,
        &cfg.log.directory,
        &cfg.log.file_name,
    );

    let mut ths = Vec::new();
    for cluster in cfg.clusters.into_iter() {
        if cluster.servers.is_empty() {
            warn!(
                "fail to running cluster {} in addr {} due filed `servers` is empty",
                cluster.name, cluster.listen_addr
            );
            continue;
        }

        if cluster.name.is_empty() {
            warn!(
                "fail to running cluster {} in addr {} due filed `name` is empty",
                cluster.name, cluster.listen_addr
            );
            continue;
        }

        info!(
            "starting aster cluster {} in addr {}",
            cluster.name, cluster.listen_addr
        );

        match cluster.cache_type {
            com::CacheType::RedisCluster => {
                let jhs = spawn_worker(&cluster, ip.clone(), proxy::cluster::spawn);
                ths.extend(jhs);
            }
            _ => {
                let jhs = spawn_worker(&cluster, ip.clone(), proxy::standalone::spawn);
                ths.extend(jhs);
            }
        }
    }

    {
        // let port_str = matches.value_of("metrics").unwrap_or("2110");
        // let port = port_str.parse::<usize>().unwrap_or(2110);
        let port = cfg.metrics.port;
        spawn_metrics(port);
    }

    for th in ths {
        th.join().unwrap();
    }
    Ok(())
}

fn init_tracing(
    level: &str,
    ansi: bool,
    stdout: bool,
    directory: &str,
    file_name: &str,
) -> WorkerGuard {
    let file_appender = tracing_appender::rolling::daily(directory, file_name);
    let (file_writer, guard) = tracing_appender::non_blocking(file_appender);

    let offset_sec = CliaUtcOffset::current_local_offset().expect("Can not get local offset!").whole_seconds();
    let offset = UtcOffset::from_whole_seconds(offset_sec).expect("Can not from whole seconds!");
    let timer = OffsetTime::new(
        offset, 
        format_description!("[year]-[month]-[day] [hour]:[minute]:[second].[subsecond digits:3]"),
    );

    // Configure a custom event formatter
    let format = tracing_subscriber::fmt::format()
        .pretty()
        .with_level(true) // don't include levels in formatted output
        .with_target(true) // don't include targets
        .with_thread_ids(true) // include the thread ID of the current thread
        .with_thread_names(true) // include the name of the current thread
        .with_source_location(true);

    if stdout {
        tracing_subscriber::fmt()
            .event_format(format)
            .with_env_filter(
                tracing_subscriber::EnvFilter::try_from_default_env()
                    .unwrap_or(tracing_subscriber::EnvFilter::new(&format!("{}", level))),
            )
            .with_timer(timer)
            .with_writer(std::io::stdout)
            .with_ansi(ansi)
            .init();
    } else {
        tracing_subscriber::fmt()
            .event_format(format)
            .with_env_filter(
                tracing_subscriber::EnvFilter::try_from_default_env()
                    .unwrap_or(tracing_subscriber::EnvFilter::new(&format!("{}", level))),
            )
            .with_timer(timer)
            .with_writer(file_writer)
            .with_ansi(ansi)
            .init();
    }

    guard
}

fn spawn_worker<T>(cc: &ClusterConfig, ip: Option<String>, spawn_fn: T) -> Vec<JoinHandle<()>>
where
    T: Fn(ClusterConfig) + Copy + Send + 'static,
{
    let worker = cc.thread.unwrap_or(4);
    let meta = load_meta(cc.clone(), ip);
    info!("setup meta info with {:?}", meta);
    (0..worker)
        .map(|_index| {
            let cc = cc.clone();
            let meta = meta.clone();
            Builder::new()
                .name(cc.name.clone())
                .spawn(move || {
                    thread_incr();
                    meta_init(meta);
                    spawn_fn(cc);
                })
                .expect("fail to spawn worker thread")
        })
        .collect()
}

fn spawn_metrics(port: usize) -> Vec<thread::JoinHandle<()>> {
    // wait for worker thread to be ready
    thread::sleep(Duration::from_secs(3));
    vec![
        thread::Builder::new()
            .name("aster-http-srv".to_string())
            .spawn(move || metrics::init(port).unwrap())
            .unwrap(),
        thread::Builder::new()
            .name("measure-service".to_string())
            .spawn(move || metrics::measure_system().unwrap())
            .unwrap(),
    ]
}
