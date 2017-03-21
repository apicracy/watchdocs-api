require 'dotenv'
Dotenv.load
require 'sinatra'
require 'pry'
require 'sidekiq'
require 'redis'

$redis = Redis.new(url: ENV["REDIS_URL"])

Bundler.require

class App < Sinatra::Base
  configure do
    set :show_exceptions, :after_handler
  end

  API_KEY = '8L9qh77q9570H0LIz90Aj00T5mcOHW1w'.freeze
  API_SECRET = 'G52uFXHPjyxRY3JdBIsw562uJ8bUdrE2'.freeze

  post '/api/v1/project/:id/reports' do
    protected!
    request.body.rewind
    Watchdocs::ReportGenerator.new(
      requests_json: request.body.read,
      project_id: params['id']
    ).call
    [200, {}, 'Success!']
  end

  get '/project/:id/docs' do
    @endpoints = EndpointSchema.where(project_id: params['id']).distinct(:endpoint)
    @endpoints.map! do |e|
      statuses = EndpointSchema.where(endpoint: e).distinct(:status)
      statuses.map! do |s|
        EndpointSchema.where(
          endpoint: e,
          status: s
        ).last
      end
      [e, statuses]
    end
    @endpoints = @endpoints.to_h
    erb :index
  end

  error Watchdocs::InvalidJsonError do
    [400, {}, json(errors: env['sinatra.error'].message)]
  end

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      #TODO: Authorize by project credentials
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials &&
        @auth.credentials == [API_KEY, API_SECRET]
    end
  end
end
