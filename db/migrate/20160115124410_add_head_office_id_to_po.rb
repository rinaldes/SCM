class AddHeadOfficeIdToPo < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :head_office_id, :integer
  end
end
