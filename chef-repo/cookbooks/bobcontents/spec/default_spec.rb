require 'chefspec'

describe 'bobcontents::default' do
  let (:chef_run) { ChefSpec::ChefRunner.new.converge 'bobcontents::default' }

  it 'should create httpd root directory' do
    dir = chef_run.node['bobcontents']['root_dir']
    chef_run.should create_directory dir
    chef_run.directory(dir).should be_owned_by('www-data', 'root')
    chef_run.directory(dir).mode.should == '0755'
  end

  it 'create index.html' do
    file = ::File.join(chef_run.node['bobcontents']['root_dir'], chef_run.node['bobcontents']['index.html'])
    chef_run.should create_cookbook_file file
    chef_run.cookbook_file(file).should be_owned_by('www-data', 'root')
    chef_run.cookbook_file(file).mode.should == '0644'
  end

  it 'create css1' do
    file = ::File.join(chef_run.node['bobcontents']['root_dir'], chef_run.node['bobcontents']['css1'])
    chef_run.should create_cookbook_file file
    chef_run.cookbook_file(file).should be_owned_by('www-data', 'root')
    chef_run.cookbook_file(file).mode.should == '0644'
  end

  it 'create css2' do
    file = ::File.join(chef_run.node['bobcontents']['root_dir'], chef_run.node['bobcontents']['css2'])
    chef_run.should create_cookbook_file file
    chef_run.cookbook_file(file).should be_owned_by('www-data', 'root')
    chef_run.cookbook_file(file).mode.should == '0644'
  end

end
