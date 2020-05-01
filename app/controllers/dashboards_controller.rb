class DashboardsController < ApplicationController
  # before_action :get_blast_messages
  def daily_sales
    branches_conditions = []
    branches_conditions << "id=#{@current_user.branch_id}" if @current_user.branch_id.present?
    @branches = Branch.where(branches_conditions.join(' AND '))
    time = Time.now
    date = time.strftime("%Y%m")

    val = []
    @branches.each_with_index do |branch, i|
      conditions = ["quantity>0"]
      conditions << "store_id='#{branch.id}'"
      conditions << "to_char(transaction_date, 'YYYYMM')='#{date}'"

      sales = Sale.select("to_char(transaction_date, 'DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price")
                  .joins(:store, :sales_details).group("to_char(transaction_date, 'DD')").where(conditions.join(' AND ')).order("transaction_date ASC")

      val << {
        name: branch.office_name,
        data: (1..time.day).map{|x|0}
      }

      sales.map do |s|
        val[-1][:data][s.transaction_date.to_i - 1] = (params[:text] == "Price" ? s.total_price : s.total_quantity)
      end
    end

    render json: {day: (1..time.day).map{|x|x.to_s}, values: val}
  end

  def category_sales
    time = Time.now
    date = time.strftime("%Y%m")

    val = []
    if params[:text] == 'Department'
      @categories = MClass.where(level: 0)
      @categories.each_with_index do |cat, i|
        conditions = ["quantity>0"]
        conditions << "products.department_id='#{cat.id}'"
        conditions << "to_char(transaction_date, 'YYYYMM')='#{date}'"
        conditions << "store_id='#{current_user.branch_id}'" if current_user.branch_id.present?

        sales = SalesDetail.select("to_char(transaction_date, 'DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price")
                    .joins(:sale, product: :m_class).group("to_char(transaction_date, 'DD')").where(conditions.join(' AND ')).order("transaction_date ASC")

        val << {
          name: cat.name,
          y: 0
        }

        sales.map do |s|
          val[-1]['y'] = (s.total_quantity rescue 0)
        end
      end

      render json: {
        #day: (1..time.day).map{|x|x.to_s},
        values: val
      }
    else
      @categories = MClass.where(level: 1)
      @categories.each_with_index do |cat, i|
        conditions = ["quantity>0"]
        conditions << "substr(btrim(path_id, '>' || department_id), length(btrim(path_id, '>' || department_id)), 1)='#{cat.id}'"
        conditions << "to_char(transaction_date, 'YYYYMM')='#{date}'"
        conditions << "store_id='#{current_user.branch_id}'" if current_user.branch_id.present?


        sales = SalesDetail.select("to_char(transaction_date, 'DD') AS transaction_date, SUM(quantity) AS total_quantity,
          SUM(sales_details.total_price) AS total_price")
                    .joins(:sale, product: :m_class).group("to_char(transaction_date, 'DD')")
                    .where(conditions.join(' AND ')).order("transaction_date ASC")

        val << {
          name: cat.name,
          y: 0
        }

        sales.map do |s|
          val[-1]['y'] = (s.total_quantity rescue 0)
        end
      end

      render json: {
        #day: (1..time.day).map{|x|x.to_s},
        values: val
      }
    end
  end

  def line_chart
    result = []
    year = Time.now.year
    branches_conditions = []
    branches_conditions << "id=#{@current_user.branch_id}" if @current_user.branch_id.present?
    times = []
    @branches = Branch.where(branches_conditions.join(' AND ')).order("id ASC")
    first_sales = Sale.where("created_at>'#{(Time.now).strftime('%Y-%m-%d 00:00:00')}'").order("created_at").first.created_at.strftime('%H').to_i rescue 1
    if params[:text] == 'Amount'
      @branches.each{|branch|
        trans_per_hour = []
        first_sales.upto(Time.now.hour).each{|hour|
          0.upto(Time.now.hour > hour ? 11 : Time.now.strftime('%M').to_i/5).each{|minute|
            trans_per_hour << Sale.where("created_at BETWEEN '#{Time.now.strftime('%Y-%m-%d 00:00:00')}' AND '#{Time.now.strftime("%Y-%m-%d #{hour}:#{minute*5}:59")}' AND store_id=#{branch.id}")
              .select("SUM(total_price) AS total_price")[0].total_price rescue 0
            times << "#{sprintf('%02d', hour)}:#{sprintf('%02d', minute*5)}"
          }
        }
        result.push({name: branch.office_name, data: trans_per_hour})
      }
    else
      @branches.each{|branch|
        trans_per_hour = []
        first_sales.upto(Time.now.hour).each{|hour|
          0.upto(Time.now.hour > hour ? 11 : Time.now.strftime('%M').to_i/5).each{|minute|
            trans_per_hour << Sale.where("created_at BETWEEN '#{Time.now.strftime('%Y-%m-%d 00:00:00')}' AND '#{Time.now.strftime("%Y-%m-%d #{hour}:#{minute*5}:59")}' AND store_id=#{branch.id}").select("SUM(total_price) AS total_price")[0].total_price rescue 0
            times << "#{sprintf('%02d', hour)}:#{sprintf('%02d', minute*5)}"
          }
        }
        result.push({name: branch.office_name, data: trans_per_hour})
      }
    end
    render json: {line_chart: result, times: times}
  end

  def index
    if current_user.can_view_dashboard?
      @branches = Branch.all
      conditions = ["to_char(transaction_date, 'YYYY-MM-DD')='#{Time.now.strftime('%Y-%m-%d')}'"]
      conditions << "store_id=#{@current_user.branch_id}" if @current_user.branch_id.present?
      @today_sales = SalesDetail.joins(:sale).where(conditions.join(' AND ')).select("SUM(sales_details.total_price-ppn) AS sum_all")[0].sum_all.to_f
      render file: "#{Rails.root.to_s}/app/views/dashboards/temp.html.erb"
    else
      render file: "#{Rails.root.to_s}/app/views/dashboards/empty.html.erb"
    end
  end

  def update_todolist
    if ToDoList.update(params["id"], :date => params["date"], :end_at => params["end_at"])
      render :json => { status: true }
    else
      render :json => { status: false }
    end
  end
end
