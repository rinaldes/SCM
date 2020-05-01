class AddStatus2ToProduct < ActiveRecord::Migration
  def change
    add_column :products, :status2, :string
  end
end
