#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'inifile'
require './lib/db.rb'

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
$sensu_url = ini.search("SENSU", "sensu_url")

def sensu_get_instance_load()
  instances = []
  instancename = db_search_instance_all()
  instancename.each do |server|
    url_checks = URI.parse("#{$sensu_url}")
    res_checks = Net::HTTP.start(url_checks.host, url_checks.port) {|http|
      http.get("/events/#{server}/load")
    }
    if res_checks.body != "" then
      result = JSON.parse(res_checks.body)
      result.each do |k, v|
        if k == "client" then client = v; instances << client end
      end
    end
  end
  return instances
end
