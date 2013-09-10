#
# Cookbook Name:: bobcontents
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
directory node['bobcontents']['root_dir'] do
  owner "www-data"
  group "root"
  mode "0755"
  recursive true
end

%W{#{node['bobcontents']['index.html']} #{node['bobcontents']['css1']} #{node['bobcontents']['css2']}}.each do | content |
  cookbook_file ::File.join(node['bobcontents']['root_dir'], content) do
    source content
    owner "www-data"
    group "root"
    mode "0644"
  end
end
