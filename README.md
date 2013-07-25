# Engine Yard Cloud Client

engineyard-cloud-client contains a Ruby api library to the Engine Yard Cloud API. Extracted from the [engineyard gem](https://github.com/engineyard/engineyard).

## Use at your own risk

At this time, cloud-client is not documented for public use. It was created to
be used by the engineyard gem with the hopes of eventually providing a public
api client, but it's still in its infancy.

If you would like to use this gem directly instead of interfacing with the
engineyard gem, you will likely be on your own. We may be available to answer
questions about the gem, but the gem itself is not currently a supported public
interface to Engine Yard Cloud.

This gem accesses API actions that can alter your dashboard and settings. If
used incorrectly, it could lead to problems. As we work towards making this a
reliable public client, the interface may change.

If you intend to use this gem, please lock to an exact version and pay close
attention to newly released versions and changes to the interface.

Please [open github issues](https://github.com/engineyard/engineyard-cloud-client/issues)
for any problems you encounter.

## Usage

Setup:

    require 'engineyard-cloud-client'
    require 'engineyard-cloud-client/test'

    token  = EY::CloudClient.new.authenticate("your@email.com", "password")
    ui = EY::CloudClient::Test::VerboseUI.new
    # Test::VerboseUI is used in this example for simplicity.
    # You may substitute your own ui object with #debug and #info methods

    ey_api = EY::CloudClient.new(token, ui)

Current User:

    user = ey_api.current_user
    user.class # => EY::CloudClient::User
    user.name  # => "Your Name"
    user.email # => "your@email.com"

Apps:

    apps = ey_api.apps # loads all your app data at once; caches result

    app = apps.find {|app| app.name == 'myapp'}
    app.class           # => EY::CloudClient::App
    app.name            # => 'myapp'
    app.id              # => 123
    app.repository_uri  # => git@github.com:myaccount/myapp.git

    app.account.class   # => EY::CloudClient::Account

    app.app_environments.first.class # => EY::CloudClient::AppEnvironment
    app.app_environments.map {|e| e.environment.name} # => ['myapp_production', 'myapp_staging']

Create a new application (to be booted within Environments):

    account = EY::CloudClient::Account.new(ey_api, {:id => 4212, :name => 'drnic'})
    app = EY::CloudClient::App.create(ey_api,
      "account"        => account
      "name"           => "myapp",
      "repository_uri" => "git@github.com:mycompany/myapp.git",
      "app_type_id"    => "rails3",
    })

Valid `app_type_id` are: `rack, rails2, rails3, rails4, sinatra, nodejs`. For some your account may require an early access feature to be enabled.

Accounts:

    account = app.account
    account.class   # => EY::CloudClient::Account
    account.id      # => 1234
    account.name    # => 'myaccount'

Keypairs:

Upload your SSH public keys before you create Environments.

    keypair = EY::CloudClient::Keypair.create(ey_api, {
      "name"       => 'laptop',
      "public_key" => "ssh-rsa OTHERKEYPAIR"
    })

Environments:

    envs = ey_api.environments # loads all your environment data at once; caches result

    env = envs.find {|e| e.name == 'myapp_production'}
    env.class             # => EY::CloudClient::Environment
    env.name              # => 'myapp_production'
    env.id                # => 2345
    env.framework_env     # => "production"
    env.app_server_stack_name     # => "nginx_thin"
    env.deployment_configurations # => {"myapp"=>{"name"=>"myapp", "uri"=>nil, "migrate"=>{"command"=>"rake db:migrate", "perform"=>false}, "repository_uri"=>"git@github.com:myaccount/myapp.git", "id"=>123, "domain_name"=>"_"}}
    env.load_balancer_ip_address  # => "1.2.3.4"

    # if environment isn't booted
    env.instances_count     # => 0
    env.app_master          # => nil
    env.instances.count     # => []

    # if environment is booted
    env.instances_count     # => 1
    env.app_master.class    # => EY::CloudClient::Instance
    env.instances.first.class # => EY::CloudClient::Instance

Create a new environment (for a given App):

    app = EY::CloudClient::App.new(ey_api, {:id => 4212, :name => 'drnic'})
    env = EY::CloudClient::Environment.create(ey_api,
      "app"                   => app,
      "name"                  => 'myapp_production',
      "app_server_stack_name" => 'nginx_thin',       # default: nginx_passenger3
      "region"                => 'us-west-1',        # default: us-east-1
      "framework_env"         => 'staging'           # default: production
    })


Valid `app_server_stack_name` values: `nginx_unicorn, nginx_passenger3, nginx_nodejs, nginx_thin, nginx_puma`. For some your account may require an early access feature to be enabled.

Instances:

    instance = env.instances.first
    instance.class        # => EY::CloudClient::Instance
    instance.id           # => 12345
    instance.role         # => "solo"
    instance.status       # => "running"
    instance.amazon_id    # => "i-abcdefg"
    instance.hostname     # => "ec2-1-2-3-4.compute-1.amazonaws.com"
    instance.public_hostname # => "ec2-1-2-3-4.compute-1.amazonaws.com" # alias of hostname

## Debugging:

When $DEBUG is set, display debug information to the ui object using the #debug method. The API commands will print internal request information:

    app = EY::CloudClient::App.create(ey_api, 'account' => account, 'name' => 'myapp2', 'repository_uri' => 'git@github.com:myaccount/myapp2.git', 'app_type_id' => 'rails3')
           Token  YOURTOKEN
         Request  POST https://cloud.engineyard.com/api/v2/accounts/1234/apps
          Params  {"app"=>{"name"=>"myapp2", "app_type_id"=>"rails3", "repository_uri"=>"git@github.com:myaccount/myapp2.git"}}
        Response
    {"app"=>
      {"environments"=>[],
       "name"=>"myapp2",
       "repository_uri"=>"git@github.com:myaccount/myapp2.git",
       "account"=>{"name"=>"myaccount", "id"=>1234},
       "id"=>12345}}

