#!/usr/bin/ruby
require 'usagewatch'
require 'sys/filesystem' #sys-filesystem
require 'firebase'
require 'yaml'
require 'net/smtp'

include Sys

def sync
  usw = Usagewatch

  config = YAML.load_file('config.yml')
  base_uri = config["base_uri"]
  historic_max_size = config["historic_max_size"]
  smtp = config["smtp"]
  restrictions = config["restrictions"]
  mail_notification = config["mail_notification"]


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
                       disk_free_gb: disk_gb_available,
                       date: Time.now
                     }

  historic_fb = firebase.get("historic")
  historic = historic_fb.body
  historic = [] if historic.nil?
  if historic.size > historic_max_size
    historic.shift
  end

  historic << data_to_publish

  firebase.set("historic", historic)
  firebase.set("now", data_to_publish)

  if disk_gb_available <= restrictions['disk_min_free_size']
    Net::SMTP.start(smtp['url_server'], smtp['port'], smtp['url_from'], smtp['user'], smtp['password'], smtp['type']) do |smtp|
      msgstr = <<END_OF_MESSAGE
From: CHITA SYSTEM ALERT <noreply@chita.cl>
To: <#{mail_notification}>
Subject: SYSTEM ALERT

DISK FREE SIZE: #{disk_gb_available} GB
END_OF_MESSAGE

      smtp.send_message msgstr,
                        'noreply@chita.cl',
                        mail_notification
    end

  end
end

def top_cpu size

end

def last size

end

def now

end

case ARGV[0]
when '--sync'
  sync
else
  puts "Bad option"
end
