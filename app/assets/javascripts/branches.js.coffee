jQuery ->
  city = $('#branch_city_name').html()
  $('#branch_province_id').change ->
    province = $('#branch_province_id :selected').text()
    options = $(city).filter("optgroup[label='#{province}']").html()
    if options
      $('#branch_city_name').html(options)
    else
      $('#branch_city_name').empty()
