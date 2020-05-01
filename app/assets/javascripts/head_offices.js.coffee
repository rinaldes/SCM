jQuery ->
  city = $('#head_office_city_name').html()
  $('#head_office_province').change ->
    province = $('#head_office_province :selected').text()
    options = $(city).filter("optgroup[label='#{province}']").html()
    if options
      $('#head_office_city_name').html(options)
    else
      $('#head_office_city_name').empty()
