require 'httparty'

module Watchdocs
  module SchemaExporter
    class ConfigurationError < StandardError; end
    class WatchdocsApiError < StandardError; end

    DEFAULT_ERROR = 'Unknown API Error occured.'.freeze

    class << self
      def export(endpoint_schema)
        unless api_url.present?
          raise ConfigurationError,
                'Watchdocs-backend export url not defined. Define in EXPORT_URL.'
        end
        response = HTTParty.post(
          api_url,
          body: payload(endpoint_schema),
          headers: { 'Content-Type' => 'application/json' },
          basic_auth: api_auth
        )
        check_response(response)
      end

      private

      def payload(endpoint_schema)
        payload = {
          app_id: endpoint_schema.project_id,
          endpoint: {
            url: endpoint_schema.endpoint,
            method: endpoint_schema.method
          },
          response: {
            status: endpoint_schema.status,
            headers: parse_json(endpoint_schema.response_headers),
            body: parse_json(endpoint_schema.response)
          }
        }
        if endpoint_schema.status.to_s =~ /^2/
          payload[:request] = {
            url_params: parse_json(endpoint_schema.query_string_params),
            headers: parse_json(endpoint_schema.request_headers),
            body: parse_json(endpoint_schema.request)
          }
        end
        to_json_api(payload)
      end

      def to_json_api(attributes)
        {
          data: {
            type: 'endpoint_schemas',
            attributes: attributes
          }
        }.to_json
      end

      def parse_json(json)
        ::JSON.parse(json)
      rescue ::JSON::ParserError => e
        {}
      end

      def check_response(response)
        case response.code.to_s.chars.first
        when '2'
          true
        when '4', '5'
          raise WatchdocsApiError, get_error(response.body)
        else
          raise WatchdocsApiError, DEFAULT_ERROR
        end
      end

      def get_error(response_body)
        JSON.parse(response_body)['errors'].join(', ')
      rescue
        DEFAULT_ERROR
      end

      def api_url
        ENV['EXPORT_URL']
      end

      def api_auth
        {
          username: ENV['EXPORT_AUTH_USERNAME'],
          password: ENV['EXPORT_AUTH_PASSWORD']
        }
      end
    end
  end
end
