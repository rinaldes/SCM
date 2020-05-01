class RenamePsToPRtsd < ActiveRecord::Migration
  def change
    rename_column :returns_to_supplier_details, :product_size_id, :product_id
  end
end
