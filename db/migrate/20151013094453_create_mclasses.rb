class CreateMclasses < ActiveRecord::Migration
  def change
    create_table :mclasses do |t|
    	t.string :code
      t.string :name
      t.integer :department_id
      t.integer :parent_id
      t.timestamps
    end
  end
end
