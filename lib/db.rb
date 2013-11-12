#!/usr/bin/env ruby

require "dbi"
require "inifile"

class IniLoad
  def initialize
    # @ini = IniFile.load("./sclman.conf")
    @ini = IniFile.load("/home/thirai/sclman/sclman.conf")
  end

  def search( section, name )
    val = @ini[section][name]
    return "#{val}"
  end
end

module ConnectDb
  def self.connect()
    ini = IniLoad.new
    dbname = ini.search("DB", "dbname")
    dbuser = ini.search("DB", "dbuser")
    dbpass = ini.search("DB", "dbpass")
    dbconn = DBI.connect("DBI:Mysql:#{dbname}:localhost", "#{dbuser}", "#{dbpass}")
    begin
      result = yield dbconn
    rescue DBI::DatabaseErro => e
      puts "An error occurred"
      puts "Error code: #{e.err}"
      puts "Error message: #{e.errstr}"
    ensure
      dbconn.disconnect if dbconn
    end
  rescue Errno::ECONNREFUSED
  end
end

def create_table(tablename)
  if tablename == "lbmembers" then
    ConnectDb.connect() do |sock|
      sock.do("CREATE TABLE #{tablename} (
                  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                  instancename CHAR(20) NOT NULL,
                  ipaddr CHAR(20) NOT NULL,
                  groupname CHAR(20) NOT NULL,
                  PRIMARY KEY (id))")
    end
  elsif tablename == "counter" then
    ConnectDb.connect() do |sock|
      sock.do("CREATE TABLE #{tablename} (
                  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                  groupname CHAR(20) NOT NULL,
                  count INT NOT NULL,
                  basic_count INT NOT NULL,
                  PRIMARY KEY (id))")
    end
  else
    puts "error was occoured. table name should be 'lbmembers' or 'counter'."
  end
end

def insert_table_lbmembers(instancename, ipaddr, groupname)
  ConnectDb.connect() do |sock|
    sock.do("INSERT INTO lbmembers (id, instancename, ipaddr, groupname) VALUE(?, ?, ?, ?)",
             nil, "#{instancename}", "#{ipaddr}", "#{groupname}")
  end
end

def delete_table_lbmembers(instancename)
  ConnectDb.connect() do |sock|
    sock.do("DELETE FROM lbmembers WHERE instancename = ?", instancename)
  end
end

def insert_table_counter(groupname, count, basic_count)
  ConnectDb.connect() do |sock|
    sock.do("INSERT INTO counter (id, groupname, count, basic_count) VALUE(?, ?, ?, ?)",
                nil, "#{groupname}", "#{count}", "#{basic_count}")
  end
end

def delete_table_counter(groupname)
  ConnectDb.connect() do |sock|
    sock.do("DELETE FROM counter WHERE groupname = ?", groupname)
  end
end

def update_inc_counter(groupname)
  ConnectDb.connect() do |sock|
    sth = sock.execute("UPDATE counter SET count = count + 1 WHERE groupname = ?", "#{groupname}")
  end
end

def update_dec_counter(groupname)
  ConnectDb.connect() do |sock|
    sth = sock.execute("UPDATE counter SET count = count - 1 WHERE groupname = ?", "#{groupname}")
  end
end

def show_table(tablename)
  if tablename == "lbmembers" then
    ConnectDb.connect() do | sock |
      table_hash = []
      sth = sock.execute("SELECT * FROM #{tablename}")
      while row = sth.fetch_hash do
        hash = {"id" => row["id"], "instancename" => row["instancename"], "ipaddr" => row["ipaddr"], "groupname" => row["groupname"]}
        table_hash << hash
      end
      sth.finish
      return table_hash
    end
  elsif tablename == "counter" then
    ConnectDb.connect() do | sock |
      sth = sock.execute("SELECT * FROM #{tablename}")
      table_hash = []
      while row = sth.fetch_hash do
        hash = {"id" => row["id"], "groupname" => row["groupname"], "counter" => row["counter"]}
        table_hash << hash
      end
      sth.finish
      return table_hash
    end
  else
    puts "error was occoured. tablename should be 'lbmembers' or 'counter'."
  end
end

def db_search_instance(groupname)
  instances = []
  ConnectDb.connect() do | sock |
    sth = sock.execute("SELECT * FROM lbmembers WHERE groupname = ?", "#{groupname}")
    while row = sth.fetch_hash do
      instances << row["instancename"]
    end
  end
  return instances
end

def db_search_ipaddr(instancename)
  ipaddr = []
  ConnectDb.connect() do | sock |
    sth = sock.execute("SELECT * FROM lbmembers WHERE instancename = ?", "#{instancename}")
    while row = sth.fetch_hash do
      return row["ipaddr"]
    end
  end
end

def db_search_group(instancename)
  groups = []
  ConnectDb.connect() do | sock |
    sth = sock.execute("SELECT * FROM lbmembers WHERE instancename = ?", "#{instancename}")
    while row = sth.fetch_hash do
      groups << row["groupname"]
    end
  end
  groups.uniq
  return groups
end

def db_search_group_all()
  groups = []
  ConnectDb.connect() do |sock|
    sth = sock.execute("SELECT * FROM lbmembers")
    while row = sth.fetch do
      groups << row["groupname"]
    end
  end
  return groups
end

def db_search_ipaddr(instancename)
  ConnectDb.connect() do |sock|
    sth = sock.execute("SELECT * FROM lbmembers WHERE instancename = ?", "#{instancename}")
    while row = sth.fetch do
      return row["ipaddr"]
    end
  end
end

def db_search_instance_all()
  instances = []
  ConnectDb.connect() do |sock|
    sth = sock.execute("SELECT * FROM lbmembers")
    while row = sth.fetch do
      instances << row["instancename"]
    end
  end
  return instances
end

def db_search_count(groupname)
  ConnectDb.connect() do |sock|
    sth = sock.execute("SELECT * FROM counter WHERE groupname = ?", "#{groupname}")
    while row = sth.fetch do
      return row["count"]
    end
  end
end

def db_search_basic_count(groupname)
  ConnectDb.connect() do |sock|
    sth = sock.execute("SELECT * FROM counter WHERE groupname = ?", "#{groupname}")
    while row = sth.fetch do
      return row["basic_count"]
    end
  end
end
