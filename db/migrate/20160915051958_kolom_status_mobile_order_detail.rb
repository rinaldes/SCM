class KolomStatusMobileOrderDetail < ActiveRecord::Migration
  def change
  	add_column :mobile_order_details, :status, :string
  end
end
