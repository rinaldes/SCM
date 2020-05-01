class AddCityToBankAccount < ActiveRecord::Migration
  def change
    add_column :bank_accounts, :city, :string
  end
end