class AddNoteToRtho < ActiveRecord::Migration
  def change
    add_column :product_mutations, :note, :string
  end
end
