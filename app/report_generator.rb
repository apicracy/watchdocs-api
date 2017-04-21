require 'json-schema'
SCHEMA = JSON.parse(File.open('schemas/report.json').read)

module Watchdocs
  class InvalidJsonError < StandardError; end
  class ReportGenerator
    attr_reader :requests,
                :requests_json,
                :project_id,
                :report_id

    def initialize(requests_json:, project_id:)
      @requests_json = requests_json
      @project_id = project_id
    end

    def call
      parse_json
      validate_schema
      store_requests
      create_background_job
    end

    private

    def parse_json
      @requests = ::JSON.parse(requests_json)
    rescue ::JSON::ParserError => e
      raise Watchdocs::InvalidJsonError, e.message
    end

    def validate_schema
      ::JSON::Validator.validate!(SCHEMA, requests)
    rescue ::JSON::Schema::ValidationError => e
      raise Watchdocs::InvalidJsonError, e.message
    end

    def store_requests
      @report_id = Report.create(
        project_id: project_id,
        requests: requests.to_json
      ).id.to_s
    end

    def create_background_job
      Watchdocs::Worker::ReportExtractorWorker.perform_async(report_id)
    end
  end
end
