#!/usr/bin/env ruby
# scaleman bootstrap command line tool
# usage : ruby bootstrap_cli.rb bootstrap flavor image key environment instancename
#       : ruby bootstrap_cli.rb delete environment

require 'inifile'
require './lib/chef.rb'
require './lib/openstack.rb'
require './lib/db.rb'
require './lib/ssh.rb'

method      = ARGV[0]
flavor      = ARGV[1]
image       = ARGV[2]
key         = ARGV[3]
environment = ARGV[4]
instance    = ARGV[5]
count       = ARGV[6]

usage = <<"EOB"
Usage: ruby sclman-cli.rb bootstrap flavor image key environment instancename
        flavor : OpenStack flavor name
        image  : OpenStack image name
        key    : OpenStack secret key name
        environment : Chef environment name
        instancename : instancename (auto adding numeric number)
  or
        ruby sclman-cli.rb delete environment
  or
        ruby sclman-cli.rb list
EOB

class IniLoad
  def initialize
    @ini = IniFile.load("./sclman.conf")
  end

  def search( section, name )
    val = @ini[section][name]
    return "#{val}"
  end
end

ini = IniLoad.new
$openstack_secret_key = ini.search("OPENSTACK", "openstack_secrete_key")

if method == "bootstrap" then
  # synatx checks
  method      = ARGV[0]
  flavor      = ARGV[1]
  image       = ARGV[2]
  key         = ARGV[3]
  environment = ARGV[4]
  instance    = ARGV[5]
  count       = ARGV[6]
  if ARGV.size != 7 then
    puts "error. number of arguments is illegal."
    puts usage
    exit
  end
  # check each resources
  openstack_check_flavor(flavor)
  openstack_check_image(image)
  check_env = chef_check_env(environment)
  if check_env == nil
    chef_create_env(environment)
  else
    puts "environment is exist. It will be used."
  end
  
  num = 0
  role_trig = 0
  while num < count.to_i do
    if role_trig == 0 then
      puts "instance is booting... : #{instance}lb#{num}"
      openstack_create_node(flavor, image, key, instance+"lb"+num.to_s)
      ipaddr = openstack_search_ip(instance)

      loop do
        result = check_ssh(ipaddr, 'ubuntu', $openstack_secret_key)
        puts "ipaddr: #{ipaddr}, key: #{$openstack_secret_key}"
        if result != 'ok' then
          puts 'waiting ssh session from instance.....'
          sleep(5)
          redo
        else
          puts 'I found ssh session. now bootstraping the chef.....'
          sleep(8)
          break
        end
      end

      fork do
        chef_create_node(instance+"lb"+num.to_s, ipaddr, environment, "lb")
      end
      # insert_table_lbmembers(instance+"lb"+num.to_s, ipaddr, environment)
      date = Time.now.strftime("%Y-%m-%d-%H:%M:%S")
      insert_table_lbmembers(instance+"lb"+num.to_s, ipaddr, environment, date, date)
      role_trig = 1
    else
      puts "instance is booting... : #{instance}web#{num}"
      openstack_create_node(flavor, image, key, instance+"web"+num.to_s)
      ipaddr = openstack_search_ip(instance)
      sleep(40)
      fork do
        chef_create_node(instance+"web"+num.to_s, ipaddr, environment, "web")
      end
      # insert_table_lbmembers(instance+"web"+num.to_s, ipaddr, environment)
      insert_table_lbmembers(instance+"web"+num.to_s, ipaddr, environment, date, date)
    end
    num += 1
  end
  insert_table_counter(environment, count, count, date, date)

elsif method == "delete" then
  method      = ARGV[0]
  environment = ARGV[1]
  if ARGV.size != 2 then
    puts "error. number of arguments is illegal."
    puts usage
    exit
  end
  instancename = db_search_instance(environment)
  instancename.each do |server|
    puts "Deleting Node : #{server} ..."
    delete_table_lbmembers(server)
    delete_table_counter(environment)
    chef_delete_node(server)
    openstack_delete_node(server)
    sleep(3)
  end
  # debug
  p instancename
elsif method == "list" then
  method = ARGV[0]
  if ARGV.size != 1 then
    puts "error. number of arguments is illegal."
    puts usage
    exit
  end
  db_search_lbmembers
else
  puts usage
end
