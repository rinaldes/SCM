class ChangeArticleToString < ActiveRecord::Migration
  def change
    change_column :promo_item_lists, :article_id, :string
  end
end
