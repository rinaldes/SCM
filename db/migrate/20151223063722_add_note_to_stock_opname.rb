class AddNoteToStockOpname < ActiveRecord::Migration
  def change
    add_column :stock_opnames, :note, :string
  end
end
