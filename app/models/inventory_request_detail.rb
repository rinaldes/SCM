class InventoryRequestDetail < ActiveRecord::Base
  belongs_to :inventory_request
  belongs_to :product
  
end
