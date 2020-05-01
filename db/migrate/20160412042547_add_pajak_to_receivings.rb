class AddPajakToReceivings < ActiveRecord::Migration
  def change
    add_column :receivings, :pajak, :float
  end
end
