class AddColumnPettyCash < ActiveRecord::Migration
  def change
    add_column :petty_cashes, :year, :date
    add_column :petty_cashes, :month, :date
  end
end
