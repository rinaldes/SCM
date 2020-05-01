class CreateMonthlyBudgets < ActiveRecord::Migration
  def change
    create_table :monthly_budgets do |t|
    	t.integer :budget_id
      t.integer :month_number
      t.float :initial_budget
      t.float :additional_budget
      t.float :realization
      t.float :realization_in_percent
      t.timestamps
    end
  end
end
