class DataCenterDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(:data_center)
end
