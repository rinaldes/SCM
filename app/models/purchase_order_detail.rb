class PurchaseOrderDetail < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :product

  validates :quantity, presence: true
  validates :product_id, presence: true
  validates :hpp, presence: true
#  validates_uniqueness_of :product_id, :scope => :purchase_order_id

  def subtotal
    quantity*hpp*(fraction || 1) rescue 0
  end

  def calculated_qty
    return quantity if unit_type == 'Unit'
    if unit_type == 'Box'
      product.box_num.to_i*quantity
    else
      product.box2_num.to_i*quantity
    end
  end
end
