class Product < ActiveRecord::Base
  belongs_to :brand
  belongs_to :colour2, class_name: 'Colour'
  belongs_to :colour3, class_name: 'Colour'
  belongs_to :colour4, class_name: 'Colour'
  belongs_to :m_class
  belongs_to :unit
  belongs_to :box, class_name: 'Unit'
  belongs_to :box2, class_name: 'Unit'
  belongs_to :size
  belongs_to :colour
  belongs_to :department, class_name: 'MClass'

  validates :barcode, numericality: { only_integer: true }, allow_blank: true
  validates :box_barcode, numericality: { only_integer: true }, allow_blank: true
  validates :box2_barcode, numericality: { only_integer: true }, allow_blank: true

  has_many :purchase_request_details
  has_many :inventory_request_details
  has_many :product_details
  has_many :receivings
  has_many :stock_opname_details
  has_many :branch_prices
  has_many :product_sizes, dependent: :destroy
  has_many :product_suppliers
  has_many :suppliers, through: :product_suppliers
  has_many :selling_prices
  has_many :sales_details
  has_many :skus, dependent: :destroy # SKU dihapus jika product dihapus

 # validate :supplier_empty
 before_validation :upcase_save
 before_create :supplier_empty

  attr_accessor :supplier_id, :max_stock, :rop_stock, :store_id

  def supplier_empty
    errors.add(:supplier, "should not empty") if supplier_id == nil
  end

  def upcase_save
    self.description = description.upcase rescue nil
  end
=begin
2.0.0-p594 :001 > SellingPrice.count
   (1.7ms)  SELECT COUNT(*) FROM "selling_prices"
 => 11191
2.0.0-p594 :002 > SellingPrice.where("product_id IS NULL").delete_all
  SQL (31.4ms)  DELETE FROM "selling_prices" WHERE (product_id IS NULL)
 => 1649
2.0.0-p594 :003 > SellingPrice.count
   (3.5ms)  SELECT COUNT(*) FROM "selling_prices"
 => 9542
SellingPrice.where(office_id: 1).each{|a|
x = SellingPrice.new code: a.code, product_id: a.product_id, margin: a.margin, hpp: a.hpp, dpp: a.dpp, ppn_in: a.ppn_in, ppn_out: a.ppn_out, start_date: a.start_date, end_date: a.end_date, branch_id: 7, office_id: 7, selling_price: a.selling_price, margin_amount: a.margin_amount, hpp_2: a.hpp_2, receiving_id: a.receiving_id, margin_percent: a.margin_percent, hpp_average: a.hpp_average, supplier_id: a.supplier_id
raise x.errors.inspect unless x.save
SellingPriceDetail.create selling_price_id: x.id, sku_id: x.product.skus.first.id, price: x.selling_price
}


2.0.0-p594 :012 > SellingPrice.last.id
  SellingPrice Load (0.8ms)  SELECT  "selling_prices".* FROM "selling_prices"   ORDER BY "selling_prices"."id" DESC LIMIT 1
 => 9585
2.0.0-p594 :013 > SellingPriceDetail.last.id
  SellingPriceDetail Load (0.4ms)  SELECT  "selling_price_details".* FROM "selling_price_details"   ORDER BY "selling_price_details"."id" DESC LIMIT 1
 => 9585


