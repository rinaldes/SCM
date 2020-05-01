class AddZfoodIdToZfd < ActiveRecord::Migration
  def change
    add_column :zfood_details, :zfood_id, :integer
  end
end
