require 'rubygems'
require 'sinatra/base'
require 'multi_json'
require 'rabl'
require 'gitable'
require 'ey_resolver'
require File.expand_path('../scenarios', __FILE__)
require File.expand_path('../models', __FILE__)

Rabl.register!

class FakeAwsm < Sinatra::Base
  disable :show_exceptions
  enable :raise_errors
  set :views, File.expand_path('../views', __FILE__)

  SCENARIOS = [
    Scenario::Base.new,
    Scenario::AppWithoutEnv.new,
    Scenario::UnlinkedApp.new,
    Scenario::TwoApps.new,
    Scenario::LinkedApp.new,
    Scenario::StuckDeployment.new,
    Scenario::MultipleAmbiguousAccounts.new,
    Scenario::LinkedAppNotRunning.new,
    Scenario::LinkedAppRedMaster.new,
    Scenario::OneAppManyEnvs.new,
    Scenario::OneAppManySimilarlyNamedEnvs.new,
    Scenario::TwoAppsSameGitUri.new,
  ]

  def initialize(*)
    super
    @user = Scenario::Base.new.user
  end

  helpers do
    def json(data)
      MultiJson.dump(data)
    end
  end

  before do
    if env['PATH_INFO'] =~ %r#/api/v2#
      user_agent = env['HTTP_USER_AGENT']
      unless user_agent =~ %r#EngineYardCloudClient/\d#
        msg = "No user agent header, expected EngineYardCloudClient/ got #{user_agent.inspect}"
        $stderr.puts msg
        halt 400, msg
      end
    end
    content_type "application/json"
    token = request.env['HTTP_X_EY_CLOUD_TOKEN']
    if token
      @user = User.first(:api_token => token)
    end
  end

  get "/" do
    content_type :html
    "OMG"
  end

  get "/scenario" do
    found_scenario = SCENARIOS.detect { |scen| scen.user.name == params[:scenario] }
    unless found_scenario
      status(404)
      return json({"ok" => "false", "message" => "wtf is the #{params[:scenario]} scenario?"})
    end
    @scenario = found_scenario.user
    render :rabl, :scenario, :format => "json"
  end

  get "/scenarios" do
    @scenarios = SCENARIOS.map { |scen| scen.user }
    render :rabl, :scenarios, :format => "json"
  end

  get "/api/v2/current_user" do
    render :rabl, :user, :format => "json"
  end

  post "/api/v2/keypairs" do
    @keypair = @user.keypairs.create(params['keypair'])
    render :rabl, :keypair, :format => "json"
  end

  get "/api/v2/keypairs" do
    @keypairs = @user.keypairs
    render :rabl, :keypairs, :format => "json"
  end

  delete "/api/v2/keypairs/:id" do
    keypair = @user.keypairs.get(params['id'])
    if keypair
      keypair.destroy
      status 204
      ""
    else
      status 404
      json  "message" => "Keypair not found with id #{params['id'].inspect}"
    end
  end

  get "/api/v2/accounts" do
    @accounts = @user.accounts
    render :rabl, :accounts, :format => "json"
  end

  get "/api/v2/apps" do
    @apps = @user.accounts.apps
    render :rabl, :apps, :format => "json"
  end

  get "/api/v2/environments" do
    @environments = @user.accounts.environments
    render :rabl, :environments, :format => "json"
  end

  get "/api/v2/environments/resolve" do
    @resolver = EY::Resolver.environment_resolver(@user, params['constraints'])
    render :rabl, :resolve_environments, :format => "json"
  end

  get "/api/v2/app_environments/resolve" do
    @resolver = EY::Resolver.app_env_resolver(@user, params['constraints'])
    render :rabl, :resolve_app_environments, :format => "json"
  end

  get "/api/v2/environments/:env_id/instances" do
    environment = @user.accounts.environments.get(params['env_id'])
    @instances = environment.instances
    render :rabl, :instances, :format => "json"
  end

  get "/api/v2/environments/:env_id/logs" do
    json(
      "logs" => [
        {
          "id" => 'i-12345678',
          "role" => "app_master",
          "main" => "MAIN LOG OUTPUT",
          "custom" => "CUSTOM LOG OUTPUT"
        }
      ]
    )
  end

  get "/api/v2/environments/:env_id/recipes" do
    redirect '/fakes3/recipe'
  end

  get "/fakes3/recipe" do
    content_type "binary/octet-stream"
    status(200)

    tempdir = File.join(Dir.tmpdir, "ey_test_cmds_#{Time.now.tv_sec}#{Time.now.tv_usec}_#{$$}")
    Dir.mkdir(tempdir)
    Dir.mkdir("#{tempdir}/cookbooks")
    File.open("#{tempdir}/cookbooks/README", 'w') do |f|
      f.write "Remove this file to clone an upstream git repository of cookbooks\n"
    end

    Dir.chdir(tempdir) { `tar czf - cookbooks` }
  end

  post "/api/v2/environments/:env_id/recipes" do
    if params[:file][:tempfile]
      files = `tar --list -z -f "#{params[:file][:tempfile].path}"`.split(/\n/)
      if files.empty?
        status(400)
        "No files in uploaded tarball"
      else
        status(204)
        ""
      end
    else
      status(400)
      "Recipe file not uploaded"
    end
  end

  put "/api/v2/environments/:env_id/update_instances" do
    status(202)
    ""
  end

  put "/api/v2/environments/:env_id/run_custom_recipes" do
    status(202)
    ""
  end

  post "/api/v2/apps/:app_id/environments/:environment_id/deployments" do
    app_env = @user.accounts.apps.get(params[:app_id]).app_environments.first(:environment_id => params[:environment_id])
    @deployment = app_env.deployments.create(params[:deployment])
    render :rabl, :deployment, :format => "json"
  end

  post "/api/v2/apps/:app_id/environments/:environment_id/deployments/deploy" do
    app_env = @user.accounts.apps.get(params[:app_id]).app_environments.first(:environment_id => params[:environment_id])
    @deployment = app_env.deployments.create(params[:deployment])
    @deployment.deploy
    response['Location'] = "/api/v2/apps/#{params[:app_id]}/environments/#{params[:environment_id]}/deployments/#{@deployment.id}"
    render :rabl, :deployment, :format => "json"
  end

  get "/api/v2/apps/:app_id/environments/:environment_id/deployments/last" do
    app_env = @user.accounts.apps.get(params[:app_id]).app_environments.first(:environment_id => params[:environment_id])
    @deployment = app_env.deployments.last
    if @deployment
      render :rabl, :deployment, :format => "json"
    else
      status(404)
      json "message" => "Deployment not found: last"
    end
  end

  put "/api/v2/apps/:app_id/environments/:environment_id/deployments/:deployment_id/finished" do
    app_env = @user.accounts.apps.get(params[:app_id]).app_environments.first(:environment_id => params[:environment_id])
    @deployment = app_env.deployments.get(params[:deployment_id])
    @deployment.finished!(params[:deployment])
    render :rabl, :deployment, :format => "json"
  end

  post "/api/v2/authenticate" do
    user = User.first(:email => params[:email], :password => params[:password])
    if user
      json  "api_token" => user.api_token, "ok" => true
    else
      status(401)
      json  "ok" => false
    end
  end

end

run FakeAwsm.new
