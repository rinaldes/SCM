class AddLastPrintToSellingPriceDetails < ActiveRecord::Migration
  def change
    add_column :selling_price_details, :last_print, :datetime
  end
end
