#!/usr/bin/env ruby

require './lib/db.rb'
require "inifile"

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
dbname = ini.search("DB", "dbname")
dbuser = ini.search("DB", "dbuser")
dbpass = ini.search("DB", "dbpass") 

puts "input mysql root password twice."

system("mysql -u root -p -e \"CREATE DATABASE #{dbname};\"")
system("mysql -u root -p -e \"GRANT ALL ON #{dbname}.* TO #{dbuser}@localhost IDENTIFIED BY \'#{dbpass}\';\"")

create_table("lbmembers")
create_table("counter")
