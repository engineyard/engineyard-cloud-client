require 'rubygems'
require 'sinatra/base'
require 'json'
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

  before do
    if env['PATH_INFO'] =~ %r#/api/v2#
      user_agent = env['HTTP_USER_AGENT']
      unless user_agent =~ %r#^EngineYardCloudClient/\d#
        $stderr.puts 'No user agent header, expected EngineYardCloudClient/'
        halt 400, 'No user agent header, expected EngineYardCloudClient/'
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
    new_scenario = SCENARIOS.detect { |scen| scen.user.name == params[:scenario] }
    unless new_scenario
      status(404)
      return {"ok" => "false", "message" => "wtf is the #{params[:scenario]} scenario?"}.to_json
    end
    user = new_scenario.user
    {
      "scenario" => {
        "email"     => user.email,
        "password"  => user.password,
        "api_token" => user.api_token,
      }
    }.to_json
  end

  get "/scenarios" do
    scenarios = SCENARIOS.map do |scen|
      user = scen.user
      {
        :name      => user.name,
        :email     => user.email,
        :password  => user.password,
        :api_token => user.api_token,
      }
    end
    {'scenarios' => scenarios}.to_json
  end

  get "/api/v2/current_user" do
    render :rabl, :user, :format => "json"
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
    {
      "logs" => [
        {
          "id" => params['env_id'].to_i,
          "role" => "app_master",
          "main" => "MAIN LOG OUTPUT",
          "custom" => "CUSTOM LOG OUTPUT"
        }
      ]
    }.to_json
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

  get "/api/v2/apps/:app_id/environments/:environment_id/deployments/last" do
    {
      "deployment" => {
        "id" => 3,
        "ref" => "HEAD",
        "resolved_ref" => "HEAD",
        "commit" => 'a'*40,
        "user_name" => "User Name",
        "migrate_command" => "rake db:migrate --trace",
        "created_at" => Time.now.utc - 3600,
        "finished_at" => Time.now.utc - 3400,
        "successful" => true,
      }
    }.to_json
  end

  post "/api/v2/apps/:app_id/environments/:environment_id/deployments" do
    {"deployment" => params[:deployment].merge({"id" => 2, "commit" => 'a'*40, "resolved_ref" => "resolved-#{params[:deployment][:ref]}"})}.to_json
  end

  put "/api/v2/apps/:app_id/environments/:environment_id/deployments/:deployment_id/finished" do
    {"deployment" => params[:deployment].merge({"id" => 2, "finished_at" => Time.now})}.to_json
  end

  post "/api/v2/authenticate" do
    user = User.first(:email => params[:email], :password => params[:password])
    if user
      {"api_token" => user.api_token, "ok" => true}.to_json
    else
      status(401)
      {"ok" => false}.to_json
    end
  end

end

run FakeAwsm.new
