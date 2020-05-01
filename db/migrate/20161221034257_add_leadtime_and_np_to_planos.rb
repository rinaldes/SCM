class AddLeadtimeAndNpToPlanos < ActiveRecord::Migration
  def change
    Plano.reset_column_information
    add_column :planos, :leadtime, :integer  unless Plano.column_names.include?('leadtime')
    add_column :planos, :nplus, :integer unless Plano.column_names.include?('nplus')
  end
end
