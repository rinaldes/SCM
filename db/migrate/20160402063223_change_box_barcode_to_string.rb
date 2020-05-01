class ChangeBoxBarcodeToString < ActiveRecord::Migration
  def change
    change_column :products, :box_barcode, :string
    change_column :products, :box2_barcode, :string
  end
end
