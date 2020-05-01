class SalePosDb < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(:sale_pos)
end