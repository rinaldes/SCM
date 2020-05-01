class CreateZfoods < ActiveRecord::Migration
  def change
    create_table :zfoods do |t|
      t.integer :product_detail_id
      t.timestamps
    end
  end
end
