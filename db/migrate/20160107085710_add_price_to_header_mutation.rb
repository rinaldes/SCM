class AddPriceToHeaderMutation < ActiveRecord::Migration
  def change
    add_column :product_mutations, :total_price, :float
    add_column :product_mutations, :total_quantity, :integer
  end
end
