class InventoryRequest < ActiveRecord::Base
  has_many :inventory_request_details, dependent: :destroy

  belongs_to :supplier
  belongs_to :branch
  belongs_to :purchase_order

  accepts_nested_attributes_for :inventory_request_details, reject_if: :all_blank, allow_destroy: true
  WAITING_APPROVAL = 'Waiting Approval'
end
