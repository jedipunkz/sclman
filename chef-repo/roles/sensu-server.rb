name "sensu-server"
description "role applied to sensu server."
run_list "recipe[monitor::master]",
  "recipe[chef-client::service]"
