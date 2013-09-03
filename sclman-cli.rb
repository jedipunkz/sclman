#!/usr/bin/env ruby
# scaleman bootstrap command line tool
# usage : ruby bootstrap_cli.rb bootstrap flavor image key environment instancename
#       : ruby bootstrap_cli.rb delete environment

require "./lib/chef.rb"
require "./lib/openstack.rb"
require "./lib/db.rb"

method      = ARGV[0]
flavor      = ARGV[1]
image       = ARGV[2]
key         = ARGV[3]
environment = ARGV[4]
instance    = ARGV[5]

usage = <<"EOB"
Usage: ruby sclman.rb bootstrap flavor image key environment instancename
        flavor : OpenStack flavor name
        image  : OpenStack image name
        key    : OpenStack secret key name
        environment : Chef environment name
        instancename : instancename (auto adding numeric number)
or
Usage: ruby sclman.rb delete environment
EOB

if method == "bootstrap" then
  # synatx checks
  method      = ARGV[0]
  flavor      = ARGV[1]
  image       = ARGV[2]
  key         = ARGV[3]
  environment = ARGV[4]
  instance    = ARGV[5]
  if ARGV.size != 6 then
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
  while num < 3 do
    puts "instance is booting... : #{instance}#{num}"
    if role_trig == 0 then
      openstack_create_node(flavor, image, key, instance+"lb"+num.to_s)
      ipaddr = openstack_search_ip(instance)
      sleep(20)
      chef_create_node(instance+"lb"+num.to_s, ipaddr, environment, "lb")
      role_trig = 1
    else
      openstack_create_node(flavor, image, key, instance+"web"+num.to_s)
      ipaddr = openstack_search_ip(instance)
      sleep(20)
      chef_create_node(instance+"web"+num.to_s, ipaddr, environment, "web")
    end
    insert_table_lbmembers(instance+num.to_s, ipaddr, environment)
    num += 1
  end

elsif method == "delete" then
  method      = ARGV[0]
  environment = ARGV[1]
  if ARGV.size != 2 then
    puts "error. number of arguments is illegal."
    puts usage
    exit
  end
  instancename = select_groupname(environment)
  puts instancename
else
  puts usage
end

