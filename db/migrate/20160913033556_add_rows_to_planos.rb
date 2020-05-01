class AddRowsToPlanos < ActiveRecord::Migration
  def change
    add_column :planos, :rows, :integer, after: :min
  end
end
