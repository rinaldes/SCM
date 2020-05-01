class ApInvoice < ActiveRecord::Base
  has_many :ap_invoice_details
  accepts_nested_attributes_for :ap_invoice_details
end
