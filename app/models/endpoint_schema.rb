class EndpointSchema
  include Mongoid::Document
  field :project_id, type: Integer
  field :endpoint, type: String
  field :status, type: Integer
  field :request, type: String
  field :response, type: String
end
