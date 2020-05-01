class CreateProductMutations < ActiveRecord::Migration
  def change
    create_table :product_mutations do |t|
      t.integer :origin_warehouse_id
      t.integer :destination_warehouse_id
      t.string :status
      t.date :mutation_date
      t.integer :receiver_id
      t.date :received_date
      t.string :code
      t.integer :sender_id
      t.string :no_surat_jalan
      t.string :type #ProductMutation, 
      t.timestamps
    end
  end
end
