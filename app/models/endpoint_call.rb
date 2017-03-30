class EndpointCall
  include Mongoid::Document
  field :project_id, type: Integer
  field :endpoint, type: String
  field :status, type: Integer
  field :call, type: String
end
