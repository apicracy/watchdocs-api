class EndpointCall
  include Mongoid::Document
  field :project_id, type: String
  field :endpoint, type: String
  field :method, type: String
  field :status, type: Integer
  field :call, type: String
end
