class AddCashTypeToCashOut < ActiveRecord::Migration
  def change
    add_column :cash_outs, :cash_out_type, :string #ATK / RTK / OPERASIONAL / MAINTENANCE / LAIN-LAIN
  end
end
