class AddConsigmentNoToReceiv < ActiveRecord::Migration
  def change
    add_column :receivings, :consigment_number, :string
  end
end
