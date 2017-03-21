require 'mongoid'
Mongoid.load!('mongoid.yml', ENV['RACK_ENV'])
require './app/models/report'
require './app/models/endpoint_call'
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
        report.requests.each do |request|
          if endpoints[request[:endpoint]]
            endpoints[request[:endpoint]] << request[:response][:status]
          else
            endpoints[request[:endpoint]] = [request[:response][:status]]
          end
          EndpointCall.create(
            project_id: report.project_id,
            call: request
          )
        end
        endpoints.map { |k, v| [k, v.uniq] }.to_h
      end
    end
  end
end
