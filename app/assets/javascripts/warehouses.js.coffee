jQuery ->
  city = $('#warehouse_city_name').html()
  $('#warehouse_province_id').change ->
    province = $('#warehouse_province_id :selected').text()
    options = $(city).filter("optgroup[label='#{province}']").html()
    if options
      $('#warehouse_city_name').html(options)
    else
      $('#warehouse_city_name').empty()
