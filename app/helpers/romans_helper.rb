module RomansHelper

	def to_roman(number = self, result = "")
	  return result if number == 0
	  roman_mapping.keys.each do |divisor|
	    quotient, modulus = number.divmod(divisor)
	    result << roman_mapping[divisor] * quotient
	    return to_roman(modulus, result) if quotient > 0
	  end
	end
end
