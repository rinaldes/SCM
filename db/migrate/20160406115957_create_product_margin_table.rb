class CreateProductMarginTable < ActiveRecord::Migration
  def change
    create_table :product_margins do |t|
      t.integer :code
      t.integer :product_id
      t.integer :branch_id
      t.integer :office_id
      t.float :margin
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
