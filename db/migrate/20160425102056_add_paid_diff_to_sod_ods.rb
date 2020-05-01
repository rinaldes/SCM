class AddPaidDiffToSodOds < ActiveRecord::Migration
  def change
    add_column :sod_eods, :paid_difference, :float
    add_column :sod_eods, :ppn, :float
    add_column :sod_eods, :receipt_count, :integer
    remove_column :sod_eods, :cash
    add_column :sod_eods, :cash, :float
  end
end
