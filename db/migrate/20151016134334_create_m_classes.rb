class CreateMClasses < ActiveRecord::Migration
  def change
    create_table :m_classes do |t|

      t.timestamps
    end
  end
end
