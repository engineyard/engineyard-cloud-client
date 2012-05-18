object @resolver => :resolver
node :matches do
  @resolver.matches.map do |match|
    partial('base_app_environment', :object => match, :root => nil)
  end
end
attributes :errors, :suggestions
