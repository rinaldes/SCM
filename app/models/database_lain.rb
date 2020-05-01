class DatabaseLain < ActiveRecord::Base
  self.abstract_class = true
  self.establish_connection(
    :adapter  => 'postgresql',
    :database => 'ERP',
    :host     => '25.15.147.88',
    :username => 'admin',
    :password => 'insallah'
  )
end
