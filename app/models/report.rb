class Report
  include Mongoid::Document
  field :project_id, type: Integer
  field :requests, type: Array
end
