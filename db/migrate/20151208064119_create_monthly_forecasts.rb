class CreateMonthlyForecasts < ActiveRecord::Migration
  def change
    create_table :monthly_forecasts do |t|
      t.integer :forecast_id
      t.integer :month_number
      t.float :qty
      t.float :amount
      t.float :realization_qty
      t.float :realization_amount
      t.float :qty_in_percent
      t.float :amount_in_percent
      t.integer :department_id
      t.timestamps
    end
  end
end