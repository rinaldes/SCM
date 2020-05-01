class ApInvoiceDetail < ActiveRecord::Base
  belongs_to :ap_invoice
  belongs_to :receiving
end
