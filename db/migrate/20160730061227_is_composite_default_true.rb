class IsCompositeDefaultTrue < ActiveRecord::Migration
  def change
    change_column :products, :is_composite, :boolean, default: true
  end
end
