class AddStatus5ToProducts < ActiveRecord::Migration
  def change
    add_column :products, :status5, :string #Private, Normal
  end
end
