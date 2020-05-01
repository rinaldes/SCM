class AddColourCodeToProduct < ActiveRecord::Migration
  def change
    add_column :products, :colour_code, :string
  end
end
