class ProductStock < ActiveRecord::Base
 belongs_to :product_detail
 scope :search, lambda {|search|{
 :order => "code ASC",
 :conditions =>
    ['product_stocks.product_detail_id LIKE ? OR product_stocks.stock LIKE ? OR product_stocks.stock_type LIKE ?', "%#{search.first}%", "%#{search.first}%", "%#{search.first}%"],
    #joins: "JOIN suppliers ON brands.supplier_id = suppliers.id", :order => "code ASC"
  }}    
  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["product detail id", "stock", "stock type"]
      all.each do |product_stock|
        csv << [product_stock.product_detail_id, product_stock.stock, product_stock.stock_type]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["product detail id"]  
      all.each do |product_stock|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_product_detail_id(row["product detail id"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        product_stock = new(parameters.permit(:product_detail_id, :stock, :stock_type))
        unless product_stock.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{product_stock.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{product_stock.errors.full_messages.join('<br/>')}"}
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
