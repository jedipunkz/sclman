#!/usr/bin/env ruby

require 'dbi'
require 'inifile'
require 'fog'

class IniLoad
  def initialize
    @ini = IniFile.load("/home/thirai/sclman/sclman.conf")
  end

  def search( section, name )
    val = @ini[section][name]
    return "#{val}"
  end
end

module OpenStackCompute
  def self.connect()
    ini = IniLoad.new
    $openstack_username = ini.search("OPENSTACK", "openstack_username")
    $openstack_api_key = ini.search("OPENSTACK", "openstack_api_key")
    $openstack_auth_url = ini.search("OPENSTACK", "openstack_auth_url")
    $openstack_tenant = ini.search("OPENSTACK", "openstack_tenant")
    $openstack_net_id = ini.search("OPENSTACK", "openstack_net_id")
    conn = Fog::Compute.new({
      :provider => 'OpenStack',
      :openstack_api_key => $openstack_api_key,
      :openstack_username => $openstack_username,
      :openstack_auth_url => $openstack_auth_url,
      :openstack_tenant => $openstack_tenant
    })
    begin
      result = yield conn
    ensure
      # conn.close
    end
  rescue  Errno::ECONNREFUSED
  end
end

def openstack_create_node(flavorname, imagename, keyname, instancename)
  OpenStackCompute.connect() do |sock|
    # flavor = sock.flavors.find { |f| f.name = flavorname }
    image = sock.images.find { |i| i.name = imagename }
    server = sock.servers.create :name => instancename,
                                 :image_ref => image.id,
                                 :flavor_ref => flavorname.to_i,
                                 :key_name => keyname,
                                 :nics => ["net_id" => $openstack_net_id]
    server.wait_for { ready? }
    puts server
  end
end

def openstack_delete_node(instancename)
  OpenStackCompute.connect() do |sock|
    instance = sock.servers.find { |i| i.name = instancename }
    server = sock.delete_server(instance.id)
    p server
    p instance
    p instance.id
  end
end

def openstack_search_ip(instancename)
  OpenStackCompute.connect() do |sock|
    instance = sock.servers.find { |i| i.name = instancename }
    p instance
    instance.addresses.each do |k, v|
      v.each do |x, y|
        x.each do |z, w|
          if z == "addr" then return w end
        end
      end
    end
  end
end

def openstack_check_flavor(flavorname)
  OpenStackCompute.connect() do |sock|
    flavor = sock.flavors.find { |f| f.name == flavorname }
    if flavor.nil?
      puts "error was occoured. that flavor is not exist."
    end
  end
end


def openstack_check_image(imagename)
  OpenStackCompute.connect() do |sock|
    image = sock.images.find { |i| i.name == imagename }
    if image.nil?
      puts "error was occoured. that image is not exist."
    end
  end
end
