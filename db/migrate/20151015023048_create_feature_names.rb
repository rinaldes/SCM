class CreateFeatureNames < ActiveRecord::Migration
  def change
    create_table :feature_names do |t|
      t.string :name
      t.timestamps
    end
  end
end
