#
# Cookbook Name:: master_install
# Recipe:: master_install
#
# Copyright 2013, Scholastic
#
# All rights reserved - Do Not Redistribute
#


artifactory_db = Chef::EncryptedDataBagItem.load("services_artifactory_default", "#{node.chef_environment}")
username = artifactory_db['artifactory_username']
password = artifactory_db['artifactory_password']

user_info = Chef::EncryptedDataBagItem.load("endeca_default", "#{node.chef_environment}",)
node.override[:services][:rpm_repo][:satellite][:activation_key] = user_info['activation_key']

gem_package "ruby_expect" do
  gem_binary("/opt/chef/embedded/bin/gem")
  options("--no-ri --no-rdoc")
  action :install
end

["expect"].each do |pkg|
  package pkg do
    action :install
  end
end

# get endeca binaries
remote_file "#{Chef::Config[:file_cache_path]}/mdex_613_x86_64pc-linux.sh" do
  source "#{node['schl_endeca']['artifact_url']}/mdex_613_x86_64pc-linux.sh"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/dgraph" do
  source "#{node['schl_endeca']['artifact_url']}/Hotfix_dgraph/dgraph"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/platformservices_610_x86_64pc-linux.sh" do
  source "#{node['schl_endeca']['artifact_url']}/platformservices_610_x86_64pc-linux.sh"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/merchworkbench_210_x86_64pc-linux.sh" do
  source "#{node['schl_endeca']['artifact_url']}/merchworkbench_210_x86_64pc-linux.sh"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
  not_if { "#{node['schl_endeca']['env']}" == "PROD"}
end

remote_file "#{Chef::Config[:file_cache_path]}/AdvJDBCColumnHandler.jar" do
  source "#{node['schl_endeca']['artifact_url']}/AdvJDBCColumnHandler.jar"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/cas120il64.tar.gz" do
  source "#{node['schl_endeca']['artifact_url']}/cas120il64.tar.gz"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/deploymentTemplate-3.2.tar.gz" do
  source "#{node['schl_endeca']['artifact_url']}/deploymentTemplate-3.2.tar.gz"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/PBXApp.tar.gz" do
  source "#{node['schl_endeca']['artifact_url']}/PBXApp.tar.gz"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

directory "#{Chef::Config[:file_cache_path]}/db2_drivers" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

remote_file "#{Chef::Config[:file_cache_path]}/db2_drivers/db2jcc.jar" do
  source "#{node['schl_endeca']['artifact_url']}/db2_drivers/db2jcc.jar"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/db2_drivers/db2jcc_license_c.jar" do
  source "#{node['schl_endeca']['artifact_url']}/db2_drivers/db2jcc_license_c.jar"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

remote_file "#{Chef::Config[:file_cache_path]}/db2_drivers/db2jcc_license_cu.jar" do
  source "#{node['schl_endeca']['artifact_url']}/db2_drivers/db2jcc_license_cu.jar"
  headers ({"AUTHORIZATION" => "Basic #{Base64.encode64("#{username}:#{password}")}"})
  mode 00755
end

# create platform services silent file
template "#{Chef::Config[:file_cache_path]}/platform_services_silent" do
  source "platform_services_silent.erb"
  owner "root"
  group "root"
  mode 0644
  action :create
end

# create user endeca6
user "#{node['schl_endeca']['app_id']}" do
  home "#{node['schl_endeca']['base_dir']}"
  supports :manage_home => true
  action :create
  shell "/bin/bash"
  password user_info['user_pswd_encrpyt']
end

#Create directory for .ssh keys and new Projects ( pipeline backup ) 
["#{node['schl_endeca']['base_dir']}/new_projects", "#{node['schl_endeca']['base_dir']}/.ssh"].each do |dir|
  directory "#{node['schl_endeca']['base_dir']}/.ssh" do
    owner "#{node['schl_endeca']['app_id']}"
    group "#{node['schl_endeca']['app_id']}"
    mode 
    
    recursive true
    action :create
  end
end

template "#{node['schl_endeca']['base_dir']}/keygen.rb" do
  source "keygen.rb.erb"
  owner "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  variables(
            :fileloc => "#{node['schl_endeca']['base_dir']}/.ssh/id_rsa"
           )
  mode 0744
  not_if { File.exists? ("#{node['schl_endeca']['base_dir']}/.ssh/id_rsa") }
  action :create
end

execute "./keygen.rb" do
  cwd  "#{node['schl_endeca']['base_dir']}"
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists? ("#{node['schl_endeca']['base_dir']}/.ssh/id_rsa") }
end

#Create Source file for endeca
template "#{node['schl_endeca']['base_dir']}/#{node['schl_endeca']['alias_file_master']}" do
  source "#{node['schl_endeca']['alias_file_master']}.erb"
  owner "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  variables(
            :mdex_ver => node['schl_endeca']['mdex_version'],
            :platform_services_ver => node['schl_endeca']['platform_services_version'],
            :workbench_ver => node['schl_endeca']['workbench_version'],
            :base_dir => node['schl_endeca']['base_dir']
            )
  mode 0744
  action :create
end

# create workbench silent file
template "#{Chef::Config[:file_cache_path]}/workbench_silent" do
  source "workbench_silent.erb"
  owner "root"
  group "root"
  mode 0644
  action :create
  not_if { "#{node['schl_endeca']['env']}" == "PROD"}
end

["dos2unix", "glibc.i686"].each do |pkg|
  yum_package pkg do
    action :install
  end
end
 
