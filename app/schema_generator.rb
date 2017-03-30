require './app/models/endpoint_schema'
require 'multijson_schema_generator'

module Watchdocs
  module SchemaGenerator
    NUMBER_OF_RECENT_CALLS = 5

    class << self
      def generate(project_id, endpoint, status)
        calls = recent_calls(project_id, endpoint, status)
        params = {
          project_id: project_id,
          endpoint: endpoint,
          status: status,
          response: create_schema(calls, :response)
        }
        params[:request] = create_schema(calls, :request) if status.to_s =~ /^2/
        EndpointSchema.create(params)
      end

      def generate_for_endpoints(project_id, endpoints)
        endpoints.each do |endpoint, statuses|
          generate_for_statuses(project_id, endpoint, statuses)
        end
      end

      def generate_for_statuses(project_id, endpoint, statuses)
        statuses.uniq.each do |status|
          generate(project_id, endpoint, status)
        end
      end

      private

      def recent_calls(project_id, endpoint, status)
        EndpointCall.where(
          project_id: project_id,
          endpoint: endpoint,
          status: status
        ).order(id: :desc).limit(NUMBER_OF_RECENT_CALLS)
      end

      def create_schema(calls, source)
        Watchdocs::JSON::SchemaGenerator.new(
          calls.map do |c|
            ::JSON.parse(c.call)[source.to_s]['body']
          end
        ).call.to_json
      end
    end
  end
end
