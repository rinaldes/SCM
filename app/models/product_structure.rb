class ProductStructure < ActiveRecord::Base
  belongs_to :sku
  belongs_to :product
  belongs_to :parent, class_name: 'Sku', foreign_key: 'parent_id'

  #161351 ABC,WHITE COFFEE 10x27g RCG diconvert ke 161234 RCG ABC,WHITE COFFEE 27g (RENCENG)
  def self.convert origin_product, warehouse, qty
    ps = ProductStructure.find_by_parent_id(origin_product.id)# || ProductStructure.find_by_product_id(origin_product.id)
    if ps.blank?
      ps = ProductStructure.find_by_product_id(origin_product.id)
      origin_pd = ProductDetail.find_by_product_id_and_warehouse_id(ps.parent.product_id, warehouse)
      old_qty = ProductMutationHistory.where("product_detail_id=#{origin_pd.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = origin_pd.available_qty.to_i-1
      origin_pd.update_attributes(available_qty: new_quantity)
      product_price = origin_product.product_price Time.now

      zf = Zfood.new(
        product_detail_id: origin_pd.id,
        code: "PCN#{((sprintf '%03d', ((Zfood.order("id DESC").limit(1).last.code.gsub('PCN', '').to_i rescue 0)+1)))}"
        )
      zf.save
      ZfoodDetail.create sku_id: Sku.find_by_product_id(origin_pd.product_id).id, moved_qty: -1, zfood_id: zf.id

      destination_product = ps.product
      destination_pd = ProductDetail.find_by_product_id_and_warehouse_id(destination_product.id, warehouse)
      old_qty = ProductMutationHistory.where("product_detail_id=#{destination_pd.id}").limit(1).order("id DESC").last.new_quantity rescue destination_pd.available_qty
      new_quantity = old_qty.to_f+ps.quantity.to_f
      product_price = destination_product.product_price Time.now

      ZfoodDetail.create sku_id: Sku.find_by_product_id(destination_pd.product_id).id, moved_qty: ps.quantity, zfood_id: zf.id
    else
      origin_pd = ProductDetail.where(product_id: origin_product.product_id, warehouse_id: warehouse).first_or_create
      old_qty = ProductMutationHistory.where("product_detail_id=#{origin_pd.id}").limit(1).order("id DESC").last.new_quantity rescue 0
      new_quantity = origin_pd.available_qty.to_i+qty
      product_price = origin_product.product.product_price Time.now rescue 0

      zf = Zfood.new(
        product_detail_id: origin_pd.id,
        code: "PCN#{((sprintf '%03d', ((Zfood.order("id DESC").limit(1).last.code.gsub('PCN', '').to_i rescue 0)+1)))}"
        )
      zf.save
      ZfoodDetail.create sku_id: origin_product.id, moved_qty: qty, zfood_id: zf.id

      ProductStructure.where(parent_id: origin_product.id).where("sku_id IS NOT NULL").each{|ps|
        destination_product = ps.sku
        if ps.present? && destination_product.present? && destination_product.product.present?
          destination_pd = ProductDetail.where(product_id: destination_product.product_id, warehouse_id: warehouse).first_or_create
          old_qty = destination_pd.available_qty.to_i
          new_quantity = old_qty.to_i-ps.quantity.to_i*qty
          product_price = destination_product.product.product_price Time.now
          ZfoodDetail.create sku_id: (ps.sku_id), moved_qty: (ps.quantity || 1 rescue 1)*-1*qty, zfood_id: zf.id
        end
      }
    end
  end

  def self.to_csv(product_st, options = {})
    CSV.generate(options) do |csv|
      csv << ["SKU", "Barcode", "Main Product", "Product Constituent", "Category"]
      product_st.each_with_index do |product, i|
        product_s = ProductStructure.find_by_parent_id(Sku.find_by_product_id(product.id).id).id rescue nil
        if product_s.present?
          article = product.article
          barcode = product.barcode || '-'
          description = product.description
           if ProductStructure.joins(sku: :product).where(parent_id: Sku.find_by_product_id(product.id)).present?
            product_constituent = ProductStructure.joins(sku: :product).where(parent_id: Sku.find_by_product_id(product.id)).count
           else
            product_constituent = ProductStructure.where(parent_id: product.id).count
           end
          pc = "Have " + product_constituent.to_s + " Product Constituent"
          m_class = product.m_class_name
          csv << [article, barcode, description, pc, m_class]
        end
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["SKU", "Barcode", "Main Product", "Product Constituent", "Category"]
      all.each do |colour|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_name(row["name"].upcase).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        colour = new(parameters.permit(:name).merge(:code => "C#{('%03d' % ((Colour.last.code.gsub('C', '').to_i rescue 0)+1))}"))
        unless colour.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{colour.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{colour.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported"}
      end
    end
    return {error: 0, message: "Successfully imported"}
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
