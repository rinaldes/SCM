class CreateMonthlySalesInventories < ActiveRecord::Migration
  def change
    create_table :monthly_sales_inventories do |t|
      t.integer :product_id
      t.integer :month
      t.integer :year
      t.integer :office_id
      t.float :start_amount
      t.float :start_qty
      t.float :sales_amount
      t.float :sales_qty
      t.float :retur_sales_amount
      t.float :retur_sales_qty
      t.float :gr_amount
      t.float :gr_qty
      t.float :tat_in_amount
      t.float :tat_in_qty
      t.float :tat_out_amount
      t.float :tat_out_qty
      t.float :retur_amount
      t.float :retur_qty
      t.float :so_amount
      t.float :so_qty
      t.float :end_amount
      t.float :end_qty
      t.float :cost
      t.float :avg_cost
      t.float :last_cost
      t.timestamps
    end
  end
end
