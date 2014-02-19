name "lb"
description "Base role applied to all nodes."
run_list(
  "recipe[apt]",
  "recipe[nginx.lb]",
  "recipe[chef-client::upstart_service]",
)
