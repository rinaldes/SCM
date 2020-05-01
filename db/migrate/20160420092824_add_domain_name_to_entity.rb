class AddDomainNameToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :domain_name, :string
  end
end
