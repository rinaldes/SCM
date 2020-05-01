class AddHasPrintedDpeToReceivings < ActiveRecord::Migration
  def change
    add_column :receivings, :has_printed_dpe, :boolean, :default => false
  end
end
