class CreateSizes < ActiveRecord::Migration
  def change
    create_table :sizes do |t|
      t.text :description
      t.string :code
      t.timestamps
    end
  end
end
