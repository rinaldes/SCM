class Promotion < ActiveRecord::Base
  #  include Filter
  JOIN = ''
  ORDER = 'promotions.id'
  SELECTED = 'promotions.*'
  GROUP_BY = 'promotions.id'

  before_validation :upcase_save
  before_validation :check_prize_lists, on: :create
  belongs_to :office
  has_many :promo_item_lists, dependent: :destroy
  has_many :prize_lists, dependent: :destroy
  accepts_nested_attributes_for :promo_item_lists, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :prize_lists, reject_if: :all_blank, allow_destroy: true

  validates :name, presence: true, :length => {minimum: 3, maximum: 50}#, :uniqueness => true
  validates :from, :to, presence: true
  # validates :promo_item_lists, presence: true
  validates :prize_lists, presence: true#, :if => !:discount_amount? || !:discount_percent?
  validates :office_id, presence: true

  # validates :min_qty, presence: true, if: "min_amount.nil?"
  # validates :min_amount, presence: true, if: "min_qty.nil?"

  # def min_amount_is_not_null_and_qty_null?
  #   :min_qty == nil && :min_amount == !nil
  # end

  # def min_qty_is_not_null_and_amount_null?
  #   :min_amount == nil && min_qty == !nil
  # end

  scope :search, lambda {|search|{
    :order => "code ASC",
    :conditions => [
      'code LIKE ? OR name LIKE ?',
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def check_prize_lists
    if !self.discount_percent? && !self.discount_amount? #yang ada isinya bakal return false
        validates_presence_of :prize_lists #kalo duanya kosong return true
    end
  end


  def upcase_save
    self.name = name.upcase rescue nil
  end

  def self.number(params)
    number = (Promotion.first(:conditions => "name like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:promotion][:name][0]
    number = (Promotion.first(:conditions => "name like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_promotion_id(promotion)
    id = (Promotion.first(:conditions => "code = '#{promotion}' or name = '#{promotion}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def manage_code
    if  self.new_record?
      if self.class.unscoped.available_data.present?
        (('%03d' % ((self.class.unscoped.available_data.order("id ASC").last.code.to_i rescue 0))))
      else
        (('%03d' % ((self.class.order("code ASC").last.code.to_i rescue 0)+1)))
      end
    else
      self.code
    end
  end
end
