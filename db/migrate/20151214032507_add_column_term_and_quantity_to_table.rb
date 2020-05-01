class AddColumnTermAndQuantityToTable < ActiveRecord::Migration
  def change
    add_column :ar_vouchers, :quantity, :integer
    add_column :ar_vouchers, :term, :string
  end
end
