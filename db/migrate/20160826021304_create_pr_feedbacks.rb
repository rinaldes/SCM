class CreatePrFeedbacks < ActiveRecord::Migration
  def change
    create_table :pr_feedbacks do |t|
      t.integer :supplier_id
      t.timestamps
    end
  end
end
