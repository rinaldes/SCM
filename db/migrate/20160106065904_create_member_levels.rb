class CreateMemberLevels < ActiveRecord::Migration
  def change
    create_table :member_levels do |t|
      t.integer :level
      t.string :description
      t.float :minimum_amount
      t.float :discount_percent
      t.timestamps
    end
  end
end
