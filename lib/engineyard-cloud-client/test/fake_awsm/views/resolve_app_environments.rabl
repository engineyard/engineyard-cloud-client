object @resolver => :resolver
node :matches do
  @resolver.matches.map do |match|
    partial('app_environment_match', :object => match, :root => nil)
  end
end
attributes :errors, :suggestions