Sku.find_by_sql("SELECT products.id AS product_id, article, (SELECT COUNT(*) FROM skus WHERE product_id=products.id) AS counter FROM products WHERE (SELECT COUNT(*) FROM skus WHERE product_id=products.id)>1;").each{|a|
Sku.where("product_id=#{a.product_id}").limit(a.counter-1).destroy_all
}
=end


  after_create :generate_product_details


  validates :description, uniqueness: true, presence: true
  validates :short_name, uniqueness: true, presence: true
  #validates :barcode, uniqueness: true
  validates :article, uniqueness: true, presence: true
  validates :department_id, presence: true
  validates :m_class_id, presence: true
  validates :short_name, length: { in: 6..40 }

  validates_format_of :purchase_price, :with => /^[0-9\s,.]*$/i, :multiline => true, :message => "masukkan bilangan bulat atau desimal saja"

  accepts_nested_attributes_for :product_sizes, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :branch_prices, reject_if: :all_blank, allow_destroy: true
  scope :search, lambda {|search|{
    :order => "id ASC",
    :conditions => [
      'sku LIKE ? OR barcode LIKE ? OR  description LIKE ? OR product.brand.name LIKE ? OR product.department_name LIKE ? OR product.m_class_name LIKE ? ',
      "%#{search.first}%", "%#{search.first}%","%#{search.first}%","%#{search.first}%","%#{search.first}%","%#{search.first}%"
    ]
  }}

  mount_uploader :image, ImageUploader

  def check_transaction
    return false if ReceivingDetail.where("receiving_details.product_id=?", self.id).joins(product_size: :product).limit(1).present?
    true
  end

  def cost
    selling_prices.where("now() BETWEEN start_date AND end_date").first.hpp rescue 0
  end

  def first_cost
    selling_prices.where("start_date<now()").first.hpp rescue 0
  end

  def last_cost
      selling_prices.where("start_date<'#{Time.now.strftime('%Y-%m-01')}'").first.hpp rescue 0
  end

  def generate_product_details
    conditions = []
    conditions << "id=#{store_id}" if store_id.present?
    Office.active_store.where(conditions.join(' AND ')).each{|office|
      pd = ProductDetail.where(product_id: id, warehouse_id: office.id, sku_id: (Sku.find_by_convertion_unit_and_product_id(1, id).id rescue nil)).first_or_create
      pd.update_attributes max_stock: max_stock, rop_stock: rop_stock, min_stock: 0
    }
  end

  def set_price
=begin
    self.update_attributes(purchase_price: 100000)
    self.update_attributes(margin_percent: 100)# if margin_percent.blank?
    self.update_attributes(margin_percent4: 80)# if margin_percent4.blank?
    self.update_attributes(margin_percent1: 45)# if margin_percent1.blank?
    self.update_attributes(margin_percent2: 20)# if margin_percent1.blank?
    self.update_attributes(margin_percent3: 10)# if margin_percent1.blank?
=end
    price_after_discount1 = purchase_price*(100-brand.discount_percent1)/100
    price_after_discount2 = price_after_discount1*(100-brand.discount_percent2)/100
    price_after_discount3 = price_after_discount2*(100-brand.discount_percent3)/100
    price_after_discount4 = price_after_discount3*(100-brand.discount_percent4)/100
    h_bandrol = 0
    self.cost_of_products = price_after_discount4
    if brand.set_harga == 'Normal'
      self.margin_rp = price_after_discount4/margin_percent*100# if margin_rp.blank?
      harga_kredit = margin_percent1.to_i == 0 ? 0 : self.margin_rp/margin_percent1*100
      self.harga_kredit = harga_kredit
      h_bandrol = margin_percent4.to_i == 0 ? 0 : harga_kredit/margin_percent4*100
      self.harga_member_eceran = h_bandrol-h_bandrol*margin_percent2/100
      self.harga_eceran = h_bandrol-h_bandrol*margin_percent3/100
    elsif brand.set_harga == 'Pabrik'
      h_bandrol = self.purchase_price+margin_percent4
      harga_kredit = h_bandrol-h_bandrol*margin_percent1/100
      harga_member_eceran = (h_bandrol-h_bandrol*margin_percent2/100).to_i
      harga_eceran = (h_bandrol-h_bandrol*margin_percent3/100).to_i
    elsif brand.set_harga == 'Obral'
      harga_eceran = self.cost_of_products/margin_percent3*100
      harga_member_eceran = (harga_eceran/margin_percent2*100).to_i
      h_bandrol = harga_eceran/margin_percent4*100
      self.harga_kredit = (h_bandrol-h_bandrol*margin_percent1/100).to_i
    end
    self.harga_bandrol = h_bandrol.to_i
    self.selling_price = h_bandrol.to_i
