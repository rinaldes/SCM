class ProductSuppliersController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]

  def update
    ps = ProductSupplier.find(params[:id])
    ps.update_attributes(product_supplier_params)
    redirect_to product_suppliers_url
  end

  def index
    get_paginated_product_suppliers
    respond_to do |format|
      format.html
      format.js
      format.xls { send_data ps_xls, :filename => "product_suppliers"+".xls", :type =>  "application/vnd.ms-excel" }
    end
  end

  def ps_xls
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(:name => 'Product Suppliers')

    conditions = []
    conditions << "products.article LIKE '%#{params[:article]}%'" if params[:article].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(suppliers.name) LIKE LOWER('%#{params[:supplier_name]}%')" if params[:supplier_name].present?
    conditions << "LOWER(contact_person.name) LIKE LOWER('%#{params[:cp_name]}%')" if params[:cp_name].present?

    title = ['Article','Product Name','Supplier','Contact Person']
    sheet.row(0).push *title

    ps = ProductSupplier.where(conditions.join(' AND ')).joins(
      "LEFT JOIN products ON products.id=product_suppliers.product_id LEFT JOIN
      contact_people ON product_suppliers.contact_person_id=contact_people.id
      LEFT JOIN suppliers ON contact_people.supplier_id=suppliers.id").select(
      "product_suppliers.*, suppliers.name AS supplier_name,
      suppliers.code AS supplier_code, contact_people.name AS contact_person_name,
      products.barcode AS product_barcode, products.description AS product_description,
      suppliers.address AS supplier_address")

    ps.each_with_index do |ps, i|
      data = []
      data << (ps.product.article rescue '')
      data << (ps.product.description rescue '')
      data << (ps.supplier.name rescue '')
      data << (ps.contact_person.name rescue '')
      sheet.row(i + 1).push *data
    end
    out = StringIO.new
    book.write out
    out.rewind

    return out.string
  end

  def create
    @product_supplier = ProductSupplier.new(product_supplier_params)

    respond_to do |format|
      if @product_supplier.save
        flash.now[:notice] = 'Product supplier successfully created.'
        format.html{redirect_to product_suppliers_url}
      else
        flash.now[:error] = @product_supplier.errors.full_messages.join('<br/>')
        format.html{render 'new'}
        @cp=ContactPerson.all.order('name')
      end
    end
  end

  def new
    session[:ref] = params[:ref]
    @product_supplier = ProductSupplier.new
    # @contact_person = ContactPerson.all
    @cp=ContactPerson.all.order('name')
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @product_supplier = ProductSupplier.find params[:id]
    @cp=ContactPerson.all.order('name')
  end

  def destroy
    @product_supplier = ProductSupplier.find(params[:id])
    if @product_supplier.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete product supplier"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete product supplier. Data in use"
    end
    get_paginated_product_suppliers
    respond_to do |format|
      format.js
    end
  end

  def contact_people_per_supplier
    @contact_people = ContactPerson.where("supplier_id=#{params[:supplier_id]}").limit(11)
    respond_to do |format|
      format.js
    end
  end

  def autocomplete_contact_person_name
    hash = []
    conditions = ["LOWER(contact_people.name) like LOWER('%#{params[:term]}%')"]
    conditions << "supplier_id='#{params[:supplier_id]}'" if params[:supplier_id].present?
    contact_person = ContactPerson.where(conditions.join(' AND ')).limit(11).order('contact_people.name')
    contact_person.collect do |p|
      hash << {"id" => p.id, "name" => p.name, "label" => p.name}
    end
    render json: hash
  end

  def search_in_modal
    search_product_manual
  end

  def search_product_manual
    conditions = []
    conditions << "LOWER(suppliers.code) LIKE LOWER('%#{params[:supplier_code]}%')" if params[:supplier_code].present?
    conditions << "LOWER(article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    conditions << "LOWER(barcode) LIKE LOWER('%#{params[:barcode]}%')" if params[:barcode].present?
    conditions << "LOWER(description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(brands.name) LIKE LOWER('%#{params[:brand_name]}%')" if params[:brand_name].present?
    conditions << "LOWER(barcode) NOT IN (#{params[:present_product]})" if params[:present_product].present?
    @products = Product.where(conditions.join(' AND '))
      .joins("LEFT JOIN product_suppliers ON products.id=product_suppliers.product_id LEFT JOIN contact_people ON product_suppliers.contact_person_id=contact_people.id LEFT JOIN suppliers ON contact_people.supplier_id=suppliers.id").paginate(page: params[:page], per_page: 10) || []
  end

  private
  def get_paginated_product_suppliers
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @product_suppliers = ProductSupplier.where(conditions.join(' AND '))
      .joins("LEFT JOIN products ON products.id=product_suppliers.product_id LEFT JOIN contact_people ON product_suppliers.contact_person_id=contact_people.id LEFT JOIN suppliers ON contact_people.supplier_id=suppliers.id").
      select("product_suppliers.*, suppliers.name AS supplier_name, suppliers.code AS supplier_code, contact_people.name AS contact_person_name, products.barcode AS product_barcode, products.description AS product_description, suppliers.address AS supplier_address").
      order(params[:sort].to_s.gsub('-', ' ')).
      paginate(page: params[:page], per_page: 25) || []
  end

  def product_supplier_params
    params.require(:product_supplier).permit(:division, :product_id, :supplier_id, :hpp, :contact_person_id)
  end
end
