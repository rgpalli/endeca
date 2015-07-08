#
# Cookbook Name:: schl_endeca
# Recipe:: agent_install
#
# Copyright 2013, Scholastic
#
# All rights reserved - Do Not Redistribute
#
# get endeca binaries



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

#Create Source file for endeca
template "#{node['schl_endeca']['base_dir']}/#{node['schl_endeca']['alias_file_agent']}" do
  source "#{node['schl_endeca']['alias_file_agent']}.erb"
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

#Update the .bash_profile file of endeca6 user to include all the source file of App Endeca
ruby_block "Update .bash_profile of #{node['schl_endeca']['app_id']} user" do
      block do
          begin
            require 'fileutils'
            Schl_ETL.mergefile("#{node['schl_endeca']['base_dir']}/#{node['schl_endeca']['bash_file']}", "#{node['schl_endeca']['base_dir']}/#{node['schl_endeca']['alias_file_agent']}")
    rescue Exception => e
  puts e.message
          end
      end
end

master = search(:node, "role:endeca_master AND chef_environment:#{node.chef_environment}")

master.each do |index|
  schl_keygen_ssh "Copy SSH keys to #{index[:fqdn]}" do
    username "#{node['schl_endeca']['app_id']}"
    groupname "#{node['schl_endeca']['app_id']}"
    user_home "#{node['schl_endeca']['base_dir']}"
    keygen_file "kygn.rb"
    ssh_file "ssh_cp.rb"
    sshhost "#{index[:fqdn]}"
    userpswd user_info['user_pswd_plain']
  end
end

["dos2unix", "glibc.i686"].each do |pkg|
  yum_package pkg do
    action :install
  end
end
 
execute "dos2unix #{Chef::Config[:file_cache_path]}/platform_services_silent" do
  user "root"
end

# install MDEX
execute "echo Y | #{Chef::Config[:file_cache_path]}/mdex_613_x86_64pc-linux.sh --silent --target #{node['schl_endeca']['base_dir']}; cp #{Chef::Config[:file_cache_path]}/dgraph #{node['schl_endeca']['base_dir']}/endeca/MDEX/6.1.3/bin/" do
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['mdex_directory']}") }
end

# install Platform services. Use the platform services silent file
execute "#{Chef::Config[:file_cache_path]}/platformservices_610_x86_64pc-linux.sh --silent --target #{node['schl_endeca']['base_dir']} < #{Chef::Config[:file_cache_path]}/platform_services_silent" do
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if { File.exists?("#{node['schl_endeca']['platform_dir']}") }
end

# start up Platform Services 
execute ". #{node['schl_endeca']['base_dir']}/.bash_profile;#{node['schl_endeca']['base_dir']}/endeca/PlatformServices/#{node['schl_endeca']['platform_services_version']}/tools/server/bin/startup.sh" do
  cwd "#{node['schl_endeca']['base_dir']}"
  user "#{node['schl_endeca']['app_id']}"
  group "#{node['schl_endeca']['app_id']}"
  not_if %{ps -ef |grep -v grep |grep PlatformServices | grep #{node['schl_endeca']['platform_services_version']}}
end

["#{node['schl_endeca']['alias_file_agent']}"].each do|file|
    file "#{node['schl_endeca']['base_dir']}/#{file}" do
        action :delete
    end
end