#!/usr/bin/env ruby

require "dbi"
require "inifile"
require 'rubygems'
require "chef"
require "chef/knife/core/bootstrap_context"
require 'chef/knife'
require 'chef/knife/ssh'
require 'net/ssh'
require 'net/ssh/multi'
require 'chef/knife/bootstrap'
require 'chef/knife/node_delete'
require 'chef/knife/client_delete'
require 'chef/knife/node_list'
require 'chef/knife/node_show'
require 'chef/knife/environment_delete'
require 'chef/knife/environment_list'

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
$chef_user = ini.search("CHEF", "chef_user")
$chef_secret_key = ini.search("CHEF", "chef_secret_key")
$chef_validation_key = ini.search("CHEF", "chef_validation_key")
$chef_server_url = ini.search("CHEF", "chef_server_url")
$chef_bootstrap_file = ini.search("CHEF", "chef_bootstrap_file")
$openstack_secret_key = ini.search("OPENSTACK", "openstack_secrete_key")

Chef::Config.from_file(File.expand_path('./.chef/knife.rb'))

def chef_check_env(envname)
  i = 0
  environment = Chef::Environment::list.each do |env, url|
    if env == envname then i = 1 end
  end
  if i == 0 then
    return nil
  else
    return envname
  end
end

def chef_search_env(instancename)
  s = `knife node show #{instancename}`.split("\n")
  ss = s[1].split(" ")
  return ss[1]
end

def chef_create_env(envname)
  Chef::Config[:node_name] = $chef_user
  Chef::Config[:client_key] = $chef_secret_key
  Chef::Config[:chef_server_url] = $chef_server_url

  json_data = {
"name" => "#{envname}",
"description" => "Dummy environment for sclman",
"cookbook_versions" => {},
"default_attributes" => {},
"override_attributes" => {}
}

  @env_item = Chef::Environment.json_create(json_data)
  @env_item.save
end

def chef_delete_env(envname)
  Chef::Config[:node_name] = $chef_user
  Chef::Config[:client_key] = $chef_secret_key
  Chef::Config[:chef_server_url] = $chef_server_url

  @env_item = Chef::Knife::EnvironmentDelete.new
  @env_item.name_args = [ envname ]
  @env_item.config[:yes] = true
  @env_item.run
end

def chef_create_node(instancename, ipaddr, envname, role)
  Chef::Config[:node_name] = $chef_user
  Chef::Config[:client_key] = $chef_secret_key
  Chef::Config[:validation_key] = $chef_validation_key
  Chef::Config[:chef_server_url] = $chef_server_url
  Chef::Config[:environment] = envname

  kb = Chef::Knife::Bootstrap.new
  kb.name_args = [ipaddr]
  kb.config[:ssh_user] = "root"
  kb.config[:chef_node_name] = instancename
  kb.config[:identity_file] = $openstack_secret_key
  kb.config[:ssh_port] = "22"
  if role == "lb" then
    kb.config[:run_list ] = "role[base]", "role[lb]"
  elsif role == "web" then
    kb.config[:run_list ] = "role[base]", "role[web]"
  else
    puts "error was occoured with role selection"
  end
  kb.config[:template_file] = $chef_bootstrap_file
  kb.config[:use_sudo] = true
  kb.run 
end

def chef_delete_node(instancename)
  nd = Chef::Knife::NodeDelete.new
  nd.name_args = [ instancename ]
  nd.config[:yes] = true
  nd.run

  cd = Chef::Knife::ClientDelete.new
  cd.name_args = [ instancename ]
  cd.config[:yes] = true
  cd.run
end

