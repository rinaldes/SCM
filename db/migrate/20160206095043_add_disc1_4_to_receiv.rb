class AddDisc14ToReceiv < ActiveRecord::Migration
  def change
    add_column :receivings, :discount1, :float
    add_column :receivings, :discount2, :float
    add_column :receivings, :discount3, :float
    add_column :receivings, :discount4, :float
  end
end
