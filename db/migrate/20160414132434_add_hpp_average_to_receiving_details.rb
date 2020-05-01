class AddHppAverageToReceivingDetails < ActiveRecord::Migration
  def change
    add_column :receiving_details, :hpp_average, :float
  end
end
