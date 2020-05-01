class CreateSettingPointMembers < ActiveRecord::Migration
  def change
    create_table :setting_point_members do |t|
      t.integer :point
      t.integer :price
      t.text :description
      t.integer :user_id
      t.date :expired_date

      t.timestamps
    end
  end
end
