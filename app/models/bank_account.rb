class BankAccount < ActiveRecord::Base
  #validates :name, :presence => {:message => 'required'}
  #validates :account_number, :presence => {:message => 'required'}
  #validates :bank_name, :presence => {:message => 'required'}
  #validates :branch, :presence => {:message => 'required'}
  #validates :city, :presence => {:message => 'required'}
  # accepts_nested_attributes_for :supplier, :allow_destroy => true
 # validates_format_of :name, :with => /^[a-zA-Z\s]*$/i,:multiline => true, :message => "alphabet input only"
  validates :account_number, numericality: {only_integer: true}
 # validates_format_of :bank_name, :with => /^[a-zA-Z\d\s]*$/i,:multiline => true, :message => "alphabet input only"
  validates_format_of :branch, :with => /^[a-zA-Z\d\s]*$/i,:multiline => true, :message => "alphabet input only"
  validates_format_of :city, :with => /^[a-zA-Z\s]*$/i,:multiline => true, :message => "alphabet input only"
end
