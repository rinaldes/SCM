class AddOfficeIdToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :office_id, :integer
  end
end
