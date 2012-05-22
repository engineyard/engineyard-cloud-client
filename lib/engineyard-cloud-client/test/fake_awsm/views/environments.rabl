collection @environments, :root => :environments, :object_root => false
attributes :id, :ssh_username, :name, :instances_count, :app_server_stack_name, :load_balancer_ip_address, :framework_env
child :account do
  attributes :id, :name
end
node :apps do |m|
  m.apps.map do |app|
    partial('base_app', :object => app, :root => nil)
  end
end
