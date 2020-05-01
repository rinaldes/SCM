class RenameColumnDateOnForecasts < ActiveRecord::Migration
  def change
    rename_column :forecasts, :date, :year
  end
end
