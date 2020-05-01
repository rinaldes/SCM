class AddColumnsToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :name, :string
    add_column :vouchers, :valid_from, :date
    add_column :vouchers, :valid_until, :date
    add_column :vouchers, :min_amount, :float
    add_column :vouchers, :discount, :float
    add_column :vouchers, :is_percent, :boolean
    add_column :vouchers, :max_Voucher, :float
    add_column :vouchers, :is_max_pcs, :boolean
    add_column :vouchers, :is_multiple, :boolean
    add_column :vouchers, :branch_id, :integer
    add_column :vouchers, :term_condition, :text
    add_column :vouchers, :is_active, :boolean
  end
end
