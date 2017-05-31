require './app/models/endpoint_schema'
require './app/schema_exporter'
require 'multijson_schema_generator'
require 'active_support/core_ext/hash/slice'

module Watchdocs
  module SchemaGenerator
    NUMBER_OF_RECENT_CALLS = 5

    class << self
      def generate(project_id, endpoint, method, status)
        calls = recent_calls(project_id, endpoint, method, status)
        remove_old_calls(calls, project_id, endpoint, method, status)

        params = {
          project_id: project_id,
          endpoint: endpoint,
          method: method,
          status: status,
          response: create_schema(recent_bodies(calls, :response))
        }
        if status.to_s =~ /^2/
          params[:request] = create_schema(recent_bodies(calls, :request))
          params[:query_string_params] = create_schema(recent_query_params(calls))
        end
        return unless schema_changed?(params)
        endpoint_schema = EndpointSchema.create(params)
        SchemaExporter.export(endpoint_schema)
        remove_old_schemas(params)
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

      def recent_objects(calls, source, object)
        calls.map do |c|
          objects = ::JSON.parse(c.call)[source.to_s][object.to_s]
          block_given? ? yield(objects) : objects
        end
      end

      def remove_old_calls(recent_calls, project_id, endpoint, method, status)
        EndpointCall.where(
          project_id: project_id,
          endpoint: endpoint,
          method: method,
          status: status
        ).not_in(:_id => recent_calls.map(&:id)).delete_all
      end

      def schema_changed?(new_schema)
        old_schema = EndpointSchema.where(
          new_schema.slice(:project_id, :endpoint, :method, :status)
        ).last
        return true unless old_schema
        return true if new_schema[:response] != old_schema.response
        return true if new_schema[:request] != old_schema.request
        return true if new_schema[:query_string_params] != old_schema.query_string_params
        false
      end

      def remove_old_schemas(new_schema_params)
        conditions = new_schema_params.slice(:project_id, :endpoint, :method,
                                             :status)
        recent_schemas = EndpointSchema.where(conditions)
                                       .order(id: :desc)
                                       .limit(NUMBER_OF_RECENT_CALLS)

        EndpointSchema.where(conditions)
                      .not_in(:_id => recent_schemas.map(&:id))
                      .delete_all
      end
    end
  end
end
