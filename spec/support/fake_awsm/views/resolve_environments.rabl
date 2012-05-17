object @resolver => :resolver
node :matches do |resolver|
  resolver.matches.map do |match|
    partial('environment_match', :object => match, :root => nil)
  end
end
attributes :errors, :suggestions
