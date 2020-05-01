class PurchaseRequestDetail < ActiveRecord::Base
  belongs_to :purchase_request
  belongs_to :product

end
