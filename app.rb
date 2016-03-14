
require 'sinatra/base'
require 'json'
require 'octokit'

class DeploymentTutorial < Sinatra::Base

  # !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
  # Instead, set and test environment variables, like below
  ACCESS_TOKEN = ENV['MY_PERSONAL_TOKEN']

  before do
    Octokit.configure do |c|
      c.api_endpoint = "https://octodemo.com/api/v3/"
    end
    @client ||= Octokit::Client.new(:access_token => ACCESS_TOKEN)
  end

  get '/' do
    "Hello I'm a deploy server :-)"
  end

  post '/event_handler' do
    @payload = JSON.parse(params[:payload])

    case request.env['HTTP_X_GITHUB_EVENT']
    when "pull_request"
      if @payload["action"] == "closed" && @payload["pull_request"]["merged"]
        start_deployment(@payload["pull_request"])
      end
    when "deployment"
      process_deployment
    when "deployment_status"
      update_deployment_status
    when "issue_comment"
      pull_request = @client.pull_request(Octokit::Repository.new(@payload["repository"]["full_name"]), @payload["issue"]["number"])
      check_comment(@payload["comment"]["body"], @payload["repository"]["full_name"], pull_request["head"]["sha"])
    end
  end

  helpers do
    def check_comment(body, full_name, p_sha)
      if body =~ /.*OK.*/
        @client.create_status(full_name, p_sha, "success", {:context => "Manager Approval", :target_url => @payload["comment"]["html_url"], :description => "マネージャーがOKといえばマージ可能"})
      elsif body =~ /.*NG.*/
        @client.create_status(full_name, p_sha, "failure", {:context => "Manager Approval", :target_url => @payload["comment"]["html_url"], :description => "マネージャーがOKといえばマージ可能"})
      end

      "Status returned!"
    end

    def start_deployment(pull_request)
      user = pull_request['user']['login']
      payload = JSON.generate(:environment => 'production', :deploy_user => user)
      @client.create_deployment(pull_request['head']['repo']['full_name'], pull_request['head']['sha'], {:auto_merge => false, :payload => payload, :description => "Deploying my sweet branch"})

      "Deployment started!"
    end

    def process_deployment
      payload = JSON.parse(@payload['deployment']['payload'])
      # you can send this information to your chat room, monitor, pager, e.t.c.
      puts "Processing '#{@payload['deployment']['description']}' for #{payload['deploy_user']} to #{payload['environment']}"
      sleep 2 # simulate work
      @client.create_deployment_status("repos/#{@payload['repository']['full_name']}/deployments/#{@payload['deployment']['id']}", 'pending')
      sleep 2 # simulate work
      @client.create_deployment_status("repos/#{@payload['repository']['full_name']}/deployments/#{@payload['deployment']['id']}", 'success')

      "Deployment was processed!"
    end

    def update_deployment_status
      puts "Deployment status for #{@payload['deployment']['id']} is #{@payload['deployment_status']['state']}"
    end
  end
end
