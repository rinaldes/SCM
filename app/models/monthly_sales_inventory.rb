class MonthlySalesInventory < ActiveRecord::Base
  belongs_to :office
  belongs_to :product
end
