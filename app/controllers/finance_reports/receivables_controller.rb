class FinanceReports::ReceivablesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_receivables, only: [:index, :export]
  before_filter :can_manage_receivable_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Account Receivable Report".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_receivables_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_receivables_path }

  def index
  end

  def export
    filename = "Account Receivable Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_receivables
      @members = Member.all
      @member_id = params[:member_id].blank? ? @members.first.try(:id) : params[:member_id]
      @member_name = Member.find_by_id(@member_id).try(:name)
      results = Payment.get_report_receivables(@member_id).order('created_at')
      @payments = results.page(params[:page]).per(PER_PAGE)
      @get_total_account_receivables = AccountReceivable.get_total_account_receivables(@member_id)
    end

    def can_manage_receivable_report
      not_authorized unless current_user.can_manage_receivable_report?
    end
end
