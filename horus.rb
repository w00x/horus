#!/usr/bin/ruby

require 'ap'
require 'byebug'
require 'usagewatch'
require 'sys/filesystem'
require 'firebase'
require 'yaml'

include Sys
usw = Usagewatch

config = YAML.load_file('config.yml')
base_uri = config["base_uri"]

firebase = Firebase::Client.new(base_uri)

cpu_used = usw.uw_cpuused
load_average = usw.uw_load
cpu_top_proc = usw.uw_cputop
memory_top_proc= usw.uw_memtop

stat = Sys::Filesystem.stat("/")
disk_gb_available = (stat.block_size.to_f * stat.blocks_available.to_f / 1024 / 1024 / 1024).round(2)

data_to_publish = {
                     cpu: cpu_used,
                     load_average: load_average,
                     cpu_top_proc: cpu_top_proc,
                     memory_top_proc: memory_top_proc,
                     disk_free_gb: disk_gb_available
                   }

firebase.push("historico", data_to_publish)
firebase.set("now", data_to_publish)
