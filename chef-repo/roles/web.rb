name "web"
description "Base role applied to all nodes."
run_list(
  "recipe[apt]",
  "recipe[nginx]",
  "recipe[nginx::commons_conf]",
  "recipe[bobcontents]",
  "recipe[chef-client::upstart_service]"
)
