class AddBktAndReturToProduct < ActiveRecord::Migration
  def change
    add_column :products, :is_bkt, :boolean
  end
end