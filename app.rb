require 'sinatra'
require 'pry'
require 'sidekiq'
require 'redis'

Bundler.require

class App < Sinatra::Base
  configure do
    set :show_exceptions, :after_handler
  end

  before { @auth = Rack::Auth::Basic::Request.new(request.env) }

  post '/api/v1/reports' do
    authorize_by_project!
    request.body.rewind
    Watchdocs::ReportGenerator.new(
      requests_json: request.body.read,
      project_id: @project.app_id
    ).call
    [200, {}, 'Success!']
  end

  post '/api/v1/projects' do
    authorize_by_envs!
    request.body.rewind
    Watchdocs::ProjectCreator.new(request.body.read).call
    [200, {}, 'Success!']
  end

  get '/project/:app_id/docs' do
    aggregation = EndpointSchema.aggregation_pipeline(params['app_id'])
    @schemas = []
    EndpointSchema.collection
                  .aggregate(aggregation)
                  .each { |s| @schemas << s }
    erb :index
  end

  error Watchdocs::InvalidJsonError, Mongoid::Errors::Validations do
    [400, {}, json(errors: env['sinatra.error'].message)]
  end

  error do
    [500, {}, json(errors: env['sinatra.error'].message)]
  end

  helpers do
    def authorize_by_project!
      return if valid_auth? && set_project
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 404, 'Project not found'
    end

    def authorize_by_envs!
      return if valid_auth? && authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def set_project
      @project = Project.authorize(*@auth.credentials)
    end

    def valid_auth?
      @auth.provided? && @auth.basic? && @auth.credentials.present?
    end

    def authorized?
      @auth.credentials == [ENV['EXPORT_AUTH_USERNAME'], ENV['EXPORT_AUTH_PASSWORD']]
    end
  end
end
