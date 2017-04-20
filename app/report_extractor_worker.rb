require 'dotenv'
Dotenv.load
require 'mongoid'
Mongoid.load!('mongoid.yml', ENV['RACK_ENV'])
require './app/models/report'
require './app/models/endpoint_call'
require './app/models/project'
require './app/schema_generator'
require 'sidekiq'

$redis = Redis.new(url: ENV["REDIS_URL"])

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { :size => 5 }
end

module Watchdocs
  module Worker
    class ReportExtractorWorker
      include Sidekiq::Worker

      def perform(report_id)
        report = Report.find(report_id)
        endpoints = extract_endpoint_calls(report)
        Watchdocs::SchemaGenerator.generate_for_endpoints(
          report.project_id,
          endpoints
        )
      rescue Mongoid::Errors::DocumentNotFound
        puts "Report not found: #{report_id}"
        return nil
      end

      private

      def extract_endpoint_calls(report)
        endpoints = {}
        requests = ::JSON.parse(report.requests)
        requests.each do |request|
          endpoint = request['endpoint']
          method = request['request']['method']
          status = request['response']['status']
          endpoints = log_call(endpoints, endpoint, method, status)
          EndpointCall.create(
            project_id: report.project_id,
            call: request.to_json,
            endpoint: endpoint,
            status: status,
            method: method
          )
        end
        endpoints
      end

      def log_call(endpoints, endpoint, method, status)
        if endpoints.dig(endpoint, method)
          endpoints[endpoint][method] << status
          endpoints[endpoint][method].uniq
        elsif endpoints[endpoint]
          endpoints[endpoint][method] = [status]
        else
          endpoints[endpoint] = {}
          endpoints[endpoint][method] = [status]
        end
        endpoints
      end
    end
  end
end
