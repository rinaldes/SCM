class AddSalesIdToAr < ActiveRecord::Migration
  def change
    add_column :account_receivables, :sale_id, :integer
  end
end
