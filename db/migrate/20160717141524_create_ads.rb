class CreateAds < ActiveRecord::Migration
  def change
    create_table :ads do |t|
      t.string :url
      t.string :ad_type
      t.date :valid_from
      t.date :valid_until
      t.string :store  
      t.timestamps
    end
  end
end
