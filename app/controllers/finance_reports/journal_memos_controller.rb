class FinanceReports::JournalMemosController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_journal_memos, only: [:index, :export]
  before_filter :can_manage_journal_memo_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Journal Memo Report".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_journal_memos_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_journal_memos_path }

  def index
    respond_to do |format|
      format.html
    end
  end

  def export
    filename = "Journal Memo Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_journal_memos
      @journal_memos = Receiving.get_journal_memos
    end

    def can_manage_journal_memo_report
      not_authorized unless current_user.can_manage_journal_memo_report?
    end
end
