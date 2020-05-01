class CreateMonthlyForecastDetails < ActiveRecord::Migration
  def change
    create_table :monthly_forecast_details do |t|
      t.date :forecast_date
      t.integer :monthly_forecast_id
      t.integer :department_id
      t.float :qty
      t.float :amount
      t.float :realization_qty
      t.float :realization_amount
      t.float :qty_in_percent
      t.float :amount_in_percent
      t.timestamps
    end
  end
end