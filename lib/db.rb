#!/usr/bin/env ruby

require "rubygems"
require "inifile"
require "active_record"

class IniLoad
  def initialize
    @ini = IniFile.load("./sclman.conf")
  end

  def search( section, name )
    val = @ini[section][name]
    return "#{val}"
  end
end

ActiveRecord::Base.establish_connection(
  adapter:  "mysql2",
  host:     "localhost",
  username: "sclmanuser",
  password: "sclmanpass",
  database: "sclman",
)

class Lbmembers < ActiveRecord::Base
  self.table_name = 'lbmembers'
end

class Counter < ActiveRecord::Base
  self.table_name = 'counter'
end

def insert_table_lbmembers(instancename, ipaddr, groupname, created_date, updated_date)
  instance = Lbmembers.new
  instance.instancename = instancename
  instance.ipaddr = ipaddr
  instance.groupname = groupname
  instance.created_date = created_date
  instance.updated_date = updated_date
  instance.save
end

def delete_table_lbmembers(instancename)
  Lbmembers.destroy_all(:instancename => instancename)
end

def insert_table_counter(groupname, count, basic_count, created_date, updated_date)
  counter = Counter.new
  counter.groupname = groupname
  counter.count = count
  counter.basic_count = basic_count
  counter.created_date = created_date
  counter.updated_date = updated_date
  counter.save
end

def delete_table_counter(groupname)
  Counter.destroy_all(:groupname => groupname)
end

def update_inc_counter(groupname, date)
  counter = Counter.where(groupname: groupname).first
  counter.increment!(:count)
  counter.updated_date = date
  counter.save
end

def update_dec_counter(groupname, date)
  counter = Counter.where(groupname: groupname).first
  counter.decrement!(:count)
  counter.updated_date = date
  counter.save
end

def db_search_instance(groupname)
  instances = []
  records = Lbmembers.where(groupname: groupname)
  records.each do |val|
    instancename = val.instancename
    instances << instancename
  end
  return instances
end

def db_search_ipaddr(instancename)
  records = Lbmembers.where(instancename: instancename)
  records.each do |val|
    return val.ipaddr
  end
end

def db_search_group(instancename)
  groups = []
  records = Lbmembers.where(instancename: instancename)
  records.each do |val|
    groupname = val.groupname
    groups << groupname
  end
  return groups
end

def db_search_group_all()
  groups = []
  records = Lbmembers.all
  records.each do |val|
    groupname = val.groupname
    groups << groupname
  end
  return groups
end

def db_search_instance_all()
  instances = []
  records = Lbmembers.all
  records.each do |val|
    instancename = val.instancename
    instances << instancename
  end
  return instances
end

def db_search_count(groupname)
  records = Counter.where(groupname: groupname)
  records.each do |val|
    return val.count
  end
end

def db_search_basic_count(groupname)
  records = Counter.where(groupname: groupname)
  records.each do |val|
    return val.basic_count
  end
end

def db_search_lbmembers()
  records = Lbmembers.all
  records.each do |val|
    printf "id: %s, instancename: %s, ip: %s, groupname: %s, created: %s, updated: %s\n",
      val.id, val.instancename, val.ipaddr, val.groupname, val.created_date, val.updated_date
  end
end
