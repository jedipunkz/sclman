sclman
====

Introduce
----

sclman is auto scale manager on OpenStack. sclman uses chef, sensu, mysql, so
it enable us to make easy to migrate AWS, RackSpace or each Cloud Platform.

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
    |
    +----+----+---+
    | vm | vm |.. |
    +-------------+ +-------------+ +-------------+ +-------------+
    |  openstack  | | chef server | | sensu server| | workstation |
    +-------------+ +-------------+ +-------------+ +-------------+
    |               |               |               |
    +---------------+---------------+---------------+--------------- management network

* you can use nova-network or neutron
* you have to run 'sclman' on workstation node

Usage
----

Download sclman.

    % git clone git@gitlab.kddiweb.jp:thirai/sclman.git
    % cd sclman

Install gems.

    % gem install bundler
    % bundle install

Downlooad cookbooks

    % cd chef-repo
    % # setup your .chef, *.pem files, knife.rb
    % berks install --path=./cookbooks

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

    +--------------------------------------+---------+--------+----------------------+
    | ID                                   | Name    | Status | Networks             |
    +--------------------------------------+---------+--------+----------------------+
    | e5f213cb-4e08-4711-af85-51929eb67002 | foolb0  | ACTIVE | int_net=172.24.17.11 |
    | 4732dcd8-3e72-4197-b7fd-6c8f2095fea4 | fooweb1 | ACTIVE | int_net=172.24.17.12 |
    | 98323ae6-b6e3-40e5-b28b-63f6f45546c9 | fooweb2 | ACTIVE | int_net=172.24.17.1  |
    +--------------------------------------+---------+--------+----------------------+

Access to LB server via your browser.

ex.) http://172.24.17.11

Make load the web instances
----

If you make the instances load, sclman will scale web instances and auto connect to the
Load Balance instance.
