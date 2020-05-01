class AddShortNameInProduct < ActiveRecord::Migration
  def change
    add_column :products, :short_name, :string, length: 40
  end
end
