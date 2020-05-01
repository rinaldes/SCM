class CreateCustomStatuses < ActiveRecord::Migration
  def change
    create_table :custom_statuses do |t|
      t.string :name
      t.timestamps
    end
  end
end
