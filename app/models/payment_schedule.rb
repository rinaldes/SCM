class PaymentSchedule < ActiveRecord::Base
  belongs_to :voucher_credit
end