class EndpointSchema
  include Mongoid::Document
  field :project_id, type: Integer
  field :endpoint, type: String
  field :status, type: Integer
  field :request, type: Object
  field :response, type: Object
end
