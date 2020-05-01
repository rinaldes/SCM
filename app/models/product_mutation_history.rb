class ProductMutationHistory < ActiveRecord::Base
  belongs_to :product_detail
  belongs_to :product_mutation_detail

  def self.api(params)
    ActiveSupport::JSON.decode(params).each do |d|
      mutation_history = self.new()
      mutation_history.product_detail_id = d["product_detail_id"]
      mutation_history.old_quantity = d["old_quantity"]
      mutation_history.moved_quantity = d["moved_quantity"]
      mutation_history.new_quantity = d["new_quantity"]
      mutation_history.mutation_type = d["mutation_type"]
      mutation_history.quantity_type = d["quantity_type"]
      mutation_history.product_mutation_detail_id = d["product_mutation_detail_id"]
      mutation_history.price = d["price"]
      mutation_history.discount = d["discount"]
      mutation_history.ppn = d["ppn"]
      mutation_history.save!
    end
  end

  def clear_data_per_item prod_id
    ReceivingDetail.where("article='161534'").joins(:product).map(&:receiving).delete_all
    ReceivingDetail.where("article='161534'").joins(:product).delete_all

    PurchaseDetail.where("article='161534'").joins(:product).map(&:purchase_order).delete_all
    PurchaseDetail.where("article='161534'").joins(:product).delete_all

    ProductDetail.where("article='161534'").joins(:product).delete_all
    Product.find_by_article('161534').delete
  end

  def self.regenerate_mutation_history
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE product_mutation_histories RESTART IDENTITY")
    (SalesDetail.select("*, sales_details.created_at AS created_at, 'Sales' AS mutation_type").joins(:product)+ReceivingDetail.select("*, receiving_details.created_at AS created_at, 'Receiving' AS mutation_type").joins(:receiving).joins(:product)+ProductMutationDetail.select("*, product_mutation_details.created_at AS created_at, 'Good Transfer' AS mutation_type, product_mutations.status").joins(:product_mutation).joins(:product)+ReturnsToSupplierDetail.select("*, returns_to_supplier_details.created_at AS created_at, 'Return To Supplier' AS mutation_type").joins(:product)+StockOpnameDetail.select("*, stock_opname_details.created_at AS created_at, 'Stock Opname' AS mutation_type")+ZfoodDetail.select("*, zfood_details.created_at AS created_at, 'Zfood' AS mutation_type").joins(sku: :product)).sort_by(&:created_at).each{|mutation|
      mutation.generate_history
      mutation.product_received_by_destination_branch if mutation.mutation_type == 'Good Transfer' && mutation.status == 'RECEIVED'
    }
  end

  def self.regenerate_mutation_history_per_item_if_blank
    Product.all.each{|a|
      ProductMutationHistory.regenerate_mutation_history_per_item(a.id) if ProductMutationHistory.where("product_id=#{a.id}").joins(:product_detail).blank?
    }
  end
=begin
StockOpnameDetail.where("stock_opname_id=7").each{|a|
  ProductMutationHistory.regenerate_mutation_history_per_item(a.product_id)
}
=end
  def self.regenerate_mutation_history_per_item(prod_id)
    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE product_mutation_histories RESTART IDENTITY")
#tawon
#    prod_id = 3541
    ProductMutationHistory.where("product_id=#{prod_id}").joins(product_detail: :product).delete_all
    sales = SalesDetail.select("*, sales_details.created_at AS created_at, 'Sales' AS mutation_type").joins(:product).where("product_id=#{prod_id}")
    gr = ReceivingDetail.select("*, receiving_details.created_at AS created_at, 'Receiving' AS mutation_type").joins(:receiving).joins(:product).where("product_id=#{prod_id}")
    tat = ProductMutationDetail.select("*, product_mutation_details.created_at AS created_at, 'Good Transfer' AS mutation_type, product_mutations.status").joins(:product_mutation).joins(:product)
      .where("product_id=#{prod_id}")
    rts = ReturnsToSupplierDetail.select("*, returns_to_supplier_details.created_at AS created_at, 'Return To Supplier' AS mutation_type").joins(:product).where("product_id=#{prod_id}")
    so = StockOpnameDetail.select("*, stock_opname_details.created_at AS created_at, 'Stock Opname' AS mutation_type").where("product_id=#{prod_id} AND stock_opnames.status='COMPLETED'").joins(:stock_opname)
    zfood = ZfoodDetail.select("*, zfood_details.created_at AS created_at, 'Zfood' AS mutation_type").joins(sku: :product).where("product_id=#{prod_id}")
    product_price = SellingPrice.select("*, selling_prices.created_at AS created_at, 'Selling Price' AS mutation_type").joins(:product).where("product_id=#{prod_id}")

    (sales + gr + tat + rts + so + zfood + product_price).sort_by(&:created_at).each{|mutation|
      if mutation.mutation_type == 'Selling Price'
      else
        mutation.regenerate_history rescue ''
        mutation.regenerate_mt_when_received_by_destination_branch if mutation.mutation_type == 'Good Transfer' && mutation.status == 'RECEIVED'
      end
    }
  end

  def repair_retur_process
    ReturnsToSupplierDetail.where("returns_to_supplier_id=2").each{|a|
      pmh = ProductMutationHistory.find_by_mutation_type_and_product_mutation_detail_id('Return To Supplier', a.id)
      pmh.delete if pmh.present?
      a.delete if a.present?
      ProductMutationHistory.regenerate_mutation_history_per_item(a.product_id)
    }
    ReturnsToSupplier.find(2).delete
  end
end
