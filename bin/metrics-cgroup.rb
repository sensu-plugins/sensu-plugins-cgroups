#!/usr/bin/env ruby
#
#   metrics-cgroup
#
# DESCRIPTION:
#   This plugin collects cgroup metrics.
#
# OUTPUT:
#   metrics data in graphite
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   # Collect all cgroup metrics, tested only on CentOS.
#   metrics-cgroup.rb -g "/sys/fs/cgroup/**/**"
#
#   # Collect only systemd service metrics
#   metrics-cgroup.rb -g "/sys/fs/cgroup/**/system.slice/*"
#
#   # Collect only user.slice only
#   metrics-cgroup.rb -g "/sys/fs/cgroup/**/user.slice"
#
#   # Collect only mesos task metrics
#   metrics-cgroup.rb -g "/sys/fs/cgroup/**/mesos/*"
#
#   # Collect only docker container metrics
#   # (may not be meaningful if you already collect metrics from docker)
#   metrics-cgroup.rb -g "/sys/fs/cgroup/**/docker/*"
#
#   # collect only system.slice, user.slice, docker and mesos and nothing else
#   metrics-cgroup.rb -g "/sys/fs/cgroup/**/{system.slice,user.slice,docker,mesos}{,/*}"
#
#   # Instead of collecting breakdown of each docker instance, or
#   # mesos task, or systemd service metric; this could let to
#   # collect/compare overall docker, mesos, systemd and user recources
#   # in total.
#   metrics-cgroup.rb -g "/sys/fs/cgroup/**/{system.slice,user.slice,docker,mesos}"
#
# LICENCE:
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
require 'sensu-plugin/metric/cli'
require 'socket'

class CgroupMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to queue_name.metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.cgroup"
  option :glob,
         description: 'This should match a cgroup directories in a cgroup filesystem. '\
                      '(default: /sys/fs/cgroup/**/**)',
         short: '-g GLOB',
         long: '--glob GLOB',
         default: '/sys/fs/cgroup/**/**'
  option :files_whitelist,
         description: 'Limit metric collection to this files, comma seperated '\
                      'list of files in cgroup directories. (default is to '\
                      'collect all files)',
         short: '-f FILES_WHITELIST',
         long: '--files-whitelist FILES_WHITELIST',
         default: NIL
  option :files_blacklist,
         description: 'Don\'t collect these files, comma seperated list of file '\
                      'names in cgroup directories. This list will override '\
                      'whitelist if confict. "tasks" and "cgroup.procs" will '\
                      'always appended to the list. (default: '\
                      '"cgroup.clone_children,notify_on_release")',
         short: '-b FILES_BLACKLIST',
         long: '--files-blacklist FILES_BLACKLIST',
         default: 'cgroup.clone_children,notify_on_release'
  option :smart_paths,
         description: 'Instead of using full cgroup path in metrics this '\
                      'enabling smarter metrics names',
         short: '-p',
         long: '--no-smart-paths',
         boolean: true

  def get_tag(cgroup_dir)
    if config[:smart_paths]
      "path.#{cgroup_dir.gsub(/[.\/]/, '_')}"
    else
      # use cgroup consumer specific tags
      type, val = cgroup_dir.split(File::SEPARATOR)[-2..-1]
      case type
      when 'docker'
        "docker_id.#{val}"
      when 'mesos'
        "mesos_container_id.#{val}"
      when 'system.slice'
        "systemd_unit.#{val.gsub(/[.\/]/, '_')}"
      else
        "path.#{cgroup_dir.gsub(/[.\/]/, '_')}"
      end
    end
  end

  def run
    matching_dirs = Dir.glob(config[:glob])
    if matching_dirs.empty?
      critical "No matching directory for glob: #{config[:glob]}"
    end

    # Add 'tasks' and 'cgroup.procs' to blacklist
    files_to_skip = config[:files_blacklist].split(',') + ['tasks', 'cgroup.procs']

    matching_dirs.each do |cgroup_dir|
      # Each matching object needs to be a cgroup directory, which always have a tasks file
      next if !File.directory?(cgroup_dir) || !File.file?("#{cgroup_dir}/tasks")

      Dir.glob("#{cgroup_dir}/*").each do |file|
        next if !File.file?(file) || !File.readable?(file)

        filename = File.basename(file)

        files_whitelist = config[:files_whitelist]
        unless files_whitelist.nil?
          # skip if there is a whitelisted files list and it's not in the list
          next unless files_whitelist.split(',').include?(filename)
        end

        # skip if the file is in blacklisted files list
        next if files_to_skip.include?(filename)

        # Skip files that can't be read
        begin
          lines = File.readlines(file)
        rescue Errno::EIO
          next
        end

        tag = get_tag(cgroup_dir)
        metric_prefix = [config[:scheme], tag, filename.tr('.', '_')].join('.')

        # block that parses most types of files under cgroup file system
        if lines.size == 1
          if /^(?<value>[\d-]+)$/=~ lines[0]
            output(metric_prefix, value)
          elsif /^(?<key>\w+) (?<value>[\d-]+)$/ =~ lines[0]
            output([metric_prefix, key].join('.'), value)
          elsif /^(?<values>([\d-]+ ?)+)$/ =~ lines[0]
            values.split.each_with_index do |val, index|
              output([metric_prefix, index].join('.'), val)
            end
          end
        else
          lines.each_with_index do |line, index|
            if /^(?<value>[\d-]+)$/=~ line
              output([metric_prefix, index].join('.'), value)
            elsif /^(?<key>\w+) (?<value>[\d-]+)$/ =~ line
              output([metric_prefix, key].join('.'), value)
            elsif /^(?<dev>[\w:]+) (?<key>\w+) (?<value>[\d-]+)$/ =~ line
              output([metric_prefix, dev.tr(':', '_'), key].join('.'), value)
            end
          end
        end
      end
    end

    ok
  end
end
