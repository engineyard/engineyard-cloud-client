collection @apps, :root => :apps, :object_root => false
attributes :id, :name, :repository_uri, :app_type_id
child :account do
  attributes :id, :name
end
node :environments do |m|
  m.environments.map do |env|
    partial('base_environment', :object => env, :root => nil)
  end
end
