class ContactPerson < ActiveRecord::Base
  belongs_to :supplier

  #after_create :generate_user
  #validates_format_of :email, :with => /^[a-zA-Z\d\s@._]*$/i,:multiline => true, :message => "nama email tidak boleh special character"
  #validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :multiline => true, :message => "email format must be correctly"
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :multiline => true, :message => "format must be correctly"
  validates :division_name, :name, :presence => {:message => 'required'}
  #validates :phone, :presence => {:message => 'required'}
  validates :email, :presence => {:message => 'required'}
  # validates_format_of :pinbb, :name, :division_name, :with => /^[a-zA-Z\s]*$/i,:multiline => true, :message => "alphanumeric input only"
  has_many :product_suppliers
  has_many :products, through: :product_suppliers
  accepts_nested_attributes_for :supplier, :allow_destroy => true

  def generate_user
    user = User.new first_name: name, last_name: name, gender: "male", birth_place: "hometown", birth_date: Time.now, email: email, status: "active", confirmed_at: Time.now, username: email, password: email, role_id: Role::SUPPLIER
    user.save
    self.update_attributes user_id: user.id
  end
end
