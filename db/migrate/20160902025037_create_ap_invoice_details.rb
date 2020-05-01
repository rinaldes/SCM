class CreateApInvoiceDetails < ActiveRecord::Migration
  def change
    create_table :ap_invoice_details do |t|
      t.integer :ap_invoice_id
      t.integer :store_id
      t.integer :receiving_id
      t.string :tax_code
      t.string :tax_number
      t.date :tax_date
      t.float :gross
      t.float :vat
      t.float :amount
      t.timestamps
    end
  end
end
