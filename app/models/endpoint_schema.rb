class EndpointSchema
  include Mongoid::Document
  field :project_id, type: Integer
  field :endpoint, type: String
  field :method, type: String
  field :status, type: Integer
  field :request, type: String
  field :response, type: String
  field :query_string_params, type: String
  field :response_headers, type: String
  field :request_headers, type: String
end
