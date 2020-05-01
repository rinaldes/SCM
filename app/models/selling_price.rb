class SellingPrice < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
  belongs_to :receiving
  belongs_to :office
  belongs_to :supplier

  has_many :brands
  has_many :selling_price_details, :dependent => :destroy
  accepts_nested_attributes_for :selling_price_details, :allow_destroy => true

  validates :product_id, presence: true
  validates :office_id, presence: true
  validate :hpp_selling_price
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :hpp, presence: true
  validates :hpp_average, presence: true

  def hpp_selling_price
    errors.add(:selling_price, "should be greater than hpp or not empty") if selling_price == nil || selling_price.present? && hpp.to_f > selling_price.to_f && selling_price!=0
  end

  def self.number(params)
    number = (SellingPrice.first(:conditions => "code like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:SellingPrice][:start_date][0]
    number = (SellingPrice.first(:conditions => "start_date like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_selling_price_id(selling_price)
    id = (SellingPrice.first(:conditions => "code = '#{selling_price}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def check_transaction
    return false if Product.find_by_selling_price(self.selling_price)
    true
  end

  def self.reset_product_per_store file
    product_ids = []
    blank_prod = []
    present_prod = []
    store_id = nil
    store = nil
    CSV.foreach(file.path, headers: true) do |row|
      parameters = ActionController::Parameters.new(row.to_hash)
      store = Office.find_by_code(parameters['store'])
      store_id = store.id
      if Product.find_by_article(parameters['article']).present?
        product_ids << Product.find_by_article(parameters['article']).id
        present_prod << parameters['article']
      else
        blank_prod << parameters['article']
      end
    end
    SellingPrice.where("office_id=#{store_id} AND product_id NOT IN (#{product_ids.join(',')})").update_all("end_date='#{Time.now.yesterday.strftime('%Y-%m-%d')}', updated_at=NOW()")
    return {success: 1, message: "Success Reset Product for store #{store.office_name}"}
  end

  def margin_amount
begin
    (product.is_bkp? ? selling_price.to_f*0.9 : selling_price).to_f-hpp_average.to_f
rescue
return selling_price
end
  end

  def margin_percent
    margin_amount.to_f/(hpp_2 || product.is_bkp? ? selling_price/1.1 : selling_price).to_f*100 rescue 0
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["article", "description", "barcode","start_date", "end_date", "hm-ppn", "margin", "hj+ppn", 'supplier_code']
      all.each do |selling_price|
        csv << [selling_price.product.article, selling_price.product.description, selling_price.product.barcode, selling_price.start_date, selling_price.end_date, selling_price.hpp, selling_price.margin, selling_price.dpp]
=begin
        csv << ["no","article","barcode","product","store","start_date", "end_date", "hpp", "hpp_average", "ppn_in",
        'margin_percent', 'margin_amount', 'ppn_out', 'selling_price']
      all.each do |selling_price|
          csv << [(selling_price.product.article rescue nil), (selling_price.product.barcode rescue nil),
            (selling_price.product.description rescue nil), (selling_price.office.office_name rescue nil),
            selling_price.start_date, selling_price.end_date, selling_price.hpp, selling_price.hpp_average,
            selling_price.ppn_in, selling_price.margin_percent, selling_price.margin_amount,
            selling_price.ppn_out, selling_price.price]
=end
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["article", "description", "barcode","start_date", "end_date", "hm-ppn", "margin", "hj+ppn", 'supplier_code', 'store']
    end
  end

  def self.import(file)
    line = 0
    barcodes = []
    CSV.foreach(file.path, headers: true) do |row|
      parameters = ActionController::Parameters.new(row.to_hash)
      if row["barcode"].present?
        if Product.find_by_barcode(parameters['barcode']).blank?
          if row["article"].present?
            prod = Product.find_by_article(parameters['article'])
            sku = Sku.where(product_id: prod.id).first_or_create
          else
            barcodes << parameters['barcode']
          end
        else
          prod = Product.find_by_barcode(parameters['barcode'])
          sku = Sku.where(product_id: prod.id, barcode: parameters['barcode']).first_or_create
        end
      elsif row["article"].present?
        prod = Product.find_by_article(parameters['article'])
        sku = Sku.where(product_id: prod.id).first_or_create
      end

      if Supplier.exists?(code: row['supplier_code'])
        supp_id = Supplier.find_by_code(row['supplier_code']).id
      else
        return {error: 1, message: "Impor gagal, silakan periksa kembali kode supplier anda."}
      end

      if row['store'].present?
        branch = Office.find_by_code(row['store'])
        begin
          ActiveRecord::Base.transaction do
            selling_price = new(parameters.permit(:start_date, :end_date, :margin, :margin_percent).merge(
              code: "C#{('%03d' % ((SellingPrice.last.code.gsub('C', '').to_i rescue 0)+1))}", ppn_in: (0.1*parameters['hm-ppn'].to_f if prod.is_bkp?), product_id: prod.id, hpp: parameters['hm-ppn'],
              hpp_2: prod.is_bkp? ? parameters['hj+ppn'].to_f/1.1 : parameters['hj+ppn'], selling_price: parameters['hj+ppn'], supplier_id: supp_id, office_id: branch.id, branch_id: branch.id,
              hpp_average: (SellingPrice.where("office_id=#{branch.id} AND product_id=#{prod.id} AND supplier_id=#{supp_id}").order("id DESC").limit(1).last.hpp_average rescue parameters['hm-ppn']),
              margin_amount: parameters['hj+ppn'].to_f-parameters['hm-ppn'].to_f, ppn_out: parameters['hj+ppn'].to_f-parameters['hj+ppn'].to_f/1.1
            ))
            if selling_price.save
              SellingPriceDetail.create selling_price_id: selling_price.id, sku_id: sku.id, price: selling_price.selling_price, id: ((SellingPriceDetail.last.id rescue 0)+1) if sku.present?
              SellingPrice.where("product_id=#{prod.id} AND (supplier_id=#{supp_id} OR supplier_id IS NULL) AND office_id=#{branch.id} AND id!=#{selling_price.id} AND end_date>'#{row['start_date']}'")
                .update_all("end_date='#{(row['start_date'].to_date-1.days).strftime('%Y-%m-%d')}', updated_at=NOW()") if prod.present?
            else
              error_msg = selling_price.errors.full_messages.join('<br/>')
              return {
                error: 1,
                message: line == 0 ? "Import failed, please recheck CSV file. #{error_msg}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{error_msg}"
              }
            end
          end
        rescue => e
          ActiveRecord::Rollback
        end
      elsif branch.present? && OfficeSupplier.find_by_supplier_id_and_office_id(supp_id, branch.id) || OfficeSupplier.find_by_supplier_id(supp_id).blank?
        selling_price = new(parameters.permit(:start_date, :end_date, :margin, :margin_percent).merge(
          code: "C#{('%03d' % ((SellingPrice.last.code.gsub('C', '').to_i rescue 0)+1))}", ppn_in: (0.1*parameters['hm-ppn'].to_f if prod && prod.is_bkp?), product_id: (prod.id rescue nil), hpp: parameters['hm-ppn'],
          hpp_2: prod && prod.is_bkp? ? parameters['hj+ppn']/1.1 : parameters['hj+ppn'], selling_price: parameters['hj+ppn'], supplier_id: supp_id, office_id: (branch.id rescue nil), branch_id: (branch.id rescue nil),
          hpp_average: (SellingPrice.where("office_id=#{branch.id} AND product_id=#{prod.id} AND supplier_id=#{supp_id}").order("id DESC").limit(1).last.hpp_average rescue parameters['hm-ppn']),
          margin_amount: parameters['hj+ppn'].to_f-parameters['hm-ppn'].to_f, ppn_out: parameters['hj+ppn'].to_f-parameters['hj+ppn'].to_f/1.1
        ))
        if selling_price.save
          SellingPriceDetail.create selling_price_id: selling_price.id, sku_id: sku.id, price: selling_price.selling_price, id: ((SellingPriceDetail.last.id rescue 0)+1) if sku.present?
          SellingPrice.where("product_id=#{prod.id} AND (supplier_id=#{supp_id} OR supplier_id IS NULL) AND office_id=#{branch.id} AND id!=#{selling_price.id} AND end_date>'#{row['start_date']}'")
            .update_all("end_date='#{(row['start_date'].to_date-1.days).strftime('%Y-%m-%d')}', updated_at=NOW()") if prod.id.present?
        else
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{selling_price.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{selling_price.errors.full_messages.join('<br/>')}"}
        end
      end
      line += 1
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
