class CreateForecasts < ActiveRecord::Migration
  def change
    create_table :forecasts do |t|
      t.integer :branch_id
      t.date :date
      t.integer :target_qty
      t.integer :target_amount
      t.integer :realization_qty
      t.float :realization_amount
      t.integer :department_id
      t.timestamps
    end
  end
end
