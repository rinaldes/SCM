class StockOpname < ActiveRecord::Base
  has_many :stock_opname_details
  belongs_to :office
  belongs_to :warehouse
  belongs_to :supplier
  belongs_to :inspector, class_name: "User", foreign_key: "inspector_id"

  accepts_nested_attributes_for :stock_opname_details, :reject_if => :all_blank, :allow_destroy => true

  # before_save :check_details
  # after_create :update_stock

  def self.number
    number = (StockOpname.last(:order => "opname_number ASC").opname_number.last(6).to_i rescue 0) + 1
    return number
  end

  def diff
    actual_stock - last_stock rescue nil
  end

  def self.import(params)
    data = []
    params[:cabang] = params[:xbranch]
    params[:gudang] = params[:xstore]
    spreadsheet = open_spreadsheet(params[:file])
    header = spreadsheet.row(1)
    (6..spreadsheet.last_row).each do |i|
      xdata = spreadsheet.row(i)
      params[:barcode] = xdata[0]
      good = GoodsSize.find_by_barcode(xdata[0])
      stock = Store.cek_stock_barang(params)

      data << [xdata[0], good.goods.brand.name, good.goods.article, good.goods.colour.name, good.size_detail.size_number, stock, xdata[1], xdata[2], good.id] if good.present? && stock.present?
    end
    return data
  end


  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Roo::Csv.new(file.path, nil, :ignore)
    when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  private
  protected
    def check_details
      self.errors.add(:stock_opname_detail, "does not empty") and return false unless self.stock_opname_details.present?
  	end

    def update_stock
      stock_opname_detail = self.stock_opname_details.first
      stock_opname_detail.goods_size.goods_details.where(store_id: self.store_id).each{|g| g.update_attributes(quantity: stock_opname_detail.qty_actual)}# rescue 0
    end
end
