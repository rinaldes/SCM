class RemovingStatus2InPd < ActiveRecord::Migration
  def change
    remove_column :product_details, :status2
  end
end
