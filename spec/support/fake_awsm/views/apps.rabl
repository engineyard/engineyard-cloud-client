collection @apps, :root => :apps, :object_root => false
attributes :id, :name, :repository_uri, :app_type_id
child :account do
  attributes :id, :name
end
child :environments do
  attributes :id, :ssh_username, :name, :instances_count, :app_server_stack_name, :load_balancer_ip_address, :framework_env
  child :account do
    attributes :id, :name
  end
end
