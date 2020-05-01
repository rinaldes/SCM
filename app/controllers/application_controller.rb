class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  protect_from_forgery with: :null_session
  before_action :authenticate_user!
  before_filter :set_current_user

  # def authenticate_user!
  #   return User.first
  # end

  # def user_is_store_owner
  #   roles = [1,2,3]
  #   verify = roles.include? current_user.role.id
  #   if !verify

  #   end
  # end

  def not_authorized
    flash[:error] = 'You dont have authorize on this'
    return redirect_to root_url
  end

  def load_product
    @products = MClass.where("parent_id IS NULL").select("barcode, id").order("barcode")
  end

  def load_departments
    @departments = MClass.where("parent_id IS NULL").select("name, id").order("name")
  end

  def load_provinces
    @provinces = Province.where("parent_id IS NULL").select("name, id").order("name")
  end

  def get_paginated_sizes
    conditions = []
    conditions << "sizes.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @sizes = Size.joins("INNER JOIN size_details ON sizes.id=size_details.size_id").where(conditions.join(' AND ')).order(default_order('sizes')).uniq
      .paginate(page: params[:page], :per_page => 10) || []
  end

  def get_paginated_branches
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @branches = Branch.joins("LEFT JOIN users ON offices.contact_person=users.id LEFT JOIN offices head_offices ON head_offices.id=offices.head_office_Id").joins(:area)
      .select("offices.*, users.username, head_offices.office_name AS head_office_name").where(conditions.join(' AND ')).order(default_order('offices')).paginate(page: params[:page], per_page: 10) || []
  end

  def get_paginated_warehouses
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @warehouses = Warehouse.joins("LEFT JOIN users ON offices.contact_person=users.id LEFT JOIN offices head_offices ON head_offices.id=offices.head_office_Id")
      .select("offices.*, users.username, head_offices.office_name AS head_office_name").where(conditions.join(' AND ')).order(default_order('offices')).paginate(page: params[:page], per_page: 10) || []
  end

  def get_paginated_size_details
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @size_details = SizeDetail.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).uniq
      .paginate(page: params[:page], :per_page => 10) || []
  end

  def get_paginated_members
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @members = Member.where(conditions.join(' AND ')).select("*, to_char(birthday, 'DD-MM-YYYY')").order(default_order('members'))
      .paginate(page: params[:page], per_page: 10)
  end

  def get_paginated_member_levels
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @member_levels = MemberLevel.where(conditions.join(' AND ')).select("*").order(default_order('member_levels'))
      .paginate(page: params[:page], per_page: 10)
  end

  def get_paginated_products
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @products = Product.joins(:m_class, :colour, :size, brand: :supplier).where(conditions.join(' AND '))
    .select("brands.name AS brand_name, suppliers.name AS supplier_name, colours.name AS colour_name, m_classes.name AS m_class_name, products.*, sizes.description AS size_name,
      to_char(selling_price, '99999999D99') AS selling_price, to_char(purchase_price, '99999999D99') AS purchase_price")
      .order((params[:sort] || 'updated_at').to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
  end

    # def get_paginated_products
    #   conditions = []
    #   params[:search].each{|param|
    #     conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    #   } if params[:search].present?
    #   @products = Product.joins(:m_class).where(conditions.join(' AND ')).select("m_classes.name AS m_class_name, products.*,
    #     to_char(selling_price, '99999999D99') AS selling_price, to_char(purchase_price, '99999999D99') AS purchase_price")
    #     .order((params[:sort] || 'updated_at').to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
    # end

  def get_paginated_pos_machines
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @pos_machines = PosMachine.joins(:head_office).where(conditions.join(' AND ')).select("pos_machines.*, offices.office_name AS office_name").order(default_order('pos_machines')).paginate(:page => params[:page], :per_page => 10) || []
 end

  def get_paginated_ads
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @ads = Ad.where(conditions.join(' AND ')).order(default_order('ads')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def get_paginated_planos
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    conditions << "offices.id = #{current_user.office_id}" if current_user.office_id.present?
    unless params[:store].to_i == 0
      conditions << "offices.id = #{params[:store].to_i}"
    end
    unless request.format.xls? || request.format.csv?
      @planos = Plano.joins(:product, :planogram, :product_detail).joins("INNER JOIN offices ON offices.id = product_details.warehouse_id").select("planos.*, products.description as product_name, products.article as product_article, planograms.rack_number as rak_name, products.status3 as status3, concat(planos.start, ' - ', planos.end) as period")
      .where(conditions.join(' AND ')).order(default_order('planos')).paginate(:page => params[:page], :per_page => 10) || []
    else
      @planos = Plano.joins(:product, :planogram, :product_detail).joins("INNER JOIN offices ON offices.id = product_details.warehouse_id").select("planos.*, products.description as product_name, products.article as product_article, planograms.rack_number as rak_name, products.status3 as status3, concat(planos.start, ' - ', planos.end) as period")
      .where(conditions.join(' AND ')).order(default_order('planos')) || []
    end
  end

  def get_paginated_colours
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @colours = Colour.where(conditions.join(' AND ')).order(default_order('colours')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def get_paginated_to_do_lists
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @to_do_lists = ToDoList.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def load_supplier
    @suppliers = Supplier.select("name, id, address, code").limit(7).order("name")
  end

  def get_paginated_brands
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @brands = Brand.where(conditions.join(' AND ')).select("brands.id, brands.code, brands.name, brands.set_harga")
      .order(default_order('brands')).paginate(page: params[:page], per_page: 10) || []
  end

  def get_paginated_head_offices
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'" if param[1].present?
    } if params[:search].present?
    @head_offices = HeadOffice.joins("LEFT JOIN users ON offices.contact_person=users.id").select("offices.*, users.username").where(conditions.join(' AND '))
      .order(default_order('offices')).paginate(page: params[:page], per_page: 10) || []
  end

  def get_paginated_product_stocks
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @product_stocks = ProductStock.where(conditions.join(' AND ')).order(default_order('product_stocks')).paginate(:page => params[:page], :per_page => 10) || []
   end
   def get_paginated_locations
     conditions = []
     conditions << "level = '1'"
      conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
     params[:search].each{|param|
       conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
     } if params[:search].present?
     @locations = Location.where(conditions.join(' AND ')).order(default_order('locations')).paginate(:page => params[:page], :per_page => 10) || []
    end

  def default_order module_name=nil
    (params[:sort] || "#{module_name}#{'.' if module_name.present?}created_at DESC").to_s.gsub('-', ' ')
  end

  def romanian_month
    date = Date.today
    case date.month
      when 1
        result = "I"
      when 2
        result = "II"
      when 3
        result = "III"
      when 4
        result = "IV"
      when 5
        result = "V"
      when 6
        result = "VI"
      when 7
        result = "VII"
      when 8
        result = "VIII"
      when 9
        result = "IX"
      when 10
        result = "X"
      when 11
        result = "XI"
      when 12
        result = "XII"
      else
        result = "undefined"
    end
    return "#{result}/#{date.strftime("%y")}"
  end

  def set_current_user
    User.current = current_user
    @current_user = current_user
    @entity = Entity.where(domain_name: request.env['HTTP_HOST']).first_or_create
  end

end
