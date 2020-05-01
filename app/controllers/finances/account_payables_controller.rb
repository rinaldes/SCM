class Finances::AccountPayablesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_account_payables, only: [:index, :destroy]
  before_filter :prepare_account_payable, only: [:edit, :update, :destroy, :show]
  before_filter :can_view_account_payable, only: [:index, :show]
  before_filter :can_manage_account_payable, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  add_crumb("Account Payable".html_safe, only: ["index", "new", "create", "edit", "update", "show"]) { |instance| instance.send :finances_account_payables_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finances_account_payables_path }
  add_crumb("New".html_safe, only: ["new", "create"]) { |instance| instance.send :new_finances_account_payable_path }

  def index
  end

  def show
  end

  def update
    other_charges = params[:account_payable][:other_charges_attributes]
    other_charges.each do |other, index|
      params[:account_payable][:other_charges_attributes][other][:amount] = params[:account_payable][:other_charges_attributes][other][:amount].gsub(/,/, '').to_f
    end if other_charges.present?

    params[:account_payable][:account_payable_details_attributes]['0'][:amount] =  params[:account_payable][:account_payable_details_attributes]['0'][:amount].gsub(/,/, '').to_f

    if @account_payable.update_attributes(account_payable_params)
      @account_payable.recalculate_account_payable
      # ToDo: Need to be refactored.
=begin
      receiving_details = params[:receiving][:receiving_details]
      receiving_details.first.each do |key, value|
        @account_payable.receiving.receiving_details.where(:id => key).first.update_attributes(:paid_off => value)
      end unless receiving_details.blank?
=end
      flash[:notice] = 'Account Payable was successfully created.'
    else
      flash[:error] = @account_payable.errors.full_messages
    end
    redirect_to finances_account_payable_path(@account_payable)
  end

  def destroy
    @account_payable.destroy unless @account_payable.blank?
  end

 private
  def account_payable_params
    params.require(:account_payable).permit(:id, :payment_tempo, :outstanding_amount, account_payable_details_attributes: [:id, :account_payable_id, :amount, :payment_date, :method, :bank, :giro_number, :note, :_destroy], other_charges_attributes: [:id, :name, :amount, :_destroy])
  end

  def prepare_account_payables
    ap_number = params[:by_ap_number]
    due_date = params[:by_due_date]
    supplier_name = params[:by_supplier_name]

    results = AccountPayable.in_ap_number(ap_number).in_due_date(due_date).in_supplier_name(supplier_name).order('created_at DESC')
    @account_payables = results.page(params[:page]).per(PER_PAGE)
  end

  def prepare_account_payable
    @account_payable = AccountPayable.find(params[:id])
  end

  def can_view_account_payable
    not_authorized unless current_user.can_view_account_payable?
  end

  def can_manage_account_payable
    not_authorized unless current_user.can_manage_account_payable?
  end
end
