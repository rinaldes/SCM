class CancelItemsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :find_receipt, only: [:show, :mark_as_inspected, :print_to_pdf]
  before_filter :can_view_purchase_summary, only: [:index, :show]

  def index
    get_paginated_receivings
    @filenames = params[:controller]
    @filenames << '_' + Office.find(params[:store]).office_name if params[:store].present?
    @filenames << '_from_' + params[:start_date] if params[:start_date].present?
    @filenames << '_until_' + params[:end_date] if params[:end_date].present?
    respond_to do |format|
      format.html
      format.js
      format.xls{ headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}.xls\""}
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

  def search_receiving
    get_paginated_receivings
    respond_to do |format|
      format.js
    end
  end

private
  def get_paginated_receivings
    conditions = []
      conditions << "cancel_items.store_id = #{params[:store]}" if params[:store].present?
      conditions << "cancel_items.cancel_date >= '#{params[:start_date].to_date.strftime('%Y-%m-%d')}'" if params[:start_date].present?
      conditions << "cancel_items.cancel_date <= '#{params[:end_date].to_date.strftime('%Y-%m-%d')}'" if params[:end_date].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
      @receivings = CancelItem.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))
      .joins(product_detail: :product).joins(:store, :user)
      .select("cancel_items.*, products.description as description, office_name,products.article as article, to_char(cancel_items.quantity, '999') As c_quantity")
      .paginate(:page => params[:page], :per_page => 10) || []  
  end

  def can_view_purchase_summary
    not_authorized unless current_user.can_view_cancel_item_report?
  end
end