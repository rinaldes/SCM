class Branch < Office
  has_many :good_transfers
  has_many :product_details, class_name: 'ProductDetail', primary_key: 'id', foreign_key: 'warehouse_id'
  belongs_to :head_office
  scope :active_store, -> {where(is_active: true)}

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["Code","Name","Regional","Branch","Area","NPWP","No Telp","Email","Description","Province","City","Districts","Zip Code","Address","RT","RW","Village"]
      all.each do |branch|
      	regional = branch.regional.name rescue ""
      	head_office = branch.head_office.office_name rescue ""
      	area = branch.area.name rescue ""
      	province = branch.province.name rescue ""
      	city = branch.city.name rescue ""
      	district = branch.district.name rescue ""
        csv << [branch.code, branch.office_name, regional, head_office, area, branch.npwp, branch.phone_number, branch.email, branch.description, province, city, district, branch.zip_code, branch.address, branch.rt, branch.rw, branch.village]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["Name","Regional","Branch","Area","NPWP","No Telp","Email","Description","Province","City","Districts","Zip Code","Address","RT","RW","Village"]
      all.each do |branch|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_office_name(row["Name"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        branch = new(code: row["Code"], office_name: row["Name"], regional_id: (Region.find_by_name(row["Regional"]).id rescue 0), head_office_id: (HeadOffice.find_by_office_name(row["Branch"]).id rescue 0),
          area_id: (Area.find_by_name(row["Area"]).id rescue 0), npwp: row["NPWP"], phone_number: row["No Telp"], email: row["Email"], description: row["Description"],
          province_id: (Province.find_by_name(row["Province"]).id rescue 0), city_id: (City.find_by_name(row["City"]).id rescue 0), district_id: (District.find_by_name(row["Districts"]).id rescue 0),
          zip_code: row["Zip Code"], address: row["Address"], rt: row["RT"], rw: row["RW"], village: row["Village"])
        unless branch.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #[branch.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #[branch.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported"}
      end
    end
    return {error: 0, message: "Successfully imported"}
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def check_transaction
    return false if ProductDetail.where("available_qty>0").find_by_warehouse_id(self.id)
    true
  end
end
