class StockOpnameDetailsController < ApplicationController

  def import
    if params[:file].present? && params[:file].original_filename.split('.')[1] == 'csv'
      begin
        flash[:notice] = StockOpnameDetail.import(params[:file], params[:id])
      rescue
        flash[:error] = "Import CSV failed. Please recheck the CSV file"
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to edit_stock_opname_url(params[:id])
  end

  def index
    @stock_opname_details = StockOpname.find(params[:id])
    filename = "Stock Opname " + @stock_opname_details.opname_number + ".xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
      format.xls
      if(params[:a] == "a")
        format.csv { send_data StockOpnameDetail.where(stock_opname_id: params[:id]).to_csv2(params[:id]) }
      else
        format.csv { send_data StockOpnameDetail.to_csv(params[:id]) }
      end
    end
  end

end