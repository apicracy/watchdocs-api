require './app/models/project'
require 'json-schema'
PROJECT_SCHEMA = JSON.parse(File.open('schemas/project.json').read)

module Watchdocs
  class InvalidJsonError < StandardError; end
  class ProjectCreator
    attr_reader :json_data,
                :project_data

    def initialize(json_data)
      @json_data = json_data
    end

    def call
      parse_json
      validate_schema
      store_project
    end

    private

    def parse_json
      @project_data = ::JSON.parse(json_data)
    rescue ::JSON::ParserError => e
      raise Watchdocs::InvalidJsonError, e.message
    end

    def validate_schema
      ::JSON::Validator.validate!(PROJECT_SCHEMA, project_data)
    rescue ::JSON::Schema::ValidationError => e
      raise Watchdocs::InvalidJsonError, e.message
    end

    def store_project
      Project.create!(
        app_id: project_data['app_id'],
        app_secret: project_data['app_secret']
      )
    end
  end
end
