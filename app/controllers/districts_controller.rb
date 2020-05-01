class DistrictsController < ApplicationController
  autocomplete :district, :name
end