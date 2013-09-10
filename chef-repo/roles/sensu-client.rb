name "sensu-client"
description "role applied to sensu client."
run_list "recipe[monitor]",
  "recipe[chef-client::service]"
#  "recipe[mine]",
#  "recipe[users::sysadmins]"
