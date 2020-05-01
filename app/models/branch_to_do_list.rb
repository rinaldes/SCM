class BranchToDoList < ActiveRecord::Base
  belongs_to :office
  belongs_to :to_do_list
end
