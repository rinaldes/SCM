class StockTransfer < ActiveRecord::Base
  has_many :stock_transfer_details, dependent: :destroy

  belongs_to :user
  belongs_to :product
  belongs_to :origin, :class_name => "Office"
  belongs_to :location
  belongs_to :destination, :class_name => "Office"

  after_destroy :restore_quantity

  # validate :check_stock, on: :create

  # validates :origin_id, presence: true
  # validates :destination_id, presence: true
  # validates :origin_stock, presence: true
  # validates :destination_stock, presence: true

  accepts_nested_attributes_for :stock_transfer_details, :reject_if => :all_blank, :allow_destroy => true

  def check_stock
    stock_transfer_details.each{|p|
      errors.add(:quantity, "of #{p.product.description} can't be more than available quantity") if p.quantity.to_i > (ProductDetail.find_by_warehouse_id_and_product_id(destination_id, p.product_id).available_qty.to_i rescue 0)
    }
  end

  def restore_quantity
    stock_transfer_details.each{|pmd|
      origin = ProductDetail.find_by_warehouse_id_and_product_size_id(origin_id, pmd.product_detail_id)
      origin_stock_qty = "#{origin_stock.downcase}_qty"
      destination_qty = "#{destination_stock.downcase}_qty"
      tobe_updated = {origin_stock_qty => (eval("origin.#{origin_stock_qty}.to_i") + pmd.quantity)}
      ProductMutationHistory.where(product_detail_id: origin.id, mutation_type: 'Stock Transfer', product_mutation_detail_id: pmd.id, quantity_type: origin_stock_qty).delete_all
      unless destination_stock == 'Scrap'
        ProductMutationHistory.where(product_detail_id: origin.id, mutation_type: 'Stock Transfer', product_mutation_detail_id: pmd.id, quantity_type: destination_qty).delete_all
        tobe_updated = tobe_updated.merge("#{destination_stock.downcase}_qty" => (eval("origin.#{destination_stock.downcase}_qty.to_i") - pmd.quantity))
      end
      origin.update(tobe_updated)
    }
  end

  def generate_details(params)
    params[:stock_transfer][:stock_mutation_details_attributes].each do |detail|
        if detail[1]["quantity"].present? && detail[1]["quantity"].to_i != 0
          stock_transfer_detail = self.stock_transfer_details.new(
            product_detail_id: detail[1]["product_size_id"], size_detail_id: detail[1]["size_detail_id"], quantity: detail[1]["quantity"]
          )
          stock_transfer_detail.save
          if stock_transfer_detail
            origin = ProductDetail.find_by_product_size_id_and_warehouse_id(detail[1]["product_size_id"], params[:stock_transfer][:branch_id])
            ProductMutationHistory.create product_detail_id: origin.id, old_quantity: eval("origin.#{origin_stock.downcase}_qty.to_i"), moved_quantity: detail[1]["quantity"].to_i,
              new_quantity: eval("origin.#{origin_stock.downcase}_qty.to_i") - detail[1]["quantity"].to_i, mutation_type: 'Stock Transfer',
              product_mutation_detail_id: stock_transfer_detail.id, quantity_type: "#{origin_stock.downcase}_qty"
            tobe_updated = {"#{origin_stock.downcase}_qty" => (eval("origin.#{origin_stock.downcase}_qty.to_i") - detail[1]["quantity"].to_i)}
            unless destination_stock == 'Scrap'
              ProductMutationHistory.create product_detail_id: origin.id, old_quantity: eval("origin.#{destination_stock.downcase}_qty.to_i"),
                moved_quantity: detail[1]["quantity"].to_i, new_quantity: eval("origin.#{destination_stock.downcase}_qty.to_i") + detail[1]["quantity"].to_i,
                mutation_type: 'Stock Transfer', product_mutation_detail_id: stock_transfer_detail.id, quantity_type: "#{destination_stock.downcase}_qty"
              tobe_updated = tobe_updated.merge("#{destination_stock.downcase}_qty" => (eval("origin.#{destination_stock.downcase}_qty.to_i") + detail[1]["quantity"].to_i))
            end
            origin.update(tobe_updated)
          end
        end
      end
  end
end
