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

def make_shortname(environment)
  instances = db_search_instance(environment)
  instance = instances[2].split("web")
  return instance[0]
end

def add_server()
  $wng_group[0].each do |adding|
    db_count_adding = db_search_count(adding)
    count_adding = db_count_adding
    puts "adding server at #{adding}, count_adding : #{count_adding}"
    shortname = make_shortname(adding)
    openstack_create_node($man_flavor, $man_image, $man_key, shortname+"web"+count_adding.to_s)
    ipaddr = openstack_search_ip(shortname)
    sleep(20)
    chef_create_node(shortname+"web"+count_adding.to_s, ipaddr, adding, "web")
    insert_table_lbmembers(shortname+"web"+count_adding.to_s, ipaddr, adding)
    count_adding += 1
    update_inc_counter(adding)
  end
end

def del_server(group)
  if group == "stb_group" then
    $stb_group.each do |deleting|
      db_count_deleting = db_search_count(deleting)
        count_deleting = db_count_deleting
      if count_deleting.to_i >= 4 then
        puts "deleting server at #{deleting}, count_deleting : #{count_deleting}"
        shortname = make_shortname(deleting)
        openstack_delete_node(shortname+"web"+count_deleting.to_s)
        chef_delete_node(shortname+"web"+count_deleting.to_s)
        delete_table_lbmembers(shortname+"web"+count_deleting.to_s)
        update_dec_counter(deleting)
      end
    end
  elsif group === "group_all" then
    $group_all.each do |deleting|
      db_count_deleting = db_search_count(deleting)
      count_deleting = db_count_deleting - 1
      if count_deleting.to_i >= 4 then
        puts "deleting server at #{deleting}, count_deleting : #{count_deleting}"
        shortname = make_shortname(deleting)
        openstack_delete_node(shortname+"web"+count_deleting.to_s)
        chef_delete_node(shortname+"web"+count_deleting.to_s)
        delete_table_lbmembers(shortname+"web"+count_deleting.to_s)
        update_dec_counter(deleting)
      end
    end
  end
end

class SclmanDaemon < DaemonSpawn::Base
  def start(args)
    puts "start : #{Time.now}"
    trig_add = 0; counter_add = 0; trig_del = 0; counter_del = 0
    loop do
      process_sclman_cli = `ps axu | grep sclman-cli.rb | grep -v grep`
      if process_sclman_cli != "" then
        puts "sclman-cli.rb is running. please wait a moment."
        sleep(3)
        redo
      end
      db_all_group = db_search_group_all()
      $all_group = db_all_group.uniq
      puts "all of groups : #{$all_group}"

      warning_instances = sensu_get_instance_load()
      groups = []
      $wng_group = []
      $stb_group = []
      if warning_instances != [] then
        warning_instances.each do |servers|
          db_group = db_search_group(servers)
          groups << db_group
        end
        $wng_group = groups.uniq
        puts "warning groups : #{$wng_group[0]}"
        stb_group = $all_group - $wng_group[0]
        puts "stability groups : #{$stb_group}"
      end

      # if warning_instances are exist, it will add a server
      if $all_group != [] and warning_instances != [] then
        if trig_add == 1 then
          counter_add += 1
          puts "counter_add : #{counter_add}"
        else
          counter_add = 0
        end
        if counter_add >= 10 then
          add_server()
          counter_add = 0; trig_add = 0; trig_del = 0
        else
          trig_add = 1; trig_del = 0
        end
      # if stability group is exist, it will be delete a server
      elsif $all_group != [] and $stb_group != [] then
        if trig_del == 1 then
          counter_del += 1
          puts "counter_del : #{counter_del}"
        else
          counter_del = 0
        end
        if counter_del >= 10 then
          del_server("stb_group")
          counter_del = 0; trig_add = 0; trig_del = 0
        else
          trig_add = 0; trig_del = 1
        end
      # if warning instances are not exist and all groups is exist,
      # it will delete a server : stb_group will be exist when only one
      # environment is exist.
      elsif $all_group != [] and warning_instances == [] then
        if trig_del == 1 then
          counter_del += 1
          puts "counter_del : #{counter_del}"
        else
          counter_del = 0
        end
        if counter_del >= 10 then
          del_server("all_group")
          counter_del = 0; trig_add = 0; trig_del = 0
        else
          trig_add = 0; trig_del = 1
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
