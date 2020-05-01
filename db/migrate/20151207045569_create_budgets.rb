class CreateBudgets < ActiveRecord::Migration
  def change
    create_table :budgets do |t|
    	t.date :year
      t.float :monthly_budget
      t.float :initial_budget
      t.float :additional_budget
      t.float :realization
      t.float :realization_in_percent
      t.timestamps
    end
  end
end
