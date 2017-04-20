class EndpointSchema
  include Mongoid::Document
  field :project_id, type: String
  field :endpoint, type: String
  field :method, type: String
  field :status, type: Integer
  field :request, type: String
  field :response, type: String
  field :query_string_params, type: String
  field :response_headers, type: String
  field :request_headers, type: String

  class << self
    def aggregation_pipeline(project_id)
      match = {
        '$match' => {
          'project_id' => project_id
        }
      }
      group = {
        '$group' => {
          '_id' => {
            'endpoint' => '$endpoint',
            'method' => '$method',
            'status' => '$status'
          },
          'request' => {
            '$last' => '$request'
          },
          'response' => {
            '$last' => '$response'
          },
          'query_string_params' => {
            '$last' => '$query_string_params'
          },
          'response_headers' => {
            '$last' => '$response_headers'
          },
          'request_headers' => {
            '$last' => '$request_headers'
          }
        }
      }
      sort = {
        '$sort' => {
          'endpoint' => 1
        }
      }
      [match, group, sort]
    end
  end
end
