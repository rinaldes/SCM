class Api::MobileOrdersController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def create
    transaction = []
    first_detail = ActiveSupport::JSON.decode(params[:transactions]).first
#    Transaction.delete_all
    MobileOrder.api(params[:transactions])
    render json: {status: 'success'}, status: 200
  end

private
  def get_paginated_transactions
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @transactions = Transaction.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))
      .select("transactions.*")
      .paginate(:page => params[:page], :per_page => 10) || []
  end
end
