class CreatePrFeedbackDetails < ActiveRecord::Migration
  def change
    create_table :pr_feedback_details do |t|
      t.integer :quantity
      t.float :price
      t.integer :pr_feedback_id
      t.timestamps
    end
  end
end
