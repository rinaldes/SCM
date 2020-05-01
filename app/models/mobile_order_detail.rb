class MobileOrderDetail < ActiveRecord::Base
  belongs_to :product
  belongs_to :mobile_order
end