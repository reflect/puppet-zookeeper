# == Class zookeeper::server::jmxtrans
# Sets up a jmxtrans instance for a zookeeper Server Broker
# running on the current host.
# Note: This requires the jmxtrans puppet module found at
# https://github.com/wikimedia/puppet-jmxtrans.
#
# == Parameters
# $jmx_port      - Zookeeper JMX port
# $ganglia       - Ganglia host:port
# $graphite      - Graphite host:port
# $outfile       - outfile to which zookeeper stats will be written.
# $run_interval  - How often jmxtrans should run.        Default: 15
# $log_level     - level at which jmxtrans should log.   Default: info
#
# == Usage
# class { 'zookeeper::server::jmxtrans':
#     ganglia => 'ganglia.example.org:8649'
# }
#
class zookeeper::jmxtrans(
    $jmx_port       = $zookeeper::defaults::jmx_port,
    $ganglia        = undef,
    $graphite       = undef,
    $statsd         = undef,
    $outfile        = undef,
    $group_prefix   = undef,
    $run_interval   = 15,
    $log_level      = 'info',
) inherits zookeeper::defaults
{
    $jmx = "${::fqdn}:${jmx_port}"

    if !defined(Class['::jmxtrans']) {
        class {'::jmxtrans':
            run_interval => $run_interval,
            log_level    => $log_level,
        }
    }

    # query for metrics from zookeeper's JVM
    jmxtrans::metrics::jvm { $jmx:
        ganglia      => $ganglia,
        graphite     => $graphite,
        statsd       => $statsd,
        outfile      => $outfile,
        group_prefix => $group_prefix,
    }

    $zookeeper_objects = [
        {
            'name'          => 'org.apache.ZooKeeperService:name0=*,name1=*,name2=*',
            'resultAlias'   => 'zookeeper',
            'typeNames'     => ['serverId', 'replicaId', 'leaderOrFollower'],
            'attrs'         => {
                'AvgRequestLatency'        => { 'slope' => 'both',      'bucketType' => 'g' },
                'MinRequestLatency'        => { 'slope' => 'both',      'bucketType' => 'g' },
                'MaxRequestLatency'        => { 'slope' => 'both',      'bucketType' => 'g' },
                'MaxClientCnxnsPerHost'    => { 'slope' => 'both',      'bucketType' => 'g' },
                'NumAliveConnections'      => { 'slope' => 'both',      'bucketType' => 'g' },
                'OutstandingRequests'      => { 'slope' => 'both',      'bucketType' => 'g' },
                'PacketsReceived'          => { 'slope' => 'positive',  'bucketType' => 'g' },
                'PacketsSent'              => { 'slope' => 'positive',  'bucketType' => 'g' },
                'PendingRevalidationCount' => { 'slope' => 'both',      'bucketType' => 'g' },
            },
        },
    ]

    # Query zookeeper server for relevant jmx metrics.
    jmxtrans::metrics { "zookeeper-${::hostname}-${jmx_port}":
        jmx                  => $jmx,
        outfile              => $outfile,
        ganglia              => $ganglia,
        ganglia_group_name   => "${group_prefix}zookeeper",
        graphite             => $graphite,
        graphite_root_prefix => "${group_prefix}zookeeper",
        statsd               => $statsd,
        statsd_root_prefix   => "${group_prefix}zookeeper",
        objects              => $zookeeper_objects,
    }
}
