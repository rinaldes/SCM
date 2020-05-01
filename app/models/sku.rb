class Sku < ActiveRecord::Base
  belongs_to :product
  belongs_to :unit

#  after_save :generate_product_details

  def generate_product_details
    Office.all.each{|office|
      ProductDetail.where(product_id: product.id, warehouse_id: office.id, sku_id: id).first_or_create
    }
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["product", "unit", "barcode", "convertion_unit"]
      all.each do |sku|
        csv << [sku.product.description, sku.unit.name, sku.barcode, sku.convertion_unit]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["product", "unit", "barcode", "convertion_unit"]
      all.each do |sku|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_name(row["name"].upcase).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        product_id = Product.find_by_description(row["product"]).id
        unit_id = Unit.find_by_name(row["unit"]).id
        sku = new(parameters.permit(:barcode, :convertion_unit).merge(:product_id => product_id, :unit_id => unit_id ))
        unless sku.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{sku.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{sku.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported"}
      end
    end
    return {error: 0, message: "Successfully imported"}
  end
end