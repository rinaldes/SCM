class CreateReturnsToHoDetails < ActiveRecord::Migration
  def change
    create_table :returns_to_ho_details do |t|
      t.string :code
      t.string :name
      t.string :article
      t.string :colour
      t.string :dept
      t.float :total
      t.integer :qty
      t.string :status, default: "pending"
      t.timestamps
    end
  end
end
