attributes :id, :domain_name, :uri
child :environment do
  attributes :id, :ssh_username, :name, :instances_count, :instance_status, :app_server_stack_name, :load_balancer_ip_address, :framework_env
  child :account do
    attributes :id, :name
  end
end
child :app do
  attributes :id, :name, :repository_uri, :app_type_id
  child :account do
    attributes :id, :name
  end
end
