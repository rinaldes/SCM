class MClassesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :m_class, :name
  before_filter :can_view_mclass, only: [:index, :show]
  before_filter :can_manage_mclass, only: [:new, :create, :edit, :update]

  def import
    import_result = MClass.import(params[:file])
    if import_result[:error] == 1
      flash[:error] = import_result[:message]
    else
      flash[:notice] = import_result[:message]
    end
    redirect_to m_classes_path
  end

  def create
    @m_class = MClass.new m_class_params.merge(level: 1, code: (("M1#{sprintf '%03d', ((MClass.where("parent_id IS NOT NULL AND level=1").order("id DESC").limit(1).last.code.gsub('M1', '').to_i rescue 0)+1)}")))
    if @m_class.save
      @m_class.set_path
      create_sub_mclass params[:m_class][:m_class_attributes], @m_class if params[:m_class][:m_class_attributes].present?
      flash[:notice] = "Successfully created"
      redirect_to m_classes_url
    else
      load_departments
      flash[:error] = @m_class.errors.full_messages.join('<br/>')
      render :new
    end
  end

  def update
    @m_class = MClass.find(params[:id])
    @quit = nil
    @errors = []
    respond_to do |format|
      hash_to_be_updated = {parent_id: params[:m_class][:parent_id]}
      hash_to_be_updated = hash_to_be_updated.merge(name: params[:m_class][:name]) unless params[:m_class][:name] == @m_class.name
      if @m_class.update_attributes(hash_to_be_updated) && @m_class.set_path && @quit.nil?
        MClass.where("code IN ('#{params[:tobe_deleted].split(', ').reverse.join("', '").chop.chop.chop.chop}')").delete_all
        update_sub_mclass params[:m_class][:m_class_attributes], @m_class if params[:m_class][:m_class_attributes].present?
        if @quit.nil?
          format.js
        else
          load_departments
          @errors.push(@m_class.errors.full_messages.join('<br/>')) if @m_class.errors.full_messages.join('<br/>').present?
          flash[:error] = @errors.join('<br/>')
          format.js
        end
      else
        load_departments
        flash[:error] = @m_class.errors.full_messages.join('<br/>')
        format.js
      end
    end
  end

  def show
    @m_class = MClass.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update_sub_mclass sub_m_classes, parent
    sub_m_classes.values.each_with_index{|m_class_params, i|
      m_class = MClass.find_by_code m_class_params[:code]
      if m_class
        unless m_class.update_attributes name: m_class_params[:name]
          @errors << m_class.errors.full_messages.join('<br/>')
          @quit = true
        end
      else
        m_class = MClass.new name: m_class_params[:name], level: parent.level+1, parent_id: parent.id, code: "#{parent.code}.#{(parent.m_classes.last.code.split('.').last.to_i rescue 0)+1}"
        unless m_class.save
          @errors << m_class.errors.full_messages.join('<br/>')
          @quit = true
        end
      end
      break if @quit
      m_class.set_path
      update_sub_mclass m_class_params[:m_class_attributes], m_class if m_class_params[:m_class_attributes].present?
    }
  end

  def create_sub_mclass sub_m_classes, parent
    sub_m_classes.values.each_with_index{|m_class_params, i|
      lv = parent.level+1
      m_class = MClass.new name: m_class_params[:name], level: lv, parent_id: parent.id, code: "#{parent.code}.#{i+1}"
      create_sub_mclass m_class_params[:m_class_attributes], m_class if m_class.save && m_class.set_path && m_class_params[:m_class_attributes].present?
    }
  end

  def destroy
    @m_class = MClass.find(params[:id])
    check = Product.find_by_m_class_id(params[:id])
    if check.present?
      flash[:notice] = nil
      flash[:error] = "Can't delete category. data in use by product"
    else
      if @m_class.check_transaction && @m_class.destroy
        flash[:error] = nil
        flash[:notice] = "Successfully delete category"
      else
        flash[:notice] = nil
        flash[:error] = "Can't delete category. data in use by something."
      end
    end
    get_paginated_m_class
    respond_to do |format|
      format.js
    end
  end

  def new
    @m_class = MClass.new
    load_departments
  end

  def add_sub_m_class
    @m_class = MClass.find_by_id params[:m_class_id]
    @blank_state = true
    respond_to do |format|
      format.js
    end
  end

  def index
    get_paginated_m_class
    respond_to do |format|
      format.html
      format.js
      format.xls{ headers["Content-Disposition"] = "attachment; filename=\"#{'Category.xls'}\""}
      if(params[:a] == "a")
        format.csv{send_data MClass.all.to_csv2, :filename => 'Category.csv'}
      else
        format.csv{send_data MClass.all.to_csv, :filename => 'Category.csv'}
      end
    end
  end

  def autocomplete_m_class_name
=begin
    hash = []
    supplier = MClass.where("parents.name='#{params[:parent_id]}' AND LOWER(m_classes.name) like '%#{params[:term]}%'").limit(11).order('m_classes.name')
      .joins("INNER JOIN m_classes parents ON m_classes.parent_id=parents.id")
    supplier.collect do |p|
      hash << {"id" => p.id, "label" => p.name, "value" => p.name}
    end
    render json: hash
=end
    hash = []
    supplier = MClass.where("LOWER(name) like '%#{params[:term]}%' AND parent_id=#{(Department.find_by_name(params[:mclass_name]).id)}").limit(11).order('name')
    supplier.collect do |p|
      hash << {"id" => p.id, "label" => p.name, "value" => p.name}
    end
    render json: hash
  end

  def edit
    @m_class = MClass.find params[:id]
    load_departments
  end

private
  def get_paginated_m_class
    conditions = ["level=1 AND parent_id IS NOT NULL"]
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @m_classes = MClass.where(conditions.join(' AND ')).order('m_classes.code DESC').paginate(:page => params[:page], :per_page => 10).select("m_classes.*, m_classes.name as name1, m_classes.name as name2, m_classes.code as code1, m_classes.code as code2, path_code, m_classes.created_at") || []
  end

  def m_class_params
    params.require(:m_class).permit(:code, :name, :parent_id, :jenis)
  end

  def can_view_mclass
    not_authorized unless current_user.can_view_mclass?
  end

  def can_manage_mclass
    not_authorized unless current_user.can_manage_mclass?
  end
end
