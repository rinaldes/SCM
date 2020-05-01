class CreatePlanogramsStores < ActiveRecord::Migration
  def change
    create_table :planograms_stores do |t|
      t.integer :planogram_id
      t.integer :branch_id
      t.timestamps
    end
  end
end
