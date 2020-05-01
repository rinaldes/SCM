class ReceivingDetail < ActiveRecord::Base
  belongs_to :receiving
  belongs_to :product
  belongs_to :product_size

  after_create :generate_history
  after_create :generate_total_price

#  validates_uniqueness_of :product_id, :scope => :receiving_id
  validate :hpp_selling_price
  validate :fraction, presence: true

  def hpp_selling_price
    errors.add(:hpp, "should be greater than 0") if hpp.to_f == 0
  end

  def calculated_qty
    ((quantity || 0) rescue 0)*(fraction || 1)
  end

  def update_total_price
    self.update_attributes(total_price: calculated_qty.to_i*hpp.to_i)
  end

  def subtotal
    quantity.to_f*hpp.to_f*(fraction || 1)
  end

  def generate_history
    product_detail = ProductDetail.where(warehouse_id: receiving.head_office_id, product_id: product_id).first_or_create
    pod = PurchaseOrderDetail.find_by_product_id_and_purchase_order_id(product_id, receiving.purchase_order_id)
    moved_quantity = calculated_qty
    update_total_price
    if product_detail.present? && quantity.to_i > 0
      old_qty = product_detail.available_qty.to_f
      new_quantity = old_qty.to_i+moved_quantity
      product_price = hpp
      ppn = receiving.supplier.status_pkp && product_detail.product.is_bkp? ? (product_price.ppn_in.to_f rescue 0)*quantity : 0
      begin
        pmh = ProductMutationHistory.new(
          product_detail_id: product_detail.id, old_quantity: old_qty,
          moved_quantity: moved_quantity, new_quantity: new_quantity,
          created_at: created_at, product_mutation_detail_id: id,
          quantity_type: 'available_qty', mutation_type: 'Receiving',
          ref_code: (receiving.number rescue '-'), price: hpp*quantity, ppn: ppn,
          cost: hpp, last_cost: hpp,
          avg_cost: ((product.product_price(created_at).hpp_average rescue hpp)*old_qty+quantity*hpp)/(quantity+old_qty)
        )
        pmh.save
        product_detail.update_attributes(available_qty: new_quantity)
      rescue
        raise ActiveRecord::Rollback
      end
    end
  end

  def regenerate_history
    product_detail = ProductDetail.where(warehouse_id: receiving.head_office_id, product_id: product_id).first_or_create
    pod = PurchaseOrderDetail.find_by_product_id_and_purchase_order_id(product_id, receiving.purchase_order_id)
    moved_quantity = calculated_qty
    update_total_price
    if product_detail.present? && quantity.to_i > 0
      prev_hst = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last
      old_qty = prev_hst.new_quantity rescue 0
      new_quantity = old_qty.to_i+moved_quantity
      product_price = hpp
      ppn = receiving.supplier.status_pkp && product_detail.product.is_bkp? ? (product_price.ppn_in.to_f rescue 0)*quantity : 0
      ProductMutationHistory.create(
        product_detail_id: product_detail.id, old_quantity: old_qty,
        moved_quantity: moved_quantity, new_quantity: new_quantity,
        created_at: created_at, product_mutation_detail_id: id,
        quantity_type: 'available_qty', mutation_type: 'Receiving',
        price: hpp*quantity, ppn: ppn, cost: hpp,
        last_cost: hpp, ref_code: (receiving.number rescue '-'),
        avg_cost: (product.product_price(created_at).hpp_average*old_qty+quantity*hpp)/(quantity+old_qty)
      )
      product_detail.update_attributes(available_qty: new_quantity)
    end
  end

  def generate_total_price
    self.update_attributes(total_price: calculated_qty*(product_size.product.purchase_price.to_f rescue 0))
  end

  def self.get_stock_movement(date_start, date_end)
    receiving_details = ReceivingDetail.select("'Receive' as flag, receiving_details.product_id, products.code, receivings.number as noref_dc_bkl, receiving_details.quantity as qty, receiving_details.total_price/receiving_details.quantity as hargasatuan,
receiving_details.total_price as totalharga, receiving_details.pajak, suppliers.name, receiving_details.created_at, offices.code as kodetoko").joins("left join products on receiving_details.product_id = products.id left join receivings on receiving_details.receiving_id = receivings.id left join suppliers on receivings.supplier_id = suppliers.id left join offices on receivings.head_office_id = offices.id")
    result = date_start.present? ? receiving_details.where("receiving_details.created_at between ? and ?", date_start, date_end) : receiving_details
    return result
  end
end
