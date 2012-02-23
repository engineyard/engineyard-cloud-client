require 'rspec/matchers'

RSpec::Matchers.define :have_app_code do
  match { |instance| instance.has_app_code? }

  failure_message_for_should do |instance|
    "Expected #has_app_code? to be true on instance: #{instance.inspect}"
  end

  failure_message_for_should_not do |instance|
    "Expected #has_app_code? to be false on instance: #{instance.inspect}"
  end
end
