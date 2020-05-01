class Office < ActiveRecord::Base
  scope :active_store, -> { where(is_active: true) }
  belongs_to :user, foreign_key: :contact_person
  belongs_to :area
  belongs_to :regional
  belongs_to :city

  before_validation :upcase_save

  has_many :promotions
  has_many :petty_cashes

  has_many :office_departments, :dependent => :destroy
  has_many :departments, :through => :office_departments

  has_many :sod_eods
  has_many :stock_opnames
  has_many :account_receivables

  has_many :branch_to_do_lists, :dependent => :destroy
  has_many :to_do_lists, through: :branch_to_do_lists

  has_many :planograms

  accepts_nested_attributes_for :office_departments, reject_if: :all_blank, allow_destroy: true

  validates :office_name, :presence => true, :uniqueness => true
  validates :regional_id, presence: true
  validates :city_id, presence: true
  validates :area_id, presence: true

  #validates :description, :presence => true
  #validates :warehouse, :presence => true
  #validates :address, :presence => true
  #validates :mobile_phone, :presence => true
  #validates :phone_number, :presence => true
  #validates :fax_number, :presence => true
  #validates :contact_person, presence: {:message => "Penanggung Jawab tidak diketahui"}
  validates_format_of :office_name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  validates_format_of :description, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  #validates_format_of :warehouse, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  #validates_format_of :address, :with => /^[a-zA-Z\d\s.,-]*$/i, :multiline => true, :message => "alphabet input only"
  validates :rt, :rw, numericality: {only_integer: true, allow_blank: true}

  after_create :generate_product_details

  def upcase_save
    self.office_name = office_name.last == ' ' ? office_name.chop.titleize : office_name.titleize rescue nil
  end

  def check_transaction
    return false if User.find_by_head_office_id(self.id) || User.find_by_branch_id(self.id) || ProductDetail.where("warehouse_id=#{self.id} AND available_qty>0").limit(1).present? || Branch.find_by_head_office_id(self.id)
    true
  end

  def generate_product_details
    # Office.delay.generate_product_details_async(id)
    Office.generate_product_details_async(id)
  end

  def self.generate_product_details_async(id)
    Product.all.each{|product|
      ProductDetail.where(product_id: product.id, warehouse_id: id).first_or_create
      present_pp = product.product_price(Time.now)
      if present_pp
        product_price = SellingPrice.new code: product.barcode, product_id: product.id, margin_percent: present_pp.margin_percent, hpp: present_pp.hpp, start_date: Time.now, end_date: '3000-01-01', branch_id: id,
          office_id: id, selling_price: present_pp.selling_price, margin_amount: present_pp.margin_amount, hpp_2: present_pp.hpp, hpp_average: present_pp.hpp, ppn_in: present_pp.ppn_in
          # margin_amount: ((present_pp.selling_price rescue 0) - (present_pp.hpp rescue 0)), supplier_id: present_pp.supplier_id
        product_price.save
        present_pp.selling_price_details.each{|spd|
          SellingPriceDetail.create selling_price_id: product_price.id, sku_id: spd.sku_id, price: spd.price, id: (SellingPriceDetail.last.id rescue 0)+1
        }
      end
    }
  end

  def self.cut_off
    [1, 2, 3, 4, 5, 6, 7, 8, 14, 21].each{|office_id|
      DailySalesInventory.generate_monthly_per_office '2016-10', office_id
    }
  end

  def self.generate_product_price(id, product)
    ProductDetail.where(product_id: product.id, warehouse_id: id).first_or_create
    present_pp = product.product_price(Time.now)
    if present_pp && SellingPrice.where("branch_id=#{id} AND product_id=#{product.id} AND end_date>NOW()").blank?
      product_price = SellingPrice.new code: product.barcode, product_id: product.id, margin_percent: present_pp.margin_percent, hpp: present_pp.hpp, start_date: Time.now, end_date: '3000-01-01', branch_id: id,
        office_id: id, selling_price: present_pp.selling_price, margin_amount: present_pp.margin_amount, hpp_2: present_pp.hpp, hpp_average: present_pp.hpp, ppn_in: present_pp.ppn_in,
        margin_amount: present_pp.selling_price-present_pp.hpp, supplier_id: present_pp.supplier_id
      product_price.save
      present_pp.selling_price_details.each{|spd|
        SellingPriceDetail.create selling_price_id: product_price.id, sku_id: spd.sku_id, price: spd.price, id: SellingPriceDetail.last.id+1
      }
    end
  end
end
