class PlanosController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_plano, only: [:index, :show]
  before_filter :can_manage_plano, only: [:new, :create, :edit, :update]

  def index
    get_paginated_planos
    @filenames = "Rack Display"
    if request.format.xls? || request.format.xlsx?
      @filenames << '_' + Office.find(params[:store]).office_name if (params[:store].present? && (Office.find(params[:store]).present? rescue false))
    end
    respond_to do |format|
      format.html
      format.js
      format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}.xls\""}
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}.xlsx\"" }
      if(params[:a] == "a")
        format.csv { send_data Plano.all.to_csv2 }
      else
        format.csv { send_data @planos.to_csv(@planos, {}) }
      end
    end
  end

  def autogenerate_type
    rak = Planogram.find(params[:idnya])
    @rak_type = rak.rack_type
    respond_to do |plano|
      plano.js
    end
  end

  def generate_auto_pkm
    begin
      Plano.calculate_pkm
      redirect_to planos_path
    rescue Exception => e
      flash[:error] = "#{e}. Perhitungan Otomatis PKM Gagal. Pastikan data-data yang diperlukan seperti Safety stock, minor, dll sudah terisi."
      redirect_to planos_path
    end
  end

  def import
    import_result = Plano.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to planos_path
  end

  def show
    @plano = Plano.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def get_planogram_type
    @plano = PlanogramsStore.find_by_planogram_id(params[:id])
    p_id = Product.find_by_barcode(params[:product_id]).id
    @pd = ProductDetail.find_by_product_id_and_warehouse_id(p_id, @plano.branch_id)
  end

  def get_spd
    product_detail = ProductDetail.find_by_product_id_and_warehouse_id(params[:product_id],params[:store_id])

    # ambil dari Receiving pertama
    rcd = ReceivingDetail.where("product_id = #{product_detail.product_id} AND receivings.head_office_id IN (#{params[:store_id].join(',')})").joins(:receiving)

    if rcd.present?
      created_at = rcd.first.created_at
    else
      # jika tidak ada, maka ambil dari TaT pertama
      tat = ProductMutationDetail.where("product_id = #{product_detail.product_id} AND product_mutations.destination_warehouse_id = #{product_detail.warehouse_id}").joins(:product_mutation)

      if tat.present?
        created_at = tat.first.created_at
      else
        created_at = Date.today.beginning_of_month - 3.month
      end
    end
    spd = SalesDetail.select(
      "round(AVG(quantity), 2) AS averages").where(
      "to_char(transaction_date, 'YYYY-MM-DD') BETWEEN '#{created_at}' AND '#{Date.today.end_of_month}' AND
      product_id = (select product_id from product_details where id = #{product_detail.id} limit 1)"
      ).joins(:sale).order("averages")
    @spd = spd.first
  end

  def new
    @offices = Office.active_store
    @plano = Plano.new(params[:plano])
    respond_to do |format|
      format.html
    end
  end

  def edit
    @offices = Office.active_store
    @plano = Plano.find(params[:id])
    @spd = SalesDetail.select(
      "round(AVG(quantity), 2) AS averages").where(
      "to_char(transaction_date, 'YYYY-MM-DD') BETWEEN '#{Date.today.beginning_of_month - 3.month}' AND '#{Date.today.end_of_month}' AND
      product_id = (select product_id from product_details where id = #{@plano.product_detail_id} limit 1)"
      ).joins(:sale).order("averages").first
    respond_to do |format|
      format.html
    end
  end

  def create
    @plano = Plano.new(plano_params)
    if @plano.valid?
      params[:rackdis][:office_id].each do |oid|
        @pd = ProductDetail.find_by_product_id_and_warehouse_id(params[:plano][:product_id], oid)
        @pd.update_attributes!(
          min_stock: params[:product_details][:min_stock],
          rop_stock: params[:product_details][:rop_stock],
          max_stock: params[:product_details][:max_stock]
        )
        @plano = Plano.create(plano_params.merge(product_detail_id: @pd.id))
      end
      flash[:notice] = 'Plano was successfully created'
      redirect_to planos_path
    else
      @offices = Office.active_store
      flash[:error] = @plano.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def update
    @plano = Plano.find(params[:id])
    if @plano.update_attributes(plano_params)
      flash[:notice] = 'Plano was successfully created'
      redirect_to planos_path
    else
      flash[:error] = @plano.errors.full_messages.join('<br/>')
      render "edit"
    end
  end

  def destroy
    @plano = Plano.find(params[:id])
    if @plano.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete plano"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete plano. data in used"
    end
    get_paginated_planos
    respond_to do |format|
      format.js
    end
  end

  def search
    @planos = Plano.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @plano = Plano.new
      format.js
    end
  end

  def get_number
    @plano_number = Plano.number(params)
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
  def plano_params
    params.require(:plano).permit(
      :code, :product_id, :start, :end, :rak_id, :rak_type, :shelving, :kir_ka,
      :at_ba, :de_be, :min, :rows, :product_detail_id, :nplus, :leadtime
    )
  end

  def can_view_plano
    not_authorized unless current_user.can_view_planogram?
  end

  def can_manage_plano
    not_authorized unless current_user.can_manage_planogram?
  end
end
