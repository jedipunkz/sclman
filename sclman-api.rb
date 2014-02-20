#!/usr/bin/env ruby

require 'active_record'
require 'mysql2'
require 'sinatra'
require './lib/openstack.rb'
require './lib/db.rb'
require './lib/chef.rb'
require './lib/ssh.rb'
require 'inifile'

IMAGES = {
  'precise' => {'imageid' => 'cdbed601-3671-4a15-b013-e6ef03e2a35f'},
  'saucy'   => {'imageid' => '27560521-9612-4882-9551-c04b742d87da'}
}
FLAVORS = {
  'm1.small'  => {'flavorid' => '2'},
  'm1.medium' => {'flavorid' => '3'},
  'm1.large'  => {'flavorid' => '4'},
  'm1.xlarge' => {'flavorid' => '5'}
}
SSHKEYS = {
  'sclman_key' => {'keyname' => 'sclman_key'}
}

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

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection('development')

class Counters < ActiveRecord::Base
end

get '/counters.json' do
  content_type :json, :charset => 'utf-8'
  counters = Counters.order("created_date DESC")
  counters.to_json(:root => false)
end

class Lbmembers < ActiveRecord::Base
end

get '/lbmembers.json' do
  content_type :json, :charset => 'utf-8'
  lbmembers = Lbmembers.order("created_date DESC")
  lbmembers.to_json(:root => false)
end

get '/' do
  @lbmembers = Lbmembers.find(:all)
  @counters = Counters.find(:all)
  @images = IMAGES
  @flavors = FLAVORS
  @sshkeys = SSHKEYS
  erb :index
end

post '/removegroup/:groupname' do |g|
  return 'Error' unless params[:groupname]
  remove_group params[:groupname]
  redirect '/'
end

get '/bootstrap' do
  image = request['image']
  flavor = request['flavor']
  key = request['sshkey']
  instancename = request['instancename']
  groupname = request['groupname']
  count = request['count']
  Thread.new do
    bootstrap(flavor, image, key, instancename, groupname, count)
  end
  redirect '/'
end

def remove_group(groupname)
  instancename = db_search_instance(groupname)
  instancename.each do |server|
    delete_table_lbmembers(server)
    delete_table_counters(groupname)
    chef_delete_node(server)
    openstack_delete_node(server)
    sleep(3)
  end
end

def bootstrap(flavor, image, key, instancename, groupname, count)
  num = 0 # -> number of instance
  role_trig = 0 # -> web or lb ? : role triger
  while num < count.to_i do
    if role_trig == 0 then
      openstack_create_node(flavor, image, key, instancename+"lb"+num.to_s)
      ipaddr = openstack_search_ip(instancename)
      
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
  
      Thread.new do
        chef_create_node(instancename+"lb"+num.to_s, ipaddr, groupname, "lb")
      end
      date = Time.now.strftime("%Y-%m-%d-%H:%M:%S")
      insert_table_lbmembers(instancename+"lb"+num.to_s, ipaddr, groupname, date, date)
      role_trig = 1
    else
      openstack_create_node(flavor, image, key, instancename+"web"+num.to_s)
      ipaddr = openstack_search_ip(instancename)
      sleep(40)
      Thread.new do
        chef_create_node(instancename+"web"+num.to_s, ipaddr, groupname, "web")
      end
      insert_table_lbmembers(instancename+"web"+num.to_s, ipaddr, groupname, date, date)
    end
    num += 1
  end
  insert_table_counters(groupname, count, count, date, date)
end
