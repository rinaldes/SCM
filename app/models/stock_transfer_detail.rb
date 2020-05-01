class StockTransferDetail < ActiveRecord::Base
	belongs_to :stock_transfer
	belongs_to :product

  after_create :generate_history

  def generate_history
    product_detail = product.product_details.find_by_warehouse_id(stock_transfer.destination_id)
    if product_detail.present? && quantity.to_i > 0
      old_qty = product_detail.available_qty
      new_quantity = old_qty.to_i-quantity.to_i
      product_price = product.product_price created_at
			begin
				pmh = ProductMutationHistory.new(
	        product_detail_id: product_detail.id, old_quantity: old_qty,
	        moved_quantity: quantity, new_quantity: new_quantity,
	        product_mutation_detail_id: id, quantity_type: 'available_qty',
	        mutation_type: 'Inventory Issue', ref_code: (stock_transfer.number rescue '-'),
	        price: (product_price.hpp*quantity rescue 0),
	        ppn: (product_price.ppn_in*quantity rescue 0), created_at: created_at
	      )
	      pmh.save
	      product_detail.update_attributes(available_qty: new_quantity)
	      return pmh
			rescue
				raise ActiveRecord::Rollback
			end
    end
  end

  def regenerate_history
    product_detail = product.product_details.find_by_warehouse_id(stock_transfer.destination_id)
    if product_detail.present? && quantity.to_i > 0
      old_qty = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = old_qty.to_i-quantity.to_i
      product_price = product.product_price created_at
      pmh = ProductMutationHistory.new(
				product_detail_id: product_detail.id, old_quantity: old_qty,
				moved_quantity: quantity, new_quantity: new_quantity,
				product_mutation_detail_id: id, quantity_type: 'available_qty',
				mutation_type: 'Inventory Issue',
				price: (product_price.hpp*quantity rescue 0),
				ppn: (product_price.ppn_in*quantity rescue 0)
				)
      pmh.save
      product_detail.update_attributes(available_qty: new_quantity)
      return pmh
    end
  end

end
