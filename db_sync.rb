#!/usr/bin/env ruby

# require './lib/db.rb'
require "inifile"
require 'dbi'

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
dbname = ini.search("DB", "dbname")
dbuser = ini.search("DB", "dbuser")
dbpass = ini.search("DB", "dbpass") 

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
                  created_date CHAR(20) NOT NULL,
                  updated_date CHAR(20) NOT NULL,
                  PRIMARY KEY (id))")
    end
  elsif tablename == "counter" then
    ConnectDb.connect() do |sock|
      sock.do("CREATE TABLE #{tablename} (
                  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                  groupname CHAR(20) NOT NULL,
                  count INT NOT NULL,
                  basic_count INT NOT NULL,
                  created_date CHAR(20) NOT NULL,
                  updated_date CHAR(20) NOT NULL,
                  PRIMARY KEY (id))")
    end
  else
    puts "error was occoured. table name should be 'lbmembers' or 'counter'."
  end
end

puts "input mysql root password twice."

system("mysql -u root -p -e \"CREATE DATABASE #{dbname};\"")
system("mysql -u root -p -e \"GRANT ALL ON #{dbname}.* TO #{dbuser}@localhost IDENTIFIED BY \'#{dbpass}\';\"")

create_table("lbmembers")
create_table("counter")
