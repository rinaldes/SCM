class AddCodeToZfood < ActiveRecord::Migration
  def change
    add_column :zfoods, :code, :string
  end
end
