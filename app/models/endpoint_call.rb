class EndpointCall
  include Mongoid::Document
  field :project_id, type: Integer
  field :call, type: Object
end
