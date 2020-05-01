class AddStatusReturToProducts < ActiveRecord::Migration
  def change
    add_column :products, :status_retur, :boolean, default: false
  end
end
