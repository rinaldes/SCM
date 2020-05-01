class ProductMutationDetail < ActiveRecord::Base
  after_create :generate_history

  belongs_to :product
  belongs_to :product_mutation

  def generate_history
    product_detail = product.product_details.find_by_warehouse_id(product_mutation.origin_warehouse_id)
    if product_detail.present? && quantity.to_i > 0
      old_qty = product_detail.available_qty
      new_quantity = old_qty.to_i-quantity.to_i
      product_price = product.product_price created_at
      begin
        pmh = ProductMutationHistory.new(
          product_detail_id: product_detail.id, old_quantity: old_qty,
          moved_quantity: quantity, new_quantity: new_quantity,
          ref_code: (product_mutation.code rescue '-'),
          product_mutation_detail_id: id, quantity_type: 'available_qty',
          mutation_type: product_mutation.class.to_s.titleize,
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
    product_detail = product.product_details.find_by_warehouse_id(product_mutation.origin_warehouse_id)
    if product_detail.present? && quantity.to_i > 0
      old_qty = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = old_qty.to_i-quantity.to_i
      product_price = product.product_price created_at
      pmh = ProductMutationHistory.new product_detail_id: product_detail.id, old_quantity: old_qty, moved_quantity: quantity, new_quantity: new_quantity, product_mutation_detail_id: id,
        quantity_type: 'available_qty', mutation_type: product_mutation.class.to_s.titleize, price: (product_price.hpp*quantity rescue 0), ppn: (product_price.ppn_in*quantity rescue 0), created_at: created_at
      pmh.save
      product_detail.update_attributes(available_qty: new_quantity)
      return pmh
    end
  end

  def hpp
    begin
      SellingPrice.where("start_date<'#{created_at.to_date.strftime('%Y-%m-%d')}' AND product_id=#{product_id} AND office_id=#{product_mutation.origin_warehouse_id}").last.hpp_average
    rescue
      SellingPrice.where("start_date<'#{created_at.to_date.strftime('%Y-%m-%d')}' AND product_id=#{product_id}").last.hpp_average rescue 0
    end
  end

  def product_received_by_destination_branch
    product_detail = ProductDetail.where(warehouse_id: product_mutation.destination_warehouse_id, product_id: product_id).first_or_create
    if product_detail.present? && quantity.to_i > 0
      old_qty = product_detail.available_qty.to_f
      new_quantity = old_qty.to_i+quantity.to_i
      product_price = product.product_price created_at
      pmh = ProductMutationHistory.new(
        product_detail_id: product_detail.id, old_quantity: old_qty,
        moved_quantity: quantity, new_quantity: new_quantity,
        product_mutation_detail_id: id, quantity_type: 'available_qty',
        mutation_type: "#{product_mutation.class.to_s.titleize} Receipt",
        ref_code: product_mutation.code,
        price: (product_price.hpp.to_f rescue 0)*quantity.to_f,
        ppn: (product_price.ppn_in.to_f rescue 0)*quantity.to_f,
        created_at: created_at
      )
      pmh.save
      product_detail.update_attributes(available_qty: new_quantity)
      return pmh
    end
  end

  def regenerate_mt_when_received_by_destination_branch
    product_detail = ProductDetail.where(warehouse_id: product_mutation.destination_warehouse_id, product_id: product_id).first_or_create
    if product_detail.present? && quantity.to_i > 0
      old_qty = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = old_qty.to_i+quantity.to_i
      product_price = product.product_price created_at
      pmh = ProductMutationHistory.new product_detail_id: product_detail.id, old_quantity: old_qty, moved_quantity: quantity, new_quantity: new_quantity, product_mutation_detail_id: id,
        quantity_type: 'available_qty', mutation_type: "#{product_mutation.class.to_s.titleize} Receipt", price: (product_price.hpp.to_f rescue 0)*quantity.to_f,
        ppn: (product_price.ppn_in.to_f rescue 0)*quantity.to_f, created_at: created_at
      pmh.save
      product_detail.update_attributes(available_qty: new_quantity)
      return pmh
    end
  end
end
