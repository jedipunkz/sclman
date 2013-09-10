name "web"
description "Base role applied to all nodes."
run_list(
  "recipe[apt]",
  "recipe[chef-client::service]",
  "recipe[nginx]",
  "recipe[nginx::commons_conf]",
  "recipe[bobcontents]"
)
