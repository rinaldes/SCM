class FavoriteProduct < ActiveRecord::Base
	belongs_to :mobile_user
	belongs_to :product

	validates :mobile_user_id, :presence => {message: 'required'}
	validates :product_id, :presence => {message: 'required'}
  
  def self.api(params)
    begin
      ActiveSupport::JSON.decode(params).each do |fp|
      	user_id = MobileUser.find(fp["user_id"]).id
      	prod_id = Product.find(fp["product_id"]).id
      	if FavoriteProduct.find_by_mobile_user_id_and_product_id(user_id, prod_id).nil?
	        favo = self.new()
	        favo.mobile_user_id = user_id
          favo.product_id = prod_id
	        favo.quantity = fp["quantity"]
	        favo.save!
        else
          favo = FavoriteProduct.find_by_mobile_user_id_and_product_id(user_id, prod_id)
          favo.quantity = favo.quantity.to_i + fp["quantity"].to_i
          favo.save
	      end
      end
      error = ""
      status = "success"
    rescue => e
      error = e.message
      status = "failed"
    end
    return error, status
  end

end