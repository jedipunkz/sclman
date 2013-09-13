sclman
====

Introduce
----

sclman is auto scale manager on OpenStack. sclman uses chef, sensu, mysql, so
it enable us to make easy to migrate AWS, RackSpace or each Cloud
Platform. sclman-cli.rb is command line tool for bootstraping or deleting
servers with chef and OpenStack. sclman.rb is manager which monitoring load of
each servers. if any servers in HA cluster will be getting a load, sclman
manager will put some servers to that HA cluster. then if load will be getting
down, sclman manager will delete some servers in that HA cluster.

git
----

<git@gitlab.kddiweb.jp:thirai/sclman.git>

Author
----

* name : Tomokazu HIRAI
* id : @jedipunkz

License
----

Apache License.

Required Architecture
----

    +-------------- public network
    |                                               +-------------+
    +----+----+---+                                 |  sclman.rb  |
    | vm | vm |.. |                                 |sclman-cli.rb|
    +-------------+ +-------------+ +-------------+ +-------------+
    |  openstack  | | chef server | | sensu server| | workstation |
    +-------------+ +-------------+ +-------------+ +-------------+
    |               |               |               |
    +---------------+---------------+---------------+--------------- management network

* you can use nova-network or neutron
* you have to run 'sclman' on workstation node
* it does not mind which 'all in one' arch or 'separated' arch on OpenStack

Usage
----

Download sclman via git.

    % git clone git@gitlab.kddiweb.jp:thirai/sclman.git
    % cd sclman

Install gems.

    % gem install bundler
    % bundle install

Downlooad cookbooks

    % cd chef-repo
    % # setup your .chef, *.pem files, knife.rb
    % berks install --path=./cookbooks

Deploy Sensu
----

edit sensu server's ip addr.

    % ${EDITOR} cookbooks/monitor/attributes/default.rb
    default["monitor"]["master_address"] = "XXX.XXX.XXX.XXX"

Upload these to your chef server.
 
    % knife cookbook upload -o cookbooks -a
    % knife role from file role/*.rb

Generate ssl key for sensu server and clients.

    % cd data_bags/ssl
    % ./ssl_certs.sh generate
    % knife data bag create sensu
    % knife data bag from file sensu ./ssl.json

Make 'sensu_checks' data bag for each monitoring items.

    % cd ../../
    % knife data bag create sensu_checks
    % knife data bag from file sensu_checks data_bags/sensu_checks/*.json

Deploy sensu-server.

    % knife bootstrap <sensu_server_ip> -N <sensu_server_name> -r \
      'role[sensu-server]' -x root -i <secret_key>

#### Deploy chef server

You can use chef omnibus package to deploy chef-server. download it at this
URL.

<http://www.opscode.com/chef/install/>

#### Deploy OpenStack

You can use github.com/rcbops/chef-cookbooks to deploy OpenStack.

<https://github.com/rcbops/chef-cookbooks>

setup sclman.conf
----

setup sclman.conf for each service and self parameters such as openstack
endpoint information, username, mysql username, password ....

    [DB]
    dbname = sclman
    dbuser = sclmanuser
    dbpass = sclmanpass
    [CHEF]
    chef_user = thirai
    chef_secret_key = /home/thirai/sclman/chef-repo/.chef/thirai.pem
    chef_validation_key = /home/thirai/sclman/chef-repo/.chef/chef-validator.pem
    chef_server_url = "https://10.200.10.96"
    #chef_bootstrap_file = /home/thirai/chef-full.erb
    chef_bootstrap_file =
    /home/thirai/sclman/chef-repo/.chef/bootstrap/chef-full.erb
    [OPENSTACK]
    openstack_secrete_key = /home/thirai/novakey01
    openstack_username = demo
    openstack_api_key = demo
    openstack_auth_url = "http://10.200.9.46:5000/v2.0/tokens"
    openstack_tenant = service
    openstack_net_id = "2431d382-1566-4780-b2ba-8571b4efcbec"
    [SENSU]
    sensu_url = "http://10.200.10.95:4567"
    [MANAGER]
    man_flavor = "m1.tiny"
    man_image = "precise-kwc"
    man_key = "novakey01"
    man_sensitivity = 10
    man_pid = /tmp/sclman.pid
    man_log = /tmp/sclman.log

Boot sclman.rb daemon
----

sclman.rb will boot daemon mode on linux. boot up 'sclman.rb' manager.

    % ruby sclman.rb start

Bootstrap minimum HTTP HA cluster
----

bootstrap with sclman-cli.rb.

    % ruby sclman-cli.rb bootstrap m1.tiny precise-kwc novakey01 <group_name> <server_name>
      
You can find these instances on OpenStack.

ex.) server_name : foo

    +--------------------------------------+---------+--------+---------------------+
    | ID                                   | Name    | Status | Networks            |
    +--------------------------------------+---------+--------+---------------------+
    | 36b15ce8-c7fa-4236-b6cd-b65e83f05cbf | foolb0  | ACTIVE | int_net=172.24.17.1 |
    | 2230788a-bb34-4cc4-8123-b2f32feaeec9 | fooweb1 | ACTIVE | int_net=172.24.17.4 |
    | 7dfd21b4-f76e-46d2-b7dc-f2d4278339d5 | fooweb2 | ACTIVE | int_net=172.24.17.3 |
    +--------------------------------------+---------+--------+---------------------+

Access to LB server via your browser.

ex.) http://172.24.17.11

Put a load to the web instances
----

If you make the instances load, sclman will scale web instances and auto connect to the
Load Balance instance.

    +--------------------------------------+---------+--------+---------------------+
    | ID                                   | Name    | Status | Networks            |
    +--------------------------------------+---------+--------+---------------------+
    | 36b15ce8-c7fa-4236-b6cd-b65e83f05cbf | foolb0  | ACTIVE | int_net=172.24.17.1 |
    | 2230788a-bb34-4cc4-8123-b2f32feaeec9 | fooweb1 | ACTIVE | int_net=172.24.17.4 |
    | 7dfd21b4-f76e-46d2-b7dc-f2d4278339d5 | fooweb2 | ACTIVE | int_net=172.24.17.3 |
    | 50554ea0-adcf-4459-a3c5-3b448b2395d6 | fooweb3 | ACTIVE | int_net=172.24.17.5 |
    +--------------------------------------+---------+--------+---------------------+

Sensitivity
----

'man_sensitivity' parameter in sclman.conf is used by sclman.rb manager and used as gain sensitivity.
If load increase continuously on web instance, sclman.rb add a server. sensitivity is continuously counter.
