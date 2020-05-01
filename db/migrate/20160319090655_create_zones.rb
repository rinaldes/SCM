class CreateZones < ActiveRecord::Migration
  def change
    create_table :zones do |t|
    	t.string :code
    	t.string :name
    	t.text   :description
    	t.string :type
    	t.timestamps
    end
  end
end
