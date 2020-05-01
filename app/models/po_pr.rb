class PoPr < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :purchase_request
end
