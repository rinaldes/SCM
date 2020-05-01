class CreateReturnToHos < ActiveRecord::Migration
  def change
    create_table :return_to_hos do |t|
    	t.date :date
      t.string :status
      t.string :number
      t.integer :head_office_id
      t.timestamps
    end
  end
end
