class Ad < ActiveRecord::Base

  validates :url, :presence => {message: 'required'} , :uniqueness => true
  validates :ad_type, :presence => {message: 'required'}
  validates :valid_from, :presence => {message: 'required'}
  validates :valid_until, :presence => {message: 'required'}

  def self.number(params)
    number = (Ad.first(:conditions => "url like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:ad][:url][0]
    number = (Ad.first(:conditions => "url like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["url", "ad_type", "valid_from", "valid_until", "store"]
      all.each do |ad|
        csv << [ad.url, ad.ad_type, ad.valid_from, ad.valid_until, ad.store]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["url", "ad_type", "valid_from", "valid_until", "store"]
      all.each do |ad|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_url(row["url"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        ad = new(parameters.permit(:url, :ad_type, :valid_from, :valid_until, :store))
        unless ad.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{ad.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{ad.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported"}
      end
    end
    return {error: 0, message: "Successfully imported"}
  end

  def self.open_spreadsheet(file)
    case File.exturl(file.original_fileurl)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_fileurl}"
    end
  end

end