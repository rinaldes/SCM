class ReturnsToSupplierDetail < ActiveRecord::Base
  after_create :generate_history

  belongs_to :product
  belongs_to :returns_to_supplier

#  after_destroy :customize_stock

  def customize_stock
    product_detail = product_size.product_details.find_by_warehouse_id(returns_to_supplier.head_office_id)
    if product_detail.present? && quantity.to_i > 0
      old_qty = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = old_qty.to_i-quantity.to_i
      product_price = product.product_price
      ProductMutationHistory.create product_detail_id: product_detail.id, old_quantity: old_qty, moved_quantity: quantity, new_quantity: new_quantity,
        product_mutation_detail_id: id, quantity_type: 'available_qty', mutation_type: 'Return To Supplier', price: product_price.hpp*quantity, ppn: product_price.ppn*quantity
      product_detail.update_attributes(available_qty: new_quantity)
    end
  end

  def generate_history
    product_detail = product.product_details.find_by_warehouse_id(returns_to_supplier.head_office_id)
    if product_detail.present? && quantity.to_i > 0
      old_qty = product_detail.available_qty.to_f
      new_quantity = old_qty.to_i-quantity.to_i
      product_price = product.product_price Time.now
      begin
        pmh = ProductMutationHistory.new(
          product_detail_id: product_detail.id, old_quantity: old_qty,
          moved_quantity: quantity, new_quantity: new_quantity,
          product_mutation_detail_id: id, quantity_type: 'available_qty',
          ref_code: returns_to_supplier.number,
          mutation_type: 'Return To Supplier',
          price: product_price.hpp.to_f*quantity.to_f,
          ppn: product_price.ppn_in.to_f*quantity.to_f,
          created_at: created_at
        )
        pmh.save
        product_detail.update_attributes(available_qty: new_quantity)
      rescue
        raise ActiveRecord::Rollback
      end
    end
  end

  def regenerate_history
    product_detail = product.product_details.find_by_warehouse_id(returns_to_supplier.head_office_id)
    if product_detail.present? && quantity.to_i > 0
      old_qty = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = old_qty.to_i-quantity.to_i
      product_price = product.product_price Time.now
      ProductMutationHistory.create product_detail_id: product_detail.id, old_quantity: old_qty, moved_quantity: quantity, new_quantity: new_quantity,
        product_mutation_detail_id: id, quantity_type: 'available_qty', mutation_type: 'Return To Supplier', price: product_price.hpp.to_f*quantity.to_f, ppn: product_price.ppn_in.to_f*quantity.to_f,
        created_at: created_at
      product_detail.update_attributes(available_qty: new_quantity)
    end
  end

  def self.get_stock_movement(date_start, date_end)
    returns_to_supplier_details = ReturnsToSupplierDetail.select("'Return' as flag, returns_to_supplier_details.product_id, products.code, returns_to_suppliers.number as noref_dc_bkl, returns_to_supplier_details.quantity as qty, returns_to_supplier_details.total/returns_to_supplier_details.quantity as hargasatuan,
returns_to_supplier_details.total as totalharga, returns_to_supplier_details.pajak, suppliers.name, returns_to_supplier_details.created_at, offices.code as kodetoko").joins("left join products on returns_to_supplier_details.product_id = products.id left join returns_to_suppliers on returns_to_supplier_details.returns_to_supplier_id = returns_to_suppliers.id left join suppliers on returns_to_suppliers.supplier_id = suppliers.id left join offices on returns_to_suppliers.head_office_id = offices.id")
        result = date_start.present? ? returns_to_supplier_details.where("returns_to_supplier_details.created_at between ? and ?", date_start, date_end) : returns_to_supplier_details
    return result
  end

  def subtotal
    quantity.to_f*purchase_price.to_f
  end

end
