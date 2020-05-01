class AddColumn < ActiveRecord::Migration
  def change
    add_column :product_structures, :code, :string
  end
end