execute "dos2unix #{Chef::Config[:file_cache_path]}/platform_services_silent" do
  user "root"
end

execute "dos2unix #{Chef::Config[:file_cache_path]}/workbench_silent" do
  user "root"
  not_if { "#{node['schl_endeca']['env']}" == "PROD"}
end

#Update the .bash_profile file of endeca6 user to include all the source file of App Endeca
ruby_block "Update .bash_profile of #{node['schl_endeca']['app_id']} user" do
      block do
          begin
            require 'fileutils'
            Schl_ETL.mergefile("#{node['schl_endeca']['base_dir']}/#{node['schl_endeca']['bash_file']}", "#{node['schl_endeca']['base_dir']}/#{node['schl_endeca']['alias_file_master']}")
    rescue Exception => e
  puts e.message
          end
      end
end

# install MDEX
execute "echo Y | #{Chef::Config[:file_cache_path]}/mdex_613_x86_64pc-linux.sh --silent --target #{node['schl_endeca']['base_dir']}; cp #{Chef::Config[:file_cache_path]}/dgraph #{node['schl_endeca']['base_dir']}/endeca/MDEX/6.1.3/bin/" do
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  # write an idempotency guard here
  not_if { File.exists?("#{node['schl_endeca']['mdex_directory']}") }
end

# install Platform services. Use the platform services silent file
execute "#{Chef::Config[:file_cache_path]}/platformservices_610_x86_64pc-linux.sh --silent --target #{node['schl_endeca']['base_dir']} < #{Chef::Config[:file_cache_path]}/platform_services_silent" do
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['platform_dir']}") }
end 

# install workbench. Use the workbench silent file
execute "#{Chef::Config[:file_cache_path]}/merchworkbench_210_x86_64pc-linux.sh --silent --target #{node['schl_endeca']['base_dir']} < #{Chef::Config[:file_cache_path]}/workbench_silent" do
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}" 
  not_if { File.exists?("#{node['schl_endeca']['workbench_dir']}") } 
  not_if { "#{node['schl_endeca']['env']}" == "PROD"}
end

# move db2 lib files
execute "cp #{Chef::Config[:file_cache_path]}/db2_drivers/* #{node['schl_endeca']['platform_dir']}/j2sdk/jre/lib/ext/" do
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['platform_dir']}/j2sdk/jre/lib/ext/db2jcc.jar") }
end

# move db2 lib files
execute "cp #{Chef::Config[:file_cache_path]}/AdvJDBCColumnHandler.jar #{node['schl_endeca']['platform_dir']}/cadk/lib/" do
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['platform_dir']}/cadk/lib/AdvJDBCColumnHandler.jar") }
end

# extract CAS tar
execute "tar xfz #{Chef::Config[:file_cache_path]}/cas120il64.tar.gz -C #{node['schl_endeca']['base_dir']}/endeca" do
  user "#{node['schl_endeca']['app_id']}"
	group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['base_dir']}/endeca/ITL/1.2.0") }
end

# extract deploymentTemplate tar
execute "tar xfz #{Chef::Config[:file_cache_path]}/deploymentTemplate-3.2.tar.gz -C #{node['schl_endeca']['base_dir']}/endeca" do
  user "#{node['schl_endeca']['app_id']}"
	group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['base_dir']}/endeca/Solutions/deploymentTemplate-3.2") }
end

# extract PBX tar
execute "tar xfz #{Chef::Config[:file_cache_path]}/PBXApp.tar.gz -C #{node['schl_endeca']['base_dir']}/endeca/Solutions" do
  user "#{node['schl_endeca']['app_id']}"
	group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['base_dir']}/endeca/Solutions/pbxapp") }
end

# copy pbconfig xml
template "#{node['schl_endeca']['base_dir']}/endeca/Solutions/pbxapp/etc/pbconfig.xml" do
  source "pbconfig.xml.erb"
  owner "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
end

# copy webstudio.properties
template "#{node['schl_endeca']['base_dir']}/endeca/Workbench/workspace/conf/webstudio.properties" do
  source "webstudio.properties.erb"
  owner "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  variables(
            :hostname => node[:fqdn],
            :workbench_port => node['schl_endeca']['workbench']['http_port'],
            :eac_port => node['schl_endeca']['platform_services']['http_port']
            )
  not_if { "#{node['schl_endeca']['env']}" == "PROD"}
end

# start up Platform Services 
execute ". #{node['schl_endeca']['base_dir']}/.bash_profile;#{node['schl_endeca']['base_dir']}/endeca/PlatformServices/#{node['schl_endeca']['platform_services_version']}/tools/server/bin/startup.sh" do
  cwd "#{node['schl_endeca']['base_dir']}"
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if %{ps -ef |grep -v grep |grep PlatformServices | grep #{node['schl_endeca']['platform_services_version']}}
end

# start up WorkBench Services 
execute ". #{node['schl_endeca']['base_dir']}/.bash_profile;#{node['schl_endeca']['base_dir']}/endeca/Workbench/#{node['schl_endeca']['workbench_version']}/server/bin/startup.sh" do
  cwd "#{node['schl_endeca']['base_dir']}"
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if %{ps -ef |grep -v grep |grep Workbench | grep #{node['schl_endeca']['workbench_version']}}
  not_if { "#{node['schl_endeca']['env']}" == "PROD" }
end

["keygen.rb", "#{node['schl_endeca']['alias_file_master']}"].each do|file|
    file "#{node['schl_endeca']['base_dir']}/#{file}" do
        action :delete
    end
end