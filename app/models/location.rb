class Location < ActiveRecord::Base
  belongs_to :location, foreign_key: :parent_id
  has_many :locations, foreign_key: :parent_id, dependent: :destroy
  has_many :stock_transfers

  before_save :set_tree
  def check_name_and_parent_id
    errors.add(:name, "already in use") if Location.find_by_name_and_parent_id(name, parent_id) || Location.find_by_name_and_level(name, level)
  end

  def set_titleize
    self.name = name.titleize rescue nil
  end

  def set_tree
    set_province_location self
  end

  def set_province_location location
    d_location = []
    current_location = location
    while current_location.present? do
      d_location << current_location.name
      current_location = current_location.location
    end
    self.province_location = d_location.join(' > ')
  end

  def set_path
    set_path_id self
    set_path_code self
  end

  def set_path_id location
    d_location = []
    current_location = location
    while current_location.present? do
      d_location << current_location.id
      current_location = current_location.location
    end
    self.path_id = d_location.join('>')
    self.save validate: false
  end

  def set_code
    set_path_code self
  end

  def set_path_code location
    d_location = []
    current_location = location
    while current_location.present? do
      d_location << current_location.code
      current_location = current_location.location
    end
    self.path_code = d_location.last
    self.save validate: false
  end

  def province
    parent_id.present? ? location.province : self
  end

  # def departement
  #   if parent_id.present?
  #     return self.department
  #   else
  #     self.m_class.departement
  #   end
  # end

  def children_size
    size = locations.size
    locations.each{|location|
      locations = location.locations
      if locations.present?
        size += location.children_size
      end
    }
    return size
  end
  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["Provinsi","Kabupaten/Kota", "Kecamatan", "kelurahan/Desa"]
      pro_awal = ''
      all.where("parent_id is null").order("locations.province_id ASC").each do |provinsi|
        next unless Location.find_by_parent_id(provinsi.id)
        pro = Province.find(provinsi.province_id).name rescue ''
        if pro_awal == pro
          pro = ''
        else
          pro_awal = pro
        end
        par1 = provinsi.name
        find1 = false
        all.where(parent_id: provinsi.id).order('created_at ASC').each do |kota|
          par2 = kota.name
          find2 = false
          all.where(parent_id: kota.id).order('created_at ASC').each do |kec|
            par3 = kec.name
            find3 = false
            all.where(parent_id: kec.id).order('created_at ASC').each do |kel|
              # par4 = kel.name
              # find4 = false
              # all.where(parent_id: kel.id).order('created_at ASC').each do |m_class4|
                csv << [pro, par1, par2, par3, kel.name]
                pro, par1, par2, par3  = "", "", ""
                find3 = true
              # end
              # if find4 == false
              #   csv << [par1, par2, par3, par4, ""]
              # end
              # par1, par2, par3 = "", "", ""
              # find3 = true
            end
            if find3 == false
              csv << [pro, par1, par2, par3, ""]
            end
            pro, par1, par2 = "",""
            find2 = true
          end
          if find2 == false
            csv << [pro, par1, par2, "", ""]
          end
          pro, par1 = ""
          find1 = true
        end
        if find1 == false
          csv << [pro, par1, "", "", ""]
        end
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["Provinsi", "Kabupaten/Kota", "Kecamatan", "kelurahan/Desa"]
      all.each do |location|
      end
    end
  end

  def self.import(file)
    # line = 0
    # CSV.foreach(file.path, headers: true) do |row|
    #   if find_by_id(row["id"]).nil?
    #     parameters = ActionController::Parameters.new(row.to_hash)
    #     location = new(parameters.permit(:id, :name, :code,:jenis))
    #     unless location.save
    #       return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{location.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{location.errors.full_messages.join('<br/>')}"}
    #     end
    #     line += 1
    #   else
    #     return {error: 0, message: "Successfully imported"}
    #   end
    # end
    # return {error: 0, message: "Successfully imported"}
    parent = 0
    parent2 = 0
    parent3 = 0
    parent4 = 0
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      unless row[0].nil?
        if Province.find_by_name(row[0]).present?
          parent = Province.find_by_name(row[0]).id
        else
          Province.create!(name: row[0])
          parent = Province.find_by_name(row[0]).id
        end
      end
      unless row[1].nil?
        if Location.find_by_name(row.to_hash["Kabupaten/Kota"]).present?
          parent2 = Location.find_by_name(row.to_hash["Kabupaten/Kota"]).id
        else
          $M_SAVE = Location.new(jenis: "kota/kabupaten",:name => row[1], level: 1, province_id: parent, code: (("K#{sprintf '%03d', ((Location.where("parent_id IS NOT NULL AND level=1").order("id DESC").limit(1).last.code.gsub('K', '').to_i rescue 0)+1)}")))
          if $M_SAVE.save
            parent2 = $M_SAVE.id
            $M_SAVE.set_path
          else
            return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{$M_SAVE.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{$M_SAVE.errors.full_messages.join('<br/>')}"}
          end
        end
      end
      unless row[2].nil?
        if Location.find_by_name(row.to_hash["Kecamatan"]).present?
          parent3 = Location.find_by_name(row.to_hash["Kecamatan"]).id
        else
          $M2_SAVE = Location.new(jenis: "kecamatan",name: row[2], level: 2, parent_id: parent2, code: "#{$M_SAVE.code}.#{(Location.where(parent_id: $M_SAVE.id).order("id DESC").limit(1).last.code.last.to_i rescue 0)+1}")
          if $M2_SAVE.save
            parent3 = $M2_SAVE.id
            $M2_SAVE.set_path
          else
            return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{$M2_SAVE.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{$M2_SAVE.errors.full_messages.join('<br/>')}"}
          end
        end
      end
      unless row[3].nil?
        if Location.find_by_name(row.to_hash["kelurahan/Desa"]).present?
          parent4 = Location.find_by_name(row.to_hash["kelurahan/Desa"]).id
        else
          $M3_save = Location.new(
            jenis: "kelurahan/desa",
            name: row[3], level: 3,
            parent_id: parent3,
            code: "#{$M2_SAVE.code}.#{(Location.where(parent_id: $M2_SAVE.id).order("id DESC").limit(1).last.code.last.to_i rescue 0)+1}"
          )
          if $M3_save.save
            parent4 = $M3_save.id
            $M3_save.set_path
          else
            return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{$M3_save.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{$M3_save.errors.full_messages.join('<br/>')}"}
          end
        end
      end
      unless row[4].nil?
        unless Location.find_by_name(row.to_hash["M-Class 4"]).present?
          m4_save = Location.new(name: row[4], level: 4, parent_id: parent4, code: "#{$M3_save.code}.#{(Location.where(parent_id: $M3_SAVE.id).order("id DESC").limit(1).last.code.last.to_i rescue 0)+1}")
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{m4_save.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{m4_save.errors.full_messages.join('<br/>')}"} unless m4_save.save
          m4_save.set_path
        end
      end
    #else
    #  return "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Must unique"
    #end
      line += 1
    end
    return {error: 0, message: ""}
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
