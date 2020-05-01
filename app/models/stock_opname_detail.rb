class StockOpnameDetail < ActiveRecord::Base
  belongs_to :product
  belongs_to :stock_opname

#  after_create :update_quantity
#  after_create :generate_history

  def generate_history
    product_detail = product.product_details.where(warehouse_id: stock_opname.office_id).first_or_create
    if product_detail.present?
      old_qty = ProductMutationHistory.where("product_detail_id=#{product_detail.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = qty_actual.to_i
      if new_quantity != old_qty
        begin
          pmh = ProductMutationHistory.new(
            product_detail_id: product_detail.id, old_quantity: old_qty,
            moved_quantity: new_quantity-old_qty, new_quantity: new_quantity,
            product_mutation_detail_id: id, quantity_type: 'available_qty',
            ref_code: (stock_opname.opname_number rescue '-'),
            mutation_type: 'Stock Opname', price: hpp*diff,
            ppn: (hpp*0.1 rescue 0)*diff, created_at: updated_at
          )
          pmh.save
          product_detail.update_attributes(available_qty: new_quantity)
        rescue
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  def diff
    qty_actual.to_i - qty_virtual.to_i
  end

  def update_quantity
    product_detail = product_size.product_details.find_by_warehouse_id(stock_opname.branch_id)
    if product_detail.present? && qty_actual.present?
      product_price = product.product_price
      ProductMutation.create product_detail_id: product_detail.id, old_quantity: product_detail.available_qty, moved_quantity: product_detail.available_qty-qty_actual,
        new_quantity: qty_actual, mutation_type: 'Stock Opname', mutation_id: id, quantity_type: 'available_qty', price: product_price.hpp*quantity, ppn: product_price.ppn*quantity
      product_detail.update_attributes(available_qty: qty_actual)
    else
      self.destroy
    end
  end

  def self.to_csv(so_id, options={})
    so = StockOpname.find_by_id(so_id)
    CSV.generate(options) do |csv|
      csv << ['barcode', "sku", 'name', "store", "warehouse"]
      so.stock_opname_details.each.each do |sod|
        product = sod.product
        csv << [product.barcode, product.article, product.description]
      end
    end
  end

  def self.to_csv2(so_id, options = {})
    CSV.generate(options) do |csv|
      csv << ['barcode', "sku", 'name', "store", "warehouse"]
      Product.joins(:stock_opname_details).where("stock_opname_details.stock_opname_id = #{so_id}").each do |product|
        csv << [product.barcode, product.article, product.description]
      end
    end
  end

  def self.import(file, opname_id)
    row_count = 1
    stock_opname = StockOpname.find(opname_id)
    present_ids = []
    total_qty = 0
    CSV.foreach(file.path, headers: true, :encoding => 'ISO-8859-1') do |row|
      params = ActionController::Parameters.new(row.to_hash)
      product_id = params[:barcode].present? ? (Product.find_by_barcode(params[:barcode]).id rescue (Product.find_by_article(params[:sku]).id rescue nil)) : (Product.find_by_article(params[:sku]).id rescue nil)
      next if product_id.blank?

      mutation_out_conditions = ["origin_warehouse_id=#{stock_opname.office_id} AND type='GoodTransfer' AND product_id=#{product_id}"]
      mutation_out_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      return_to_ho_conditions = ["origin_warehouse_id=#{stock_opname.office_id} AND type='ReturnsToHo' AND product_id=#{product_id}"]
      return_to_ho_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      mutation_in_conditions = ["destination_warehouse_id=#{stock_opname.office_id} AND status='#{ProductMutation::RECEIVED}' AND type='GoodTransfer' AND product_id=#{product_id}"]
      mutation_in_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      sold_conditions = ["store_id=#{stock_opname.office_id} AND sales.status='FINISHED' AND product_id=#{product_id}"]
      sold_conditions << "sales.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      receive_transfer_conditions = ["destination_warehouse_id=#{stock_opname.office_id} AND status='#{ProductMutation::RECEIVED}' AND type='PurchaseTransfer' AND product_id=#{product_id}"]
      receive_transfer_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      receiving_conditions = ["head_office_id=#{stock_opname.office_id} AND product_id=#{product_id}"]
      receiving_conditions << "receivings.created_at > '#{stock_opname.start_date}'" if stock_opname.present?
      received_total = ReceivingDetail.where(receiving_conditions.join(' AND ')).joins(:receiving).map(&:calculated_qty).compact.sum

      product_detail = ProductDetail.where("warehouse_id=#{stock_opname.office_id} AND product_id=#{product_id}")
        .select("available_qty AS qty")

      stock_opname_detail = stock_opname.stock_opname_details.where(product_id: product_id).first_or_create
      if (params[:store].present? || params[:warehouse].present?)
        store_dan_warehouse = "store:" + params[:store].to_i.to_s + ", warehouse:" + params[:warehouse].to_i.to_s
        actual_qty = params[:store].to_i + params[:warehouse].to_i
      end
      stock_opname_detail.update_attributes(sold: SalesDetail.where(sold_conditions.join(' AND ')).joins(:sale).map(&:quantity).compact.sum,
        explanation: (store_dan_warehouse rescue ''),
        qty_actual: (actual_qty.nil? ? params[:quantity] : actual_qty),
        received_from_transfer: received_total,
        mutation_in: ProductMutationDetail.where(mutation_in_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
        mutation_out: ProductMutationDetail.where(mutation_out_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
        qty_virtual: product_detail.map(&:qty).compact.sum, retur: ProductMutationDetail.where(return_to_ho_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum)
      total_qty += params[:quantity].to_i
      present_ids << product_id
    end
    stock_opname.stock_opname_details.where("product_id NOT IN (#{present_ids.join(',')})").each{|sod|
      product_id = sod.product_id
      next if product_id.blank?

      mutation_out_conditions = ["origin_warehouse_id=#{stock_opname.office_id} AND type='GoodTransfer' AND product_id=#{product_id}"]
      mutation_out_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      return_to_ho_conditions = ["origin_warehouse_id=#{stock_opname.office_id} AND type='ReturnsToHo' AND product_id=#{product_id}"]
      return_to_ho_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      mutation_in_conditions = ["destination_warehouse_id=#{stock_opname.office_id} AND status='#{ProductMutation::RECEIVED}' AND type='GoodTransfer' AND product_id=#{product_id}"]
      mutation_in_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      sold_conditions = ["store_id=#{stock_opname.office_id} AND sales.status='FINISHED' AND product_id=#{product_id}"]
      sold_conditions << "sales.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      receive_transfer_conditions = ["destination_warehouse_id=#{stock_opname.office_id} AND status='#{ProductMutation::RECEIVED}' AND type='PurchaseTransfer' AND product_id=#{product_id}"]
      receive_transfer_conditions << "product_mutations.created_at > '#{stock_opname.start_date}'" if stock_opname.present?

      receiving_conditions = ["head_office_id=#{stock_opname.office_id} AND product_id=#{product_id}"]
      receiving_conditions << "receivings.created_at > '#{stock_opname.start_date}'" if stock_opname.present?
      received_total = ReceivingDetail.where(receiving_conditions.join(' AND ')).joins(:receiving).map(&:calculated_qty).compact.sum

      product_detail = ProductDetail.where("warehouse_id=#{stock_opname.office_id} AND product_id=#{product_id}")
        .select("available_qty AS qty")

      stock_opname_detail = stock_opname.stock_opname_details.where(product_id: product_id).first_or_create

      stock_opname_detail.update_attributes(qty_actual: 0, sold: SalesDetail.where(sold_conditions.join(' AND ')).joins(:sale).map(&:quantity).compact.sum,
        received_from_transfer: received_total,
        mutation_in: ProductMutationDetail.where(mutation_in_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
        mutation_out: ProductMutationDetail.where(mutation_out_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
        qty_virtual: product_detail.map(&:qty).compact.sum, retur: ProductMutationDetail.where(return_to_ho_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum)
      total_qty += 0
    }
    stock_opname.update_attributes(actual_stock: total_qty)
    return 'Successfully imported'
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.get_stock_movement(date_start, date_end)
    stock_opname_details = StockOpnameDetail.select("'Stock Opname' as flag, product_id, products.code, stock_opnames.opname_number as noref_dc_bkl, stock_opname_details.qty_actual as qty, stock_opname_details.price as hargasatuan,
stock_opname_details.price * stock_opname_details.qty_actual as totalharga, stock_opname_details.pajak, suppliers.name, stock_opname_details.created_at, offices.code as kodetoko").joins("left join products on stock_opname_details.product_id = products.id left join stock_opnames on stock_opname_details.stock_opname_id = stock_opnames.id left join suppliers on stock_opnames.supplier_id = suppliers.id left join offices on stock_opnames.office_id = offices.id")
    result = date_start.present? ? stock_opname_details.where("stock_opname_details.created_at between ? and ?", date_start, date_end) : stock_opname_details
    return result
  end

end
