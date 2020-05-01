class PrTransferProduct < ActiveRecord::Base
  belongs_to :purchase_request
  belongs_to :purchase_transfer, foreign_key: :transfer_product_id
end
