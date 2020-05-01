class SalesDetail < ActiveRecord::Base

  attr_accessor :store_id
  belongs_to :product_size
  belongs_to :sale
  belongs_to :product
  belongs_to :sku

#  scope :spg, select(:spg_user_name).uniq

  after_create :generate_history

  # validates :quantity, presence: {message: 'required'}
  # validates :goods_detail_id, presence: {message: 'required'}
  # validates :price, presence: {message: 'required'}
  # validates :price_after_discount, presence: {message: 'required'}
  # validate :check_stock

  def total_per_detail
    quantity * price_after_discount
  end

  def generate_history
    product_detail = ProductDetail.where(warehouse_id: sale.store_id, product_id: product_id).first_or_create
    moved_quantity = quantity.to_i
    if product_detail.present? && quantity.to_i != 0
      old_qty = product_detail.available_qty
      new_quantity = old_qty.to_i-moved_quantity
      begin
        ProductMutationHistory.create product_detail_id: product_detail.id,
          old_quantity: old_qty, moved_quantity: moved_quantity,
          new_quantity: new_quantity, product_mutation_detail_id: id,
          quantity_type: 'available_qty', mutation_type: 'Sales',
          price: capital_price, ppn: ppn, created_at: created_at,
          cost: product.product_price(created_at).hpp_average,
          last_cost: capital_price,
          avg_cost: product.product_price(created_at).hpp_average
        product_detail.update_attributes(available_qty: new_quantity)
      rescue
        raise ActiveRecord::Rollback
      end
    end
  end

  def regenerate_history
    product_detail = ProductDetail.where(warehouse_id: sale.store_id, product_id: product_id).first_or_create
    moved_quantity = quantity.to_i
    if product_detail.present? && quantity.to_i != 0
      old_qty = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = old_qty.to_i-moved_quantity
      begin
        ProductMutationHistory.create product_detail_id: product_detail.id, old_quantity: old_qty, moved_quantity: moved_quantity, new_quantity: new_quantity, product_mutation_detail_id: id,
          quantity_type: 'available_qty', mutation_type: 'Sales', price: capital_price, ppn: ppn,
          created_at: created_at, cost: product.product_price(created_at).hpp_average, last_cost: capital_price,
          avg_cost: product.product_price(created_at).hpp_average
        product_detail.update_attributes(available_qty: new_quantity)
      rescue
      end
    end
  end

  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |sales_detail|
        csv << sales_detail.attributes.values_at(*column_names)
      end
    end
  end

  private

  def check_stock
    self.errors.add(:sales_detail, "stock insufficient") and return false unless (goods_size.goods_details.find_by_store_id(store_id.to_i).quantity rescue 0) > quantity
  end
end
