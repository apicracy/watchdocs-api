require 'json-schema'
SCHEMA = JSON.parse(File.open('schema.json').read)

module Watchdocs
  class InvalidJsonError < StandardError; end
  class ReportGenerator
    attr_reader :requests,
                :requests_json,
                :project_id

    def initialize(requests_json:, project_id:)
      @requests_json = requests_json
      @project_id = project_id
    end

    def call
      parse_json
      validate_schema
      store_requests
      # create_background_job
    end

    private

    def parse_json
      @requests = JSON.parse(requests_json)
    rescue JSON::ParserError => e
      raise Watchdocs::InvalidJsonError, e.message
    end

    def validate_schema
      JSON::Validator.validate!(SCHEMA, requests)
    rescue JSON::Schema::ValidationError => e
      raise Watchdocs::InvalidJsonError, e.message
    end

    def store_requests
      endpoints = requests.group_by { |request| request['endpoint'] }
      endpoints.each do |endpoint, requests|
        Report.create(
          project_id: project_id,
          endpoint: endpoint,
          created_at: Time.now,
          requests: requests
        )
      end
    end

    # def create_background_job
    #   Watchdocs::SchemaGenerator.new(
    #     project_id: params['id']),
    #     endpoints: endpoints.keys
    #   ).call
    # end
  end
end
