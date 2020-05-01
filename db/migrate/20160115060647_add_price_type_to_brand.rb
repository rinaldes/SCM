class AddPriceTypeToBrand < ActiveRecord::Migration
  def change
    add_column :brands, :price_type, :string
  end
end
