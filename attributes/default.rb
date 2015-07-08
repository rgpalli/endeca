#  Platform Services silent installation
default['schl_endeca']['file_system'] = '/opt'
default['schl_endeca']['app_id'] = 'endeca6'
default['schl_endeca']['base_dir'] = "#{node['schl_endeca']['file_system']}/#{node['schl_endeca']['app_id']}"
default['schl_endeca']['accept_license'] = 'Y'
default['schl_endeca']['platform_services']['http_port'] = 8889
default['schl_endeca']['platform_services']['shutdown_port'] = 8091
default['schl_endeca']['jcd_port'] = 8100
default['schl_endeca']['eac_host'] = 'Y'
default['schl_endeca']['eac_agent'] = 'N' # ( comment: Master Host = Y and Agent Host = N )
default['schl_endeca']['is_eac'] = 'Y' # ( comment: Master Host = Y and Agent Host = N )
default['schl_endeca']['platform_services_version'] = '6.1.0'
default['schl_endeca']['mdex_version'] = '6.1.3'
default['schl_endeca']['workbench_version'] = '2.1.0'
default['schl_endeca']['mdex_directory'] = "#{node['schl_endeca']['base_dir']}/endeca/MDEX/#{node['schl_endeca']['mdex_version']}"
default['schl_endeca']['platform_dir'] = "#{node['schl_endeca']['base_dir']}/endeca/PlatformServices/#{node['schl_endeca']['platform_services_version']}"
default['schl_endeca']['Install_reference_apps'] = 'Y'
default['schl_endeca']['workbench_dir'] = "#{node['schl_endeca']['base_dir']}/endeca/Workbench/#{node['schl_endeca']['workbench_version']}"
default['schl_endeca']['env'] = node.chef_environment =~ /ec-prod1/ ? "PROD" : "NON_PROD"
default['schl_endeca']['alias_file_master'] = "alias_master_#{node['schl_endeca']['env']}.txt"
default['schl_endeca']['alias_file_agent'] = 'alias_agent.txt'
default['schl_endeca']['bash_file'] = '.bash_profile'
default['schl_endeca']['artifact_url'] = "http://scholastic.artifactoryonline.com/scholastic/Endeca/endeca-components"

#
#  Workbench silent installation
default['schl_endeca']['local_fqdn'] = node['fqdn']
default['schl_endeca']['workbench']['http_port'] = 8006
default['schl_endeca']['workbench']['shutdown_port'] = 8084
default['schl_endeca']['workbench']['platform_services_server_fqdn'] = node['fqdn']
default['schl_endeca']['workbench_port'] = 8006
default['schl_endeca']['dgraph1_port'] = 6000
default['schl_endeca']['dgraph2_port'] = 6001
default['schl_endeca']['log_server_port'] = 6010
