class MonthEndsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]

  def index
  end

  def report
    conditions = []
    conditions2 = []
    conditions << "EXTRACT(MONTH FROM date) = '#{params[:bulan]}'" if params[:bulan].present?
    conditions << "EXTRACT(YEAR FROM date) = '#{params[:tahun]}'" if params[:tahun].present?
    conditions2 << "EXTRACT(MONTH FROM transaction_date) = '#{params[:bulan]}'" if params[:bulan].present?
    conditions2 << "EXTRACT(YEAR FROM transaction_date) = '#{params[:tahun]}'" if params[:tahun].present?
    @periode = params[:tahun].to_s + params[:bulan].to_s if params[:tahun].present? && params[:bulan].present?
    @periode2 = Date.civil(params[:tahun].to_i, params[:bulan].to_i, -1).strftime("%d/%m/%Y") if params[:tahun].present? && params[:bulan].present?
    @receivings = Receiving.where(conditions.join(' AND ')).order('date ASC')
      .select("id, supplier_id, head_office_id, number, date, 'G' as flag_type") || []
    @returns = ReturnsToSupplier.where(conditions.join(' AND ')).order('date ASC')
      .select("id, supplier_id, head_office_id, number, date, 'R' as flag_type") || [] 
    @sales = Sale.select("offices.code AS kode_toko, SUM(capital_price*quantity) AS capital_price")
      .joins(:store, :sales_details).group("offices.code").where(conditions2.join(' AND ')).order("offices.code ASC")

    respond_to do |format|
      format.xls {
          response.headers['Content-Disposition'] = "attachment; filename=\"ME #{('01/'+params[:bulan]+'/'+params[:tahun]).to_date.strftime('%B %Y')}.xls\""
      }
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"ME #{('01/'+params[:bulan]+'/'+params[:tahun]).to_date.strftime('%B %Y')}.xlsx\"" }
    end
  end
end