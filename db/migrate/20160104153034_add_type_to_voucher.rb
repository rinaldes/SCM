class AddTypeToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :type, :string
  end
end
