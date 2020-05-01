class TransactionHistoriesController < ApplicationController

  def index
    get_transaction_histories
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @transaction_history = Sale.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def search
    @transaction_histories = TransactionHistory.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @transaction_history = TransactionHistory.new
      format.js
    end
  end

  def get_number
    @transaction_history_number = TransactionHistory.number(params)
    respond_to do |format|
      format.js
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

private
  def get_transaction_histories
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @transaction_histories = Sale.where(conditions.join(' AND ')).order(default_order('sales')).paginate(:page => params[:page], :per_page => 10) || []
  end
end