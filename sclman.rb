#!/usr/bin/env ruby

require './lib/openstack.rb'
require './lib/chef.rb'
require './lib/db.rb'
require './lib/sensu.rb'
require 'inifile'
require 'daemon_spawn'

class IniLoad
  def initialize
    @ini = IniFile.load("/home/thirai/sclman/sclman.conf")
  end

  def search( section, name )
    val = @ini[section][name]
    return "#{val}"
  end
end

ini = IniLoad.new
$man_flavor = ini.search("MANAGER", "man_flavor")
$man_image = ini.search("MANAGER", "man_image")
$man_key = ini.search("MANAGER", "man_key")

class SclmanDaemon < DaemonSpawn::Base
  def start(args)
    puts "start : #{Time.now}"
    loop do
      # get all of groups(environmet)
      db_group_all = db_search_group_all()
      group_all = db_group_all.uniq
      puts "all of groups : #{group_all}"

      warning_instances = []
      if group_all != [] then
        warning_instances = sensu_get_instance_load()
        groups = []
        wng_group = []
        if warning_instances != [] then
          warning_instances.each do |servers|
            db_group = db_search_group(servers)
            groups << db_group
          end
          wng_group = groups.uniq
          puts "warning groups : #{wng_group[0]}"
          stb_group = group_all - wng_group[0]
          puts "stability groups : #{stb_group}"
          # adding server
          db_count = db_search_count(adding)
          count = db_count - 1
          wng_group[0].each do |adding|
            puts "adding server at #{adding}, count : #{count}"
            instances = db_search_instance(adding)
            instance = instances[2].split("web")
            shortname = instance[0]
            openstack_create_node($man_flavor, $man_image, $man_key, shortname+"web"+count.to_s)
            ipaddr = openstack_search_ip(shortname)
            sleep(20)
            chef_create_node(shortname+"web"+count.to_s, ipaddr, adding, "web")
            insert_table_lbmembers(shortname+"web"+count.to_s, ipaddr, adding)
            update_counter(adding)
            count += 1
          end
        end
      end
      sleep(5)
    end
  end

  def stop
    puts "stop : #{Time.now}"
  end
end

SclmanDaemon.spawn!({
    :working_dir => "/tmp",
    :pid_file => "/tmp/sclman.pid",
    :log_file => "/tmp/sclman.log",
    :sync_log => true,
  })
