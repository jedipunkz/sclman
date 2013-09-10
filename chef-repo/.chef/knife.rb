log_level                :info
log_location             STDOUT
node_name                'thirai'
client_key               "#{Dir.pwd}/.chef/thirai.pem"
validation_client_name   'chef-validator'
validation_key           "#{Dir.pwd}/.chef/chef-validator.pem"
chef_server_url          'https://10.200.10.96'
syntax_check_cache_path  "#{Dir.pwd}/.chef/syntax_check_cache"
