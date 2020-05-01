class ArVoucher < Voucher
  has_many :ar_voucher_payment_schedules
  has_many :ar_voucher_details
  belongs_to :office
  accepts_nested_attributes_for :ar_voucher_payment_schedules, allow_destroy: true
  accepts_nested_attributes_for :ar_voucher_details, allow_destroy: true
end