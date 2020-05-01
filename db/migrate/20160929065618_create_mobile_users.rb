class CreateMobileUsers < ActiveRecord::Migration
  def change
    create_table :mobile_users do |t|
      t.string :phone
      t.string :name
      t.string :password
      t.timestamps
    end
  end
end
