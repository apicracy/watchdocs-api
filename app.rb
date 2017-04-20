require 'sinatra'
require 'pry'
require 'sidekiq'
require 'redis'

Bundler.require

class App < Sinatra::Base
  configure do
    set :show_exceptions, :after_handler
  end

  post '/api/v1/reports' do
    authorize_by_project!
    request.body.rewind
    Watchdocs::ReportGenerator.new(
      requests_json: request.body.read,
      project_id: @project.app_id
    ).call
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

  error Watchdocs::InvalidJsonError do
    [400, {}, json(errors: env['sinatra.error'].message)]
  end

  helpers do
    def authorize_by_project!
      return if set_project
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 404, 'Project not found'
    end

    def set_project
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      return unless valid_auth?
      @project = Project.authorize(*@auth.credentials)
    end

    def valid_auth?
      @auth.provided? && @auth.basic? && @auth.credentials.present?
    end
  end
end
