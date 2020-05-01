class CreateProductPlanograms < ActiveRecord::Migration
  def change
    create_table :product_planograms do |t|
      t.integer :planogram_id
      t.integer :product_id
      t.string :stock

      t.timestamps
    end
  end
end
