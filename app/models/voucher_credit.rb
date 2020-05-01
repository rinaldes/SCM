class VoucherCredit < ActiveRecord::Base
  has_many :voucher_lists
  has_many :payment_schedules
end