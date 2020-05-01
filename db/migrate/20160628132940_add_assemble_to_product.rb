class AddAssembleToProduct < ActiveRecord::Migration
  def change
    add_column :products, :is_composite, :boolean
  end
end
