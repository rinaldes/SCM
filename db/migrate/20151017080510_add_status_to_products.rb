class AddStatusToProducts < ActiveRecord::Migration
  def change
    add_column :products, :status1, :string
    add_column :products, :status3, :string
  end
end
