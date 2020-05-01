class AddReceivedQtyToPmd < ActiveRecord::Migration
  def change
    add_column :product_mutation_details, :received_qty, :integer
  end
end
