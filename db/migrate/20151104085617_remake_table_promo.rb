class RemakeTablePromo < ActiveRecord::Migration
  def change
  	drop_table :promotions
  	create_table :promotions do |t|
      t.string :code
      t.string :name
      t.date :from
      t.date :to
      t.integer :min
      t.integer :max
      t.string :branch
      t.string :multi
      t.timestamps
    end
  end
end
