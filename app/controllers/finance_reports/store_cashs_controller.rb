class FinanceReports::StoreCashsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_store_cashs, only: [:index, :export]
  before_filter :can_manage_store_cash_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Store Cash Report".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_store_cashs_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_store_cashs_path }

  def index
    respond_to do |format|
      format.html
    end
  end

  def export
    filename = "Store Cash Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_store_cashs
      # results = AccountPayable.in_receiving.order('created_at DESC')
      # @account_payables = results.page(params[:page]).per(PER_PAGE)
    end

    def can_manage_store_cash_report
      not_authorized unless current_user.can_manage_store_cash_report?
    end
end