#    self.save
  end

  def product_price created_at
    SellingPrice.where("product_id=#{id} AND end_date > now()").last
  end

  def full_colour
    colour_code.present? ? [colour_code] : [(colour.name rescue nil), (colour2.name rescue nil), (colour3.name rescue nil), (colour4.name rescue nil)].compact
  end

  #Move to fast or slow or dead
  def self.set_status4
    #Move to fast or slow
    products = SalesDetail.where("sales_details.created_at BETWEEN '#{(Time.now-14.days).strftime('%Y-%m-%d 00:00:00')}' AND '#{(Time.now).strftime('%Y-%m-%d 23:59:59')}'")
      .group("product_id").select("SUM(quantity) AS sum_quantity, product_id").joins(product_size: :product)
    products.each{|product|
      mutation_amount = (ProductDetail.where("product_id=#{product.product_id}").joins(:product_size).map(&:available_qty).compact.sum.to_f+product.sum_quantity.to_f)*100
      Product.find(product.product_id).update_attributes(status4: product.sum_quantity.to_f/mutation_amount < 10 ? 'Fast Moving' : 'Slow Moving')
    }

    #Move to dead
    Product.where("id NOT IN (#{products.map(&:product_id).join(', ')})").update_all("status4='Dead Moving'")
  end

  def color_list

    # [self.product.name, self.product2.name, self.product3.name, self.product4.name].join('/')
  end

  def full_product
    product = []
    product << self.product.name if self.product_id.present?
    product << self.product2.name if self.product2_id.present?
    product << self.product3.name if self.product3_id.present?
    product << self.product4.name if self.product4_id.present?
    return product
    # (self.product_id.present? ? self.product.name : "") + (self.product2_id.present? ? self.product2.name : "") + (self.product3_id.present? ? self.product3.name : "") + (self.product4_id.present? ? self.product4.name : "")
  end

  def self.to_csv(products, options = {})
    CSV.generate(options) do |csv|
      csv << ["No", "Article", "Division", "Department", "Category", "Sub Category", "Segment", "uom_1", "uom_2", "uom_3", "box_num", "box2_num", "barcode", "description", "supplier_code", "supplier_name"]
      nomor = 0
      products.each do |product|
        nomor += 1
        cat_ori = MClass.find(product.m_class_id) rescue ''
        cat_level = cat_ori.level rescue 0
        if cat_level == 1
          cat1 = cat_ori
          cat2 = ''
          cat3 = ''
          cat4 = ''
        elsif cat_level == 2
          cat2 = cat_ori
          cat1 = MClass.find(cat_ori.parent_id) rescue ''
          cat3 = ''
          cat4 = ''
        elsif cat_level == 3
          cat3 = cat_ori
          cat2 = MClass.find(cat_ori.parent_id) rescue ''
          cat1 = MClass.find(cat2.parent_id) rescue ''
          cat4 = ''
        elsif cat_level == 4
          cat4 = cat_ori
          cat3 = MClass.find(cat_ori.parent_id) rescue ''
          cat2 = MClass.find(cat3.parent_id) rescue ''
          cat1 = MClass.find(cat2.parent_id) rescue ''
        end
        csv << [nomor, product.article, (product.department.name rescue ''), (cat1.name rescue ''), (cat2.name rescue ''), (cat3.name rescue ''), (cat4.name rescue ''), (product.unit.name rescue ''), (Unit.find(product.box_id).name rescue ''), (Unit.find(product.box2_id).name rescue ''), product.box_num, product.box2_num, product.barcode, product.description, (product.suppliers.last.code rescue ''), (product.suppliers.last.name rescue '')]
      end
    end
  end

  def self.to_csv3(options = {}, office_name = {})
    CSV.generate(options) do |csv|
      office = Office.all
      #byebug
      office_jum = office.count
      office_str = office.collect(&:office_name).map(&:inspect).join(',"", ').split(',').map {|s| s.gsub(/"/, '')}
      office_array = ["Qty", "Min Stock"] * office_jum

      office_int = office.collect(&:id)
      prod = ""
      num = 0

      csv << ["Department", "Category", "SKU", "Barcode", "Name"] + office_str
      csv << ["", "", "", "", ""] + office_array
      all.each do |product|
        until num >= office_jum  do
         prod_qty = ProductDetail.find_by_warehouse_id_and_product_id(office_int[num], product.id).available_qty.to_i rescue ''
         prod_min_stok = ProductDetail.find_by_warehouse_id_and_product_id(office_int[num], product.id).min_stock.to_i rescue ''
         prod += prod_qty.to_s + "," + prod_min_stok.to_s + ","
         num +=1;
        end
        csv << [(product.department.name rescue ''), (product.m_class.name rescue ''), product.article, product.barcode, product.description] + prod.split(",")
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["barcode", "brand", "article", "size", "department", "m_class", "unit", "colour", "colour 2", "colour 3", "colour 4", "colour_code", "purchase_price", "selling_price", "discount_price",
        "discount_price2", "discount_price3", "percentage_price", "netto", "cost_date", "sell_price_date", "purchase_price_date", "status", "status1", "status2", "status3", "status4", "status5", "first_po",
        "margin_percent1", "margin_percent2", "margin_percent3", "margin_percent4", "margin_percent", "harga_bandrol", "harga_eceran", "harga_member_eceran", "harga_kredit"]
    end
  end

  def self.upgrade_barcode(file)
    line = 0
    #a = Receiving.new number: 1, consigment_number: 1, date: Time.now, supplier_id: Supplier.first.id, status: 'Received', created_at: Time.now.beginning_of_month
    #raise a.errors.full_messages.inspect unless a.save
    product_not_found = []
    CSV.foreach(file.path, headers: true, :encoding => 'ISO-8859-1') do |row|
      parameters = ActionController::Parameters.new(row.to_hash)
      product = Product.find_by_article(parameters['product_code'])
      if product.present?
        if product.barcode != parameters['barcode'] || product.description != parameters['product_desc']
          sku = Sku.find_by_barcode(product.barcode)
          sku.update_attributes(barcode: parameters['barcode']) rescue Sku.create barcode: parameters['barcode'], unit_id: product.unit_id, convertion_unit: 1
          raise "#{parameters['product_code']}/#{parameters['barcode']}/#{parameters['product_desc']}, #{product.errors.full_messages}".inspect unless product.update_attributes(barcode: parameters['barcode'], description: parameters['product_desc'])
        end
      else
        product_not_found << "#{parameters['product_code']}/#{parameters['barcode']}/#{parameters['product_desc']}"
      end
=begin
      product = Product.find_by_article(parameters['article']) || Product.find_by_barcode(parameters['barcode'])
      raise parameters['article'].inspect if product.blank?
      product.update_attributes(barcode: product.barcode, description: parameters['product_desc']) if product.barcode != parameters['barcode'] || product.description != parameters['product_desc']
      ReceivingDetail.create receiving_id: Receiving.first.id, product_id: product.id, created_at: Time.now.beginning_of_month, quantity: parameters['qty']
=end
    end
    raise product_not_found.inspect if product_not_found.present?
  end

  def self.import(rows)

    line = 0
    rows.each do |row|
      parameters = ActionController::Parameters.new(row.to_hash)
      product = Product.find_by_barcode(parameters['barcode'])
      present_product = Product.find_by_barcode(row['zfood_barcode']) if row['zfood_barcode'].present?
      if row.to_hash['supplier_name'].present?
        supplier = Supplier.find_by_name(row.to_hash['supplier_name'].titleize)
      else
        supplier = ProductSupplier.where(product_id: present_product.id).limit(1).order("id DESC").last.supplier rescue nil
      end
      if parameters['barcode'].blank? || product.blank?
        brand = Brand.where(name: [(row["description"].split(' ')[0] rescue ''), (row["description"].split(' ')[1] rescue ''), (row["description"].split(' ')[2] rescue '')].join(' ')).first
        if brand.blank?
          brand = Brand.new(
            name: [(row["description"].split(' ')[0] rescue ''), (row["description"].split(' ')[1] rescue ''), (row["description"].split(' ')[2] rescue '')].join(' '),
            code: "B#{(('%03d' % ((Brand.last.code.gsub('B', '').to_i rescue 0)+1)))}"
          )
          brand.save
        end
        if row["department_name"].present?
          department = Department.find_by_name((row["department_name"].to_s.titleize))
          if department.blank?
            department = Department.where(name: (row["department_name"].to_s.titleize), level: 0).first_or_create
          end
        else
          department = Department.where(name: 'Umum', level: 0).first_or_create
        end
        if row["category_1"].present?
          m_class = MClass.where(name: (row["category_1"].titleize.gsub(/\s+$/,'')), parent_id: department.id, level: 1).first
          if m_class.blank?
            m_class = MClass.new(code: row["Dvision"], name: (row["category_1"].titleize.gsub(/\s+$/,'')), parent_id: department.id, level: 1)
            m_class.save
          end
        else
          department = Department.where(name: ('Cat Umum'), parent_id: department.id, level: 1).first_or_create
        end
        if row["category_2"].present?
          m_class_2 = MClass.where(name: (row["category_2"].titleize rescue 'MD 2 Umum'), parent_id: m_class.id, level: 2).first
          if m_class_2.blank?
            m_class_2 = MClass.new(code: row["Category"], name: (row["category_2"].titleize.gsub(/\s+$/,'') rescue 'MD 2 Umum'), parent_id: m_class.id, level: 2)
            m_class_2.save
          end
        end
        if row["category_3"].present?
          m_class_3 = MClass.where(name: (row["category_3"].titleize.gsub(/\s+$/,'') rescue 'MD 3 Umum'), parent_id: m_class_2.id, level: 3).first
          if m_class_3.blank?
            m_class_3 = MClass.new(code: row["Sub Category"], name: (row["category_3"].titleize.gsub(/\s+$/,'') rescue 'MD 3 Umum'), parent_id: m_class_2.id, level: 3)
            m_class_3.save
          end
        end
        if row["category_4"].present?
          m_class_4 = MClass.where(name: (row["category_4"].titleize.gsub(/\s+$/,'') rescue 'MD 4 Umum'), parent_id: m_class_3.id, level: 4).first
          if m_class_4.blank?
            m_class_4 = MClass.new(code: row["Segment"], name: (row["category_4"].titleize.gsub(/\s+$/,'') rescue 'MD 4 Umum'), parent_id: m_class_3.id, level: 4)
            m_class_4.save
          end
        end
        purchase_price = row["purchase_price"].to_f rescue "0".to_f
        discount1 = brand.discount_percent1.to_f rescue "0".to_f
        discount2 = brand.discount_percent2.to_f rescue "0".to_f
        discount3 = brand.discount_percent3.to_f rescue "0".to_f
        discount4 = brand.discount_percent4.to_f rescue "0".to_f
        set_harga = brand.set_harga.upcase rescue 'Manual'
        price_after_discount1 = purchase_price * (100 - discount1) / 100
        price_after_discount2 = price_after_discount1 * (100 - discount2) / 100
        price_after_discount3 = price_after_discount2 * (100 - discount3) / 100
        price_after_discount4 = price_after_discount3 * (100 - discount4) / 100
        margin_percent1 = row["margin_percent1"].to_f rescue "0".to_f
        margin_percent2 = row["margin_percent2"].to_f rescue "0".to_f
        margin_percent3 = row["margin_percent3"].to_f rescue "0".to_f
        margin_percent4 = row["margin_percent4"].to_f rescue "0".to_f
        margin_percent = row["margin_percent"].to_f rescue "0".to_f
        harga_bandrol = 0
        mod = price_after_discount4 % 500
        cost_of_products = price_after_discount4

        uom_1 = Unit.find_by_name((row["uom_1"].titleize rescue ''))
        if uom_1.blank?
          uom_1 = Unit.new(id: ((Unit.last.id rescue 0)+1), name: row["uom_1"], short_name: row["uom_1"])
          uom_1.save
        end
        uom_2 = Unit.find_by_name((row["uom_2"].titleize rescue ''))
        if uom_2.blank?
          uom_2 = Unit.new(id: ((Unit.last.id rescue 0)+1), name: row["uom_2"], short_name: row["uom_2"])
          uom_2.save
        end
        uom_3 = Unit.find_by_name((row["uom_3"].titleize rescue ''))
        if uom_3.blank?
          uom_3 = Unit.new(id: ((Unit.last.id rescue 0)+1), name: row["uom_3"], short_name: row["uom_3"])
          uom_3.save
        end

        if row['status2'] == 'lotte'
          status2 = 'Non-Konsinyasi'
        else
          status2 = 'Konsinyasi'
        end

        store = Office.find_by_code(row.to_hash['store'])
        if Product.find_by_description(row['description'])
          product = Product.find_by_description(row['description'])
          product.update_attributes(parameters.permit(
            :purchase_price, :status1, :status2, :status3, :status4, :status5, :margin_percent, :margin_percent1, :margin_percent2, :margin_percent3, :margin_percent4, :margin_rp, :colour_code, :status5,
            :description, :description_2, :selling_price, :cost_of_products, :box_num, :box2_num, :box2_barcode, :max_stock, :rop_stock
          ).merge(
            unit_id: uom_1.id, box_id: uom_2.id, box2_id: uom_3.id, m_class_id: (m_class_4.id rescue (m_class_3.id rescue (m_class_2.id rescue (1)))), supplier_id: (supplier.id rescue nil), status1: row['status1'], status2: status2,
            department_id: department.id, short_name: row["description"][0..39], flag_pajak: row.to_hash['bkp'] == 'Y' ? 'BKP' : 'NBKP', parent_id: (present_product.id rescue nil), store_id: (store.id rescue nil),
            barcode: row["barcode"] || product.barcode, is_bkt: row["bkt"] == 'Y', status_retur: row["retur"] == 'Y'
          ))
        else
          art = row['article'].present? ? row['article'] : (Product.order("article ASC").last.article.to_i+1 rescue '160001')
          if row['barcode'].present?
            product = new(parameters.permit(
              :purchase_price, :status1, :status2, :status3, :status4, :status5, :margin_percent, :margin_percent1, :margin_percent2, :margin_percent3, :margin_percent4, :margin_rp, :colour_code, :status5,
              :barcode, :description, :selling_price, :cost_of_products, :box_num, :box2_num, :box2_barcode, :box_barcode
            ).merge(
              code: ('%03d' % ((Product.last.code.to_i rescue 0)+1)), brand_id: (brand.id rescue nil), unit_id: uom_1.id, box_id: uom_2.id, box2_id: uom_3.id,
              status1: row['status1'], status2: status2,
              m_class_id: (m_class_4.id rescue (m_class_3.id rescue (m_class_2.id rescue (m_class)))),
              department_id: department.id, short_name: row["description"][0..39], flag_pajak: row.to_hash['bkp'] == 'Y' ? 'BKP' : 'NBKP', parent_id: (present_product.id rescue nil), article: art,
              supplier_id: (supplier.id rescue nil), id: (Product.last.id rescue 0)+1, rop_stock: row["rop_stock"], max_stock: row["max_stock"], store_id: (store.id rescue nil), is_bkt: row["bkt"] == 'Y', status_retur: row["retur"] == 'Y'
            ))
          else
            product = new(parameters.permit(
              :purchase_price, :status1, :status2, :status3, :status4, :status5, :margin_percent, :margin_percent1, :margin_percent2, :margin_percent3, :margin_percent4, :margin_rp, :colour_code, :status5,
              :description, :description_2, :selling_price, :cost_of_products, :box_num, :box2_num, :box2_barcode, :box_barcode
            ).merge(
              code: ('%03d' % ((Product.last.code.to_i rescue 0)+1)), brand_id: (brand.id rescue nil), unit_id: uom_1.id, box_id: uom_2.id, box2_id: uom_3.id,
              m_class_id: (m_class_4.id rescue (m_class_3.id rescue (m_class_2.id rescue (1)))),
              status1: row['status1'], status2: status2,
              department_id: department.id, short_name: row["description"][0..39], flag_pajak: row.to_hash['bkp'] == 'Y' ? 'BKP' : 'NBKP', parent_id: (present_product.id rescue nil), article: art,
              barcode: ("#{Product.where("barcode LIKE '24%'").order("barcode DESC").first.barcode.to_i+1}" rescue '2400000000000'), supplier_id: (supplier.id rescue nil), id: (Product.last.id rescue 0)+1,
              rop_stock: row["rop_stock"], max_stock: row["max_stock"], store_id: (store.id rescue nil), is_bkt: row["bkt"] == 'Y', status_retur: row["retur"] == 'Y'
            ))
          end
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{product.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{product.errors.full_messages.join('<br/>')}"} unless product.save
        end
      end
      if supplier.present?
        cp = supplier.contact_people.first rescue nil
        ps_attr = {product_id: product.id, contact_person_id: (cp.id rescue (supplier.id rescue 1)), hpp: row.to_hash['cost_of_products'], minimal_order: row.to_hash['minimal_order'], supplier_id: (supplier.id rescue 1)}
        ps = ProductSupplier.find_by_contact_person_id_and_product_id((cp.id rescue (supplier.id rescue 1)), product.id) rescue ProductSupplier.find_by_supplier_id_and_product_id(supplier.id, product.id)
        if ps.present?
          ps.update_attributes(ps_attr)
        else
          ps = ProductSupplier.new ps_attr
          ps.save
        end
      end
      selling_price = row.to_hash['selling_price'].gsub(',', '').to_f rescue 0
      if present_product.present?
        hpp = SellingPrice.where("end_date > now()").limit(1).order("id DESC").last.hpp
      else
        hpp = row['cost_of_products'].gsub(',', '').to_f
      end
      hpp_and_ppn = (ps.contact_person.supplier.status_pkp ? 1.1 : 1) rescue 1
      margin_percent = (selling_price-(hpp*(hpp_and_ppn)))/selling_price*100
      sku = Sku.where(product_id: product.id, unit_id: product.unit_id, barcode: product.barcode, convertion_unit: 1).first_or_create
      if product.box_barcode.present?
        sku1 = Sku.where(product_id: product.id, unit_id: product.box_id, barcode: product.box_barcode).first_or_create
        sku1.update_attributes(convertion_unit: product.box_num)
      end
      if product.box2_barcode.present?
        sku2 = Sku.where(product_id: product.id, unit_id: product.box2_id, barcode: product.box2_barcode).first_or_create
        sku2.update_attributes(convertion_unit: product.box2_num)
      end
      if product.id.present?
        if store.present?
          product_price = SellingPrice.new code: row.to_hash['barcode'], product_id: product.id, margin_percent: margin_percent, hpp: hpp, start_date: Time.now, end_date: '3000-01-01', branch_id: store.id,
            office_id: store.id, selling_price: selling_price, hpp_2: hpp, hpp_average: hpp, ppn_in: (0.1*hpp if row.to_hash['bkp'] == 'Y'), supplier_id: (supplier.id rescue nil)
          product_price.save
          SellingPrice.where("product_id=#{product.id} AND office_id=#{store.id} AND id!=#{product_price.id} AND end_date>'#{(Time.now.to_date).strftime('%Y-%m-%d')}'")
            .update_all("end_date='#{(Time.now.to_date-1.days).strftime('%Y-%m-%d')}'")
          SellingPriceDetail.create selling_price_id: product_price.id, sku_id: sku.id, price: product_price.selling_price, id: (SellingPriceDetail.last.id rescue 0)+1
          SellingPriceDetail.create selling_price_id: product_price.id, sku_id: sku1.id, price: row.to_hash['selling_price_2'], id: (SellingPriceDetail.last.id rescue 0)+1 if product.box_barcode.present?
          SellingPriceDetail.create selling_price_id: product_price.id, sku_id: sku2.id, price: row.to_hash['selling_price_3'], id: (SellingPriceDetail.last.id rescue 0)+1 if product.box2_barcode.present?
        else
          Office.all.each{|a|
            product_price = SellingPrice.new code: row.to_hash['barcode'], product_id: product.id, margin_percent: margin_percent, hpp: hpp, start_date: Time.now, end_date: '3000-01-01', branch_id: a.id,
              office_id: a.id, selling_price: selling_price, margin_amount: 0, hpp_2: hpp, hpp_average: hpp, ppn_in: (0.1*hpp if row.to_hash['bkp'] == 'Y'),
              margin_amount: selling_price-hpp_and_ppn, supplier_id: (supplier.id rescue nil)
            if product_price.save
              SellingPrice.where("product_id=#{product.id} AND office_id=#{a.id} AND id!=#{product_price.id} AND end_date>'#{(Time.now.to_date).strftime('%Y-%m-%d')}'")
                .update_all("end_date='#{(Time.now.to_date-1.days).strftime('%Y-%m-%d')}'")
              SellingPriceDetail.create selling_price_id: product_price.id, sku_id: sku.id, price: product_price.selling_price, id: (SellingPriceDetail.last.id rescue 0)+1
              SellingPriceDetail.create selling_price_id: product_price.id, sku_id: sku1.id, price: row.to_hash['selling_price_2'], id: (SellingPriceDetail.last.id rescue 0)+1 if product.box_barcode.present?
              SellingPriceDetail.create selling_price_id: product_price.id, sku_id: sku2.id, price: row.to_hash['selling_price_3'], id: (SellingPriceDetail.last.id rescue 0)+1 if product.box2_barcode.present?
            else
              return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{product_price.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{product_price.errors.full_messages.join('<br/>')}"}
            end
          }
        end
      end
      line += 1
      ProductDetail.where("barcode='#{row["barcode"]}'").joins(:product).first.update_attributes(available_qty: row["qty"]) if row["qty"].present?
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

  def generate_sku
    sku = Sku.where(product_id: product.id, unit_id: product.unit_id, barcode: product.barcode, convertion_unit: 1).first
    if sku.blank?
    sku = Sku.where(product_id: product.id, unit_id: product.unit_id, barcode: product.barcode, convertion_unit: 1, id: Sku.last.id+1).first_or_create
    end
    if product.box_barcode.present?
      sku = Sku.where(product_id: product.id, unit_id: product.box_id, barcode: product.box_barcode).first_or_create
      sku.update_attributes(convertion_unit: product.box_num)
    end
    if product.box2_barcode.present?
      sku = Sku.where(product_id: product.id, unit_id: product.box2_id, barcode: product.box2_barcode).first_or_create
      sku.update_attributes(convertion_unit: product.box2_num)
    end
  end

  def count_qty(qty=nil, size_detail=nil)
    0
  end

  def count_total_qty(qty=nil)
    0
  end

  def self.get_product_unsold_for_three_months
    products = Product.where("products.id not in (select product_id from sales_details where created_at > now() - interval ?)", '3 months')
  end

  def self.get_best_seller
    products = Product.where("products.id in (select product_id from sales_details group by product_id having count(product_id) > ?)", 10)
  end

  def self.get_hpp_average(product_id, wh_ids)
    result = "0;0"
    pajak = "0"

    total_hpp = 0
    total_qty = 0

    wh_ids.each do |wh_id|
      selling_price = SellingPrice.where("product_id = ? and office_id = ?", product_id, wh_id).order("created_at desc limit 2")
      next if selling_price.nil?

      new_hpp = selling_price[0].hpp rescue 0
      old_hpp = selling_price[1].hpp rescue 0

      avail_qty = ProductDetail.where("product_id = ? and warehouse_id = ? and available_qty > 0", product_id, wh_id).pluck(:available_qty).sum()
      new_qty = ReceivingDetail.select("receiving_details.quantity, receivings.id")
                               .joins("left join receivings on receiving_details.receiving_id = receivings.id")
                               .where("receiving_details.product_id = ? and receivings.head_office_id = ?", product_id, wh_id)
                               .order("receivings.created_at desc").first.quantity rescue 0

      old_qty = avail_qty - new_qty
      total_hpp += old_hpp * old_qty + new_hpp * new_qty
      total_qty += avail_qty
    end

    hpp_avg = total_qty == 0 ? SellingPrice.find_by_product_id(product_id).hpp : total_hpp / total_qty
    ppn_in = hpp_avg * 0.1

    return hpp_avg.to_s + ";" + ppn_in.to_s
  end

  def is_bkp?
    flag_pajak == 'BKP'
  end

  def get_hpp_average
    ProductMutationHistory.where("product_id=#{id}").joins(:product_detail).select("SUM(price)/SUM(moved_quantity) AS hpp_ave").map(&:hpp_ave).first
  end

  def copy_reorder_formula copy_from, copy_to
    ProductDetail.where("warehouse_id=#{copy_to} AND max_stock IS NULL").each{|pd|
      prod_copied_from = ProductDetail.find_by_product_id_and_warehouse_id(pd.product_id, copy_from)
      pd.update_attributes(max_stock: prod_copied_from.max_stock, rop_stock: prod_copied_from.rop_stock, min_stock: prod_copied_from.min_stock)
    }
  end

  def self.get_receive_hpp_average(product_id, wh_id)
    result = 0
    receiving_detail = ReceivingDetail.joins("left join receivings on receiving_details.receiving_id = receivings.id").where("receiving_details.product_id = ? and receivings.head_office_id = ?", product_id, wh_id).order("receivings.created_at desc limit 2")
    if (receiving_detail.nil?)
    elsif (receiving_detail.count >= 2)
      receiving_det = ReceivingDetail.select("receiving_details.quantity, receivings.id, receiving_details.hpp, receiving_details.hpp_average").joins("left join receivings on receiving_details.receiving_id = receivings.id").where("receiving_details.product_id = ? and receivings.head_office_id = ?", product_id, wh_id).order("receivings.created_at desc limit 2")
      old_hpp = receiving_det[1].hpp_average
      new_hpp = receiving_det.first.hpp
      avail_qty = ProductDetail.select("available_qty").where("product_id = ? and warehouse_id = ?", product_id, wh_id).first
      last_qty = receiving_det.first.quantity
      new_qty = last_qty
      old_qty = avail_qty.available_qty.to_i - last_qty.to_i
      hpp_ave = ((old_hpp.to_f * old_qty.to_f) + (new_hpp.to_f * new_qty.to_f)) / avail_qty.available_qty.to_f
      result = hpp_ave.round
    elsif (receiving_detail.count == 1)
      receiving_det = ReceivingDetail.select("receiving_details.quantity, receivings.id, receiving_details.hpp").joins("left join receivings on receiving_details.receiving_id = receivings.id").where("receiving_details.product_id = ? and receivings.head_office_id = ?", product_id, wh_id).order("receivings.created_at desc")
      hpp_ave = receiving_det[0].hpp
      result = hpp_ave
    end
    return result
  end

  def self.get_pajak_supplier(supplier_id)
    is_pajak = Supplier.find(supplier_id).flag_pajak
  end

  def select_unit unit_type
    return (unit.name rescue '') if unit_type == 'Unit'
    return (box.name rescue '') if unit_type == 'Box'
    return (box2.name rescue '') if unit_type == 'Box 2'
  end
end
