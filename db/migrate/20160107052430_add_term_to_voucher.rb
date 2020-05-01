class AddTermToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :term, :string
  end
end
