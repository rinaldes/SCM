class CreatePlanograms < ActiveRecord::Migration
  def change
    create_table :planograms do |t|
      t.integer :office_id
      t.string :rack_number
      t.string :rack_type
      t.timestamps
    end
  end
end
