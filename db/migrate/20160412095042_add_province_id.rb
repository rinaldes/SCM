class AddProvinceId < ActiveRecord::Migration
  def change
    add_column :locations,:province_id ,:integer
  end
end
