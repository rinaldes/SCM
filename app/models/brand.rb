class Brand < ActiveRecord::Base
  JOIN = ''
  ORDER = 'brands.id'
  SELECTED = 'brands.*'
  GROUP_BY = 'brands.id'

  before_validation :upcase_save

  belongs_to :supplier
  belongs_to :m_class
  belongs_to :department, class_name: 'MClass'

  has_many :products

  before_destroy :goods_already_in_used

  has_many :products, dependent: :destroy
  validates :name, presence: true, uniqueness: true

  scope :search, lambda {|search|{conditions:
    ['brands.name LIKE ? OR suppliers.name LIKE ? OR brands.code LIKE ?', "%#{search.first}%", "%#{search.first}%", "%#{search.first}%"],
    joins: "JOIN suppliers ON brands.supplier_id = suppliers.id", :order => "code ASC"
  }}

  before_validation :set_titleize

  def set_titleize
    self.name = name.titleize rescue nil
    self.set_harga = set_harga.titleize rescue nil
  end

  def goods_already_in_used
    return false if Product.find_by_brand_id(id)
  end

  def self.brand_create(params)
    new_brand = Brand.new(params[:brand].merge(supplier_id: (Supplier.first(conditions: ["name = '#{params[:brand][:supplier_id]}'"]).id rescue '')))
    return new_brand
  end

  def upcase_save
    self.name = name.upcase rescue nil
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["code", "name"]
      all.order("brands.code").each do |brand|
          csv << [brand.code, brand.name]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["name"]
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_name(row["name"].upcase).nil?
        brand = find_by_name(row["name"]) || new
        parameters = ActionController::Parameters.new(row.to_hash)
        #supplier = Supplier.where("LOWER(name) = LOWER('#{row.to_hash['supplier_name'].downcase}')").first
        #department = Department.where(name: row.to_hash['department_name'].titleize).first_or_create rescue (return "Brand successfully imported until line #{line}. Unit failed imported  from line #{line+1}. Department can't be blank in row #{line+1}")
        brand = new(parameters.permit(:name).merge(:code => "B#{(('%03d' % ((Brand.last.code.gsub('B', '').to_i rescue 0)+1)))}"))
        unless brand.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{brand.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{brand.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 1, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Must unique"}
      end
    end
    return {error: 0, message: "Brand successfully imported"}
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
