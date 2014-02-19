#!/usr/bin/env ruby

require 'active_record'
require 'mysql2'
require 'sinatra'
require './lib/openstack.rb'
require './lib/db.rb'
require './lib/chef.rb'

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
