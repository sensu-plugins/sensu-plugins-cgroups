## Sensu-Plugins-cgroups

[ ![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-cgroups.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-cgroups)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-cgroups.svg)](http://badge.fury.io/rb/sensu-plugins-cgroups)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-cgroups/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-cgroups)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-cgroups/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-cgroups)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-cgroups.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-cgroups)

## Functionality

## Files
 * bin/metrics-cgroup.sh
 * bin/metrics-cgroup.rb

## Usage

Collect all cgroup metrics, tested only on CentOS.

```
metrics-cgroup.rb -g "/sys/fs/cgroup/**/**"
```

Collect only systemd service metrics

```
metrics-cgroup.rb -g "/sys/fs/cgroup/**/system.slice/*"
```

Collect only user.slice only

```
metrics-cgroup.rb -g "/sys/fs/cgroup/**/user.slice"
```

Collect only mesos task metrics

```
metrics-cgroup.rb -g "/sys/fs/cgroup/**/mesos/*"
```

Collect only docker container metrics (may not be meaningful if you already collect metrics from docker)

```
metrics-cgroup.rb -g "/sys/fs/cgroup/**/docker/*"
```

Collect only system.slice, user.slice, docker and mesos and nothing else

```
metrics-cgroup.rb -g "/sys/fs/cgroup/**/{system.slice,user.slice,docker,mesos}{,/*}"
```

Instead of collecting breakdown of each docker instance, or
mesos task, or systemd service metric; this could let to
collect/compare overall docker, mesos, systemd and user recources
in total.

```
metrics-cgroup.rb -g "/sys/fs/cgroup/**/{system.slice,user.slice,docker,mesos}"
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
