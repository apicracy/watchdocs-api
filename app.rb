require 'sinatra'
require 'pry'
require 'sidekiq'
require 'redis'

$redis = Redis.new

Bundler.require

class App < Sinatra::Base
  configure do
    set :show_exceptions, :after_handler
  end

  post '/api/v1/project/:id/reports' do
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
end
