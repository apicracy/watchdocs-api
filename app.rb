require 'dotenv'
Dotenv.load
require 'sinatra'
require 'pry'

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

  error Watchdocs::InvalidJsonError do
    [400, {}, json(errors: env['sinatra.error'].message)]
  end
end
