object @resolver => :resolver
node :matches do |resolver|
  resolver.matches.map do |match|
    partial('base_environment', :object => match, :root => nil)
  end
end
attributes :errors, :suggestions
