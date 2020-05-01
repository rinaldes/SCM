class Voucher < ActiveRecord::Base
  before_validation :upcase_save

  belongs_to :office

  has_many :voucher_details

  #after_create :generate_detail

  validates :name, presence: true
  validates :valid_from, presence: true
  validates :valid_until, presence: true
  validates :amount, presence: true
  validates :voucher_number, presence: true
  #validates :discount , presence: true unless :discount_amount.blank?
  # validates :discount_amount, presence: true
  #validates :max_voucher ,presence: true unless :max_voucher_amt.blank?


  # validates :max_voucher_amt,presence: true
  #validates :office_id,presence: true

  def upcase_save
    self.name = name.upcase rescue nil
    self.term_condition = term_condition.upcase rescue nil
  end

  def generate_detail
    1.upto(max_voucher || 7).each{|i|
      voucher_details.create voucher_code: [*('a'..'z'),*('0'..'9')].shuffle[1,7].join.upcase, generated_date: Time.now, available: true
    }
  end
end
