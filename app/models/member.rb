class Member < ActiveRecord::Base
  JOIN = ''
  ORDER = 'members.id'
  SELECTED = 'members.*'
  GROUP_BY = 'members.id'
  attr_accessor :discount_percent

  belongs_to :member_level

  before_validation :upcase_save

  has_many :sales
  has_many :discounts, foreign_key: :item_id
  has_many :setting_point_members, :through => :point_members #join table
  has_many :point_members
  has_many :account_receivables

  validates :name, presence:  {:message => 'required'}
  validates :card_number, :presence =>  {:message => 'required'}, uniqueness: true
  validates :birthday, :presence =>  {:message => 'required'}
  validates :address, :presence =>  {:message => 'required'}
  validates :hp, :presence =>  {:message => 'required'}
  validates :gender, :presence =>  {:message => 'required'}
  validates :email, :presence =>  {:message => 'required'}
  validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  validates_format_of :card_number, :with => /^[a-zA-Z0-9\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  validates_format_of :address, :with => /^[a-zA-Z0-9\d\s.,]*$/i, :multiline => true, :message => "enter the data correctly"
  #validates_format_of :hp, :with => /^[0-9\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :multiline => true, :message => "semail format must be correctly"
  #validates_format_of :email, :with => /^[a-zA-Z\d\s@.]*$/i, :multiline => true, :message => "tidak mengijinkan special character selain _ @ ."


  after_create :send_email

  scope :search, lambda {|search|{
    :conditions => ['name LIKE ?', "%#{search.first}%"], :order => "card_number ASC"
  }}

  def send_email
    
  end

  def self.apa(params)
    ActiveSupport::JSON.decode(params).each do |m|
      if Member.find_by_card_number(m["card_number"]).present?
        member = Member.find_by_card_number(m["card_number"])
      else
        member = self.new()
        member.card_number = m["card_number"]
      end
      member.address = m["address"]
      member.balance = m["balance"]
      member.birthday = m["birthday"]
      member.city = m["city"]
      member.credit_limit = m["credit_limit"]
      member.email = m["email"]
      member.gender = m["gender"]
      member.member_level_id = m["member_level_id"]
      member.name = m["name"]
      member.hp = m["hp"]
      member.point = m["point"]
      member.zip = m["zip"]
      member.code = ('%03d' % ((Member.last.code.to_i rescue 0)+1))

      member.save!
    end
  end

  def upcase_save
    self.name = name.titleize rescue nil
    self.address = address.titleize rescue nil
  end

  def reactivate
    self.update_attributes expired_date: DateTime.now.next_year.strftime("%d-%m-%Y")
  end

  def expired?
    self.expired_date.strftime("%d-%m-%Y") < DateTime.now.strftime("%d-%m-%Y") rescue true
  end

  def self.all_to_api_request(params)

    params[:page] = 1 if params[:page].blank?
    params[:per_page] = 10 if params[:per_page].blank?

    if params[:last_update].present?
      members = Member.where("members.updated_at >='#{params[:last_update]}'").paginate(:page => params[:page], :per_page => params[:per_page])
    else
      members = Member.paginate(:page => params[:page], :per_page => params[:per_page])
    end

    members.map{|member|
      discount = member.discounts.order(:id).last
      {
        id: member.id, card_number: member.card_number, name: member.name, address: member.address, birthday: member.birthday, phone_number: member.phone_number,
        gender: member.gender, hp: member.hp, discount_id: (discount.id rescue nil), discount_percent: (discount.percent rescue 10), minimal: (discount.nominal rescue nil)
      }
    }
  end

  def self.check_default_discount
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["code", "card_number", "name", "address", "birthday", "gender", "hp","email"]
      all.each do |member|
        if member.gender == 'Female'
          gender  = 'F'
        else
          gender = 'M'
        end
        birthday = member.birthday.strftime('%d-%m-%Y')
        csv << [member.code, member.card_number, member.name, member.address, birthday, gender, member.hp, member.email]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["card_number", "name", "address", "birthday", "gender", "hp", "email", 'level', 'balance', 'credit_limit']
      all.each do |member|
      end
    end
  end

  def self.import(file)
    CSV.foreach(file.path, headers: true) do |row|
   
      if find_by_name(row["name"].upcase).nil?
        member = find_by_name(row["name"]) || new
        parameters = ActionController::Parameters.new(row.to_hash)
        birthday = Date.parse(parameters[:birthday])
        member.update(
          parameters.permit(:card_number, :name, :address, :birthday, :gender, :hp, :email, :credit_limit, :balance)
            .merge(:code => (('%03d' % ((Member.last.code.to_i rescue 0)+1))), birthday: birthday.strftime('%Y-%m-%d'), gender: parameters[:gender] == 'F' ? 'Female' : 'Male', member_level_id: (MemberLevel.find_by_level(parameters[:level]).id rescue nil))
        )
        unless member.save
          return "Kesalahan pengisian data member: #{member.errors.full_messages.join('<br/>')}"
        end
      else
        return "File tidak dapat diimport,periksa kembali format atau isi file"
      end
    end
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.api(params)
    ActiveSupport::JSON.decode(params).each do |d|
      member = self.new()
      member.card_number = d["card_number"]
      member.name = d["name"]
      member.address = d["address"]
      member.birthday = d["birthday"]
      member.phone_number = d["phone_number"]
      member.gender = d["gender"]
      member.hp = d["hp"]
      member.code = d["code"]
      member.city = d["city"]
      member.zip = d["zip"]
      member.coment1 = d["coment1"]
      member.coment2 = d["coment2"]
      member.datemember = d["datemember"]
      member.reference_id = d["reference_id"]
      member.is_valid = d["is_valid"]
      member.discount = d["discount"]
      member.active = d["active"]
      member.email = d["email"]
      member.save!
    end
  end

  private
  protected
  def save_discount
    self.discounts.create(percent: discount_percent, start_date: DateTime.now.strftime("%d-%m-%Y"), discount_type: Discount::Normal) unless (self.discounts.order(:id).last.percent rescue 0) == (discount_percent.present? ? discount_percent : 10 )
  end
end
