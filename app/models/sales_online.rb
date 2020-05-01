class SalesOnline < ActiveRecord::Base
  belongs_to :branch
  belongs_to :sale
end
