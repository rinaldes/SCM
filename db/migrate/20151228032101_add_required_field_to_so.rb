class AddRequiredFieldToSo < ActiveRecord::Migration
  def change
    add_column :stock_opnames, :system_stock, :integer
    add_column :stock_opnames, :sold, :integer
    add_column :stock_opnames, :received_from_transfer, :integer
    add_column :stock_opnames, :mutation_in, :integer
    add_column :stock_opnames, :mutation_out, :integer #Mutasi Barang, Transfer Barang, Return to HO, Return to Supplier
    add_column :stock_opnames, :last_stock, :integer
    rename_column :stock_opnames, :date, :start_date
    change_column :stock_opnames, :start_date, :datetime
    add_column :stock_opnames, :end_date, :datetime
    add_column :stock_opnames, :actual_stock, :integer
    add_column :stock_opname_details, :sold, :integer
    add_column :stock_opname_details, :received_from_transfer, :integer
    add_column :stock_opname_details, :retur, :integer
    add_column :stock_opname_details, :mutation_in, :integer
    add_column :stock_opname_details, :mutation_out, :integer
  end
end
