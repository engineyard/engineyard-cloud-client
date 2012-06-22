attributes :id, :ssh_username, :name, :instances_count, :instance_status, :app_server_stack_name, :load_balancer_ip_address, :framework_env
child :account do
  attributes :id, :name
end
