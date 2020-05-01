json.array!(@locations) do |location|
  json.extract! location, :id, :type, :code, :name
  json.url location_url(location, format: :json)
end
