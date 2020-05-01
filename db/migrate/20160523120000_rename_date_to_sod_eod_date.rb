class RenameDateToSodEodDate < ActiveRecord::Migration
  def change
    rename_column :sod_eods, :date, :sod_eod_date
  end
end
