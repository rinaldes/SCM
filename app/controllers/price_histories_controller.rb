class PriceHistoriesController < ApplicationController
  
  def index
  	@price_histories = PriceHistory.where.not('price_histories.harga_lama' => 'price_histories.harga_baru')
    respond_to do |format|
      format.html
    end
  end

end