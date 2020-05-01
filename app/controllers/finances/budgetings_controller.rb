class Finances::BudgetingsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_budgets, only: [:index, :destroy]
  before_filter :prepare_budget, only: [:edit, :update, :destroy, :show]
  before_filter :can_view_budget, only: [:index, :show]
  before_filter :can_manage_budget, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  add_crumb("Budgeting".html_safe, only: ["index", "new", "create", "edit", "update", "show"]) { |instance| instance.send :finances_budgetings_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finances_budgetings_path }
  add_crumb("New".html_safe, only: ["new", "create," "show"]) { |instance| instance.send :new_finances_budgeting_path }

  def index
  end

  def new
    @budget = Budget.new
  end

  def create
    @budget = Budget.new(budget_params)
    if @budget.save
      flash[:notice] = 'Budget was successfully updated.'
      redirect_to finances_budgetings_path
    else
      flash[:error] = @budget.errors.full_messages
      render :new
      # redirect_to finances_budgetings_path
    end
  end

  def show
  end

  def edit
  end

  def update
    if @budget.update_attributes(budget_params)
        redirect_to finances_budgeting_path(@budget.id)
    else
      render :edit
    end
  end

  def destroy
    @budget.destroy unless @budget.blank?
  end

 private

  def budget_params
    params.require(:budget).permit(:year, :monthly_budget , monthly_budgets_attributes: [:name, :id, :month_number, :budget, :initial_budget, :additional_budget, :realization, :_destroy])
  end

  def prepare_budgets
    @budgetings = Budget.page(params[:page]).order('year DESC').per(PER_PAGE)
  end

  def prepare_budget
    @budget = Budget.find(params[:id])
  end

  def can_view_budget
    not_authorized unless current_user.can_view_budget?
  end

  def can_manage_budget
    not_authorized unless current_user.can_manage_budget?
  end

end
