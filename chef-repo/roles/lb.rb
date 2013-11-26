name "lb"
description "Base role applied to all nodes."
run_list(
  "recipe[apt]",
  "recipe[chef-client::service]",
  "recipe[nginx.lb]"
)
