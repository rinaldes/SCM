class Size < ActiveRecord::Base
  has_many :size_details, dependent: :destroy
  #has_many :goods, class_name: "Goods", dependent: :destroy

  accepts_nested_attributes_for :size_details, reject_if: :all_blank, allow_destroy: true

  validates :description, presence: true, uniqueness: true
#  validates_format_of :description, :with => /^[a-zA-Z\d\s-]*$/i, :multiline => true, :message => "alphabet input only"
  #validates :size_details, presence: true
  validate :check_detail

  scope :search, lambda {|search|{
    joins: "JOIN size_details ON size_details.size_id = sizes.id", order: "code ASC",
    conditions: ['description LIKE ? OR size_number LIKE ? OR code LIKE ?', "%#{search.first}%", "%#{search.first}%", "%#{search.first}%"]
  }}

  before_validation :set_titleize

  def check_transaction
    return false if Product.find_by_size_id(self.id)
    true
  end

  def set_titleize
    self.description = description.titleize rescue nil
  end

  def sorted_size_details
    size_details.sort_by{|size|
      size.size_number.upcase == 'XS' ? 0 : size.size_number.upcase == 'S' ? 1 : size.size_number.upcase == 'M' ? 2 : size.size_number.upcase == 'L' ? 3 : size.size_number.upcase == 'XL' ? 4 : size.size_number.upcase == 'XXL' ? 5 : size.size_number.upcase == 'XXXL' ? 6 : size.size_number.upcase == 'ALL SIZE' ? 777 : size.size_number.to_i
    }
  end

  def check_detail
    errors.add(:size_details, " required minimal 1 ukuran detail") if size_details.blank? 
  end

  def check_relation
    return goods_already_in_used 
  end

  def size_details_is_valid?
    size_com = size_details.compact
    if size_com.length >= 1
      size_asli = self.size_details.map{|k,v| k["size_number"]}
      size_uniq = size_asli.uniq
      size_order = size_asli

      if size_uniq == size_asli
        size_order = size_order.sort_by{|v| v.to_f}
        if size_asli != size_order
          errors.add(:base, "Data Size tidak berurutan")
        end
      else
        errors.add(:base, "Data size duplikat")
      end
    end
  end

  def goods_already_in_used
    return goods.count != 0 ? false:true
  end

  def self.number(params)
    number = (Size.first(:conditions => "description like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    number = (Size.first(:conditions => "description like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_size_id(size)
    id = (Size.first(:conditions => "code = '#{size}' or description = '#{size}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def manage_code
    if  self.new_record?
      if self.class.unscoped.available_data.present?
        (('%03d' % ((self.class.unscoped.available_data.order("id ASC").last.code.to_i rescue 0))))
      else
        (('%03d' % ((self.class.order("code ASC").last.code.to_i rescue 0)+1)))
      end
    else
      self.code
    end
  end

end
