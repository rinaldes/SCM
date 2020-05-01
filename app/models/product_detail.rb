class ProductDetail < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_size
  belongs_to :warehouse, class_name: 'Office', foreign_key: 'warehouse_id'
  has_many :product_stock
  has_many :product_mutation_histories
  has_one :plano
  before_save :set_warehouse

  validates_format_of :min_stock, :with => /^[0-9\s]*$/i, :multiline => true, :message => "masukkan bilangan bulat saja"

  CATALOG = 1
  NON_CATALOG = 2
  ONLINE = 3

  def set_warehouse
    #self.warehouse_id = HeadOffice.first.id if self.warehouse_id.blank?
  end

  def po_stock
    max_stock.to_i-available_qty.to_i
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["no","article","minimal_order","rop_stock","max_stock","store"]
      all.each do |colour|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      prod = Product.find_by_article(row["article"])
      ware = Office.find_by_code(row["store"])
      prod_id = prod.id unless prod.nil?
      war_id = ware.id unless ware.nil?
      if ProductDetail.find_by_product_id_and_warehouse_id(prod_id, war_id).present?
        prod_d = ProductDetail.find_by_product_id_and_warehouse_id(prod_id, war_id).update_attributes(min_stock: row["minimal_order"], rop_stock: row["rop_stock"], max_stock: row["max_stock"])
        unless prod_d
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{prod_d.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{prod_d.errors.full_messages.join('<br/>')}"}
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
