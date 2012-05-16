collection @environments, :root => :environments, :object_root => false
attributes :id, :ssh_username, :name, :instances_count, :app_server_stack_name, :load_balancer_ip_address, :framework_env
child :account do
  attributes :id, :name
end
child :app_master do
  attributes :id, :role, :name, :status, :amazon_id, :public_hostname
end
child :instances do
  attributes :id, :role, :name, :status, :amazon_id, :public_hostname
end

child :apps do
  attributes :id, :name, :repository_uri
  child :account do
    attributes :name
  end
end
