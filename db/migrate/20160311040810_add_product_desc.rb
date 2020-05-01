class AddProductDesc < ActiveRecord::Migration
  def change
    add_column :products, :description, :string
    add_column :products, :description_2, :string
  end
end
