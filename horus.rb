#!/usr/bin/ruby

require 'ap'
require 'byebug'

def load_avg
  File.open("/proc/loadavg", "r") do |f|
    lines = f.readlines
    if lines.size > 0
      avg_str = lines[0].gsub('\n','')
      avg = avg_str.split(' ')
      if avg.size > 1
        return avg[0].to_f
      else
        return nil
      end
    end
  end
end

def cpu_percent
  File.open("/proc/stat", "r") do |f|
    lines = f.readlines
    if lines.size > 0
      cpu_str = lines[0].gsub('\n','')
      cpu = cpu_str.split(' ')
      if cpu.size == 11
        tctsb = cpu[1..8].map { |c| c.to_i }.inject(0){|sum,x| sum + x } #Total CPU time since boot
        tcitcb = cpu[4..5].map { |c| c.to_i }.inject(0){|sum,x| sum + x } #Total CPU Idle time since boot
        tcutsb = tctsb - tcitcb #Total CPU usage time since boot
        tcp = tcutsb/tctsb*100 #Total CPU percentage
        byebug
        return tcp
      else
        return nil
      end
    end
  end
end

cpu_percent
