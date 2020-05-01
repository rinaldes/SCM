jQuery ->
  loaded_city = $('#area_city_id :selected').text()
  cities = $('#area_city_id').html()
  $('#area_city_id').parent().hide()
  if loaded_city.length != 0
   regional = $('#area_regional_id :selected').text()
   escaped_regional = regional.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g, '\\$1')
   options = $(cities).filter("optgroup[label=#{escaped_regional}]").html()
   $('#area_city_id').html(options)
   $('#area_city_id').parent().show()
  console.log(cities)
  $('#area_regional_id').change ->
    regional = $('#area_regional_id :selected').text()
    escaped_regional = regional.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g, '\\$1')
    options = $(cities).filter("optgroup[label=#{escaped_regional}]").html()
    console.log(options)
    if options
      $('#area_city_id').html(options)
      $('#area_city_id').parent().show()
    else
      $('#area_city_id').empty()
      