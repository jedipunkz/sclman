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
          wng_group[0].each do |adding|
            db_count_adding = db_search_count(adding)
            # count_adding = db_count_adding - 1
            count_adding = db_count_adding
            puts "adding server at #{adding}, count_adding : #{count_adding}"
            instances = db_search_instance(adding)
            instance = instances[2].split("web")
            shortname = instance[0]
            openstack_create_node($man_flavor, $man_image, $man_key, shortname+"web"+count_adding.to_s)
            ipaddr = openstack_search_ip(shortname)
            sleep(20)
            chef_create_node(shortname+"web"+count_adding.to_s, ipaddr, adding, "web")
            insert_table_lbmembers(shortname+"web"+count_adding.to_s, ipaddr, adding)
            count_adding += 1
            update_inc_counter(adding)
          end
        elsif stb_group =! [] then
          stb_group.each do |deleting|
            db_count_deleting = db_search_count(deleting)
            # count_deleting = db_count_deleting - 1
            count_deleting = db_count_deleting
            if count_deleting.to_i >= 4 then
              puts "deleting server at #{deleting}, count_deleting : #{count_deleting}"
              instances = db_search_instance(deleting)
              instance = instances[2].split("web")
              shortname = instance[0]
              openstack_delete_node(shortname+"web"+count_deleting.to_s)
              chef_delete_node(shortname+"web"+count_deleting.to_s)
              delete_table_lbmembers(shortname+"web"+count_deleting.to_s)
              #count_deleting -= 1
              update_dec_counter(deleting)
            end
          end
        elsif warning_instances == [] then
          group_all.each do |deleting|
            db_count_deleting = db_search_count(deleting)
            count_deleting = db_count_deleting - 1
            #count_deleting = db_count_deleting
            if count_deleting.to_i >= 4 then
              puts "deleting server at #{deleting}, count_deleting : #{count_deleting}"
              instances = db_search_instance(deleting)
              instance = instances[2].split("web")
              shortname = instance[0]
              openstack_delete_node(shortname+"web"+count_deleting.to_s)
              puts shortname+"web"+count_deleting.to_s
              chef_delete_node(shortname+"web"+count_deleting.to_s)
              delete_table_lbmembers(shortname+"web"+count_deleting.to_s)
              #count_deleting -= 1
              update_dec_counter(deleting)
            end
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
