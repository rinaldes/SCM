class CreateProvinces < ActiveRecord::Migration
  def change
    create_table :provinces do |t|
      t.string :code
      t.string :name
      t.timestamps
    end
  end
end
