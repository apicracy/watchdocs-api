class Report
  include Mongoid::Document
  field :project_id, type: String
  field :requests, type: String
end
