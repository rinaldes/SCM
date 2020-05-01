class ZfoodDetail < ActiveRecord::Base
  belongs_to :sku
  belongs_to :zfood

  after_create :generate_history

  def generate_history
    origin_product = sku.product
    origin_pd = ProductDetail.where(product_id: sku.product_id, warehouse_id: zfood.product_detail.warehouse_id).first_or_create
    old_qty = ProductMutationHistory.where("product_detail_id=#{origin_pd.id}").limit(1).order("id DESC").last.new_quantity rescue origin_pd.available_qty.to_i
    new_quantity = old_qty.to_i+moved_qty
    product_price = origin_product.product_price Time.now
    begin
      pmh = ProductMutationHistory.new(
        product_detail_id: origin_pd.id, old_quantity: old_qty,
        moved_quantity: moved_qty, new_quantity: new_quantity,
        mutation_type: 'ZFood', quantity_type: 'available_qty',
        price: (product_price.hpp rescue 0), ppn: (product_price.ppn_in rescue 0),
        product_mutation_detail_id: id
      )
      pmh.save
      origin_pd.update_attributes(available_qty: new_quantity)
    rescue
      raise ActiveRecord::Rollback
    end
  end
end
