class CreatePrizeLists < ActiveRecord::Migration
  def change
    create_table :prize_lists do |t|
    	t.integer :department_id
    	t.integer :mclass_id
    	t.integer :brand_id
    	t.integer :article_id
    	t.integer :max_qty
      t.timestamps
    end
  end
end
