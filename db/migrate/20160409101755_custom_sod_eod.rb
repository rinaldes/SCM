class CustomSodEod < ActiveRecord::Migration
  def change
    add_column :sod_eods, :start_100k, :integer
    add_column :sod_eods, :start_50k, :integer
    add_column :sod_eods, :start_20k, :integer
    add_column :sod_eods, :start_10k, :integer
    add_column :sod_eods, :start_5k, :integer
    add_column :sod_eods, :start_2k, :integer
    add_column :sod_eods, :start_1k, :integer
    add_column :sod_eods, :start_500, :integer
    add_column :sod_eods, :start_200, :integer
    add_column :sod_eods, :start_100, :integer
    add_column :sod_eods, :start_50, :integer
    add_column :sod_eods, :end_100k, :integer
    add_column :sod_eods, :end_50k, :integer
    add_column :sod_eods, :end_20k, :integer
    add_column :sod_eods, :end_10k, :integer
    add_column :sod_eods, :end_5k, :integer
    add_column :sod_eods, :end_2k, :integer
    add_column :sod_eods, :end_1k, :integer
    add_column :sod_eods, :end_500, :integer
    add_column :sod_eods, :end_200, :integer
    add_column :sod_eods, :end_100, :integer
    add_column :sod_eods, :end_50, :integer
    add_column :sod_eods, :total_sales, :float
    add_column :sod_eods, :debit, :float
    add_column :sod_eods, :credit, :float
    add_column :sod_eods, :transfer, :float
    add_column :sod_eods, :voucher, :float
    add_column :sod_eods, :retur, :float
    add_column :sod_eods, :discount, :float
    add_column :sod_eods, :special_discount, :float
    add_column :product_details, :product_size_id, :integer
  end
end
