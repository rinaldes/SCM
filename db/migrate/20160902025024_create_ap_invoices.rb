class CreateApInvoices < ActiveRecord::Migration
  def change
    create_table :ap_invoices do |t|
      t.string :number
      t.integer :supplier_id
      t.float :dpp
      t.float :ppn
      t.float :total
      t.date :due_date
      t.timestamps
    end
  end
end
