require './app/models/endpoint_schema'
require './app/schema_exporter'
require 'multijson_schema_generator'

module Watchdocs
  module SchemaGenerator
    NUMBER_OF_RECENT_CALLS = 5

    class << self
      def generate(project_id, endpoint, method, status)
        calls = recent_calls(project_id, endpoint, method, status)
        params = {
          project_id: project_id,
          endpoint: endpoint,
          method: method,
          status: status,
          response: create_schema(recent_bodies(calls, :response)),
          response_headers: create_schema(recent_headers(calls, :response))
        }
        if status.to_s =~ /^2/
          params[:request] = create_schema(recent_bodies(calls, :request))
          params[:request_headers] = create_schema(recent_headers(calls, :request))
          params[:query_string_params] = create_schema(recent_query_params(calls))
        end
        endpoint_schema = EndpointSchema.create(params)
        SchemaExporter.export(endpoint_schema)
      end

      def generate_for_endpoints(project_id, endpoints)
        endpoints.each do |endpoint, methods|
          generate_for_methods(project_id, endpoint, methods)
        end
      end

      def generate_for_methods(project_id, endpoint, methods)
        methods.each do |method, statuses|
          generate_for_statuses(project_id, endpoint, method, statuses)
        end
      end

      def generate_for_statuses(project_id, endpoint, method, statuses)
        statuses.uniq.each do |status|
          generate(project_id, endpoint, method, status)
        end
      end

      private

      def recent_calls(project_id, endpoint, method, status)
        EndpointCall.where(
          project_id: project_id,
          endpoint: endpoint,
          method: method,
          status: status
        ).order(id: :desc).limit(NUMBER_OF_RECENT_CALLS)
      end

      def create_schema(recent_objects)
        Watchdocs::JSON::SchemaGenerator.new(recent_objects).call.to_json
      end

      def recent_bodies(calls, source)
        recent_objects(calls, source, :body)
      end

      def recent_query_params(calls)
        recent_objects(calls, :request, :query_string_params)
      end

      def recent_headers(calls, source)
        recent_objects(calls, source, :headers) do |headers|
          headers.map do |header|
            [header, 'string'] # TODO: move this to middleware in the future
          end.to_h
        end
      end

      def recent_objects(calls, source, object)
        calls.map do |c|
          objects = ::JSON.parse(c.call)[source.to_s][object.to_s]
          block_given? ? yield(objects) : objects
        end
      end
    end
  end
end
