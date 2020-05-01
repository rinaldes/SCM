class PosMachineAddColumn < ActiveRecord::Migration
  def change
    add_column :pos_machines, :hide_empty_stock, :boolean
    add_column :pos_machines, :enable_ppn, :boolean
    add_column :pos_machines, :enable_minus_stock, :boolean
    add_column :pos_machines, :enable_loss_price, :boolean
    add_column :pos_machines, :receipt_footer, :string
    add_column :pos_machines, :eod_footer, :string
  end
end