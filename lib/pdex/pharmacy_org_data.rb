require_relative 'utils/formatting'
require_relative 'utils/lat_long'
require_relative 'utils/position'

module PDEX
  class PharmacyOrgData
    include Formatting
    include Position
    include ShortName

    attr_reader :name

    def initialize(name)
      @name = name 
    end

    def npi
      digest_short_name(@name)
    end

    def phone_numbers
      @phone_numbers ||= []
    end

    def fax_numbers
      @fax_numbers ||= []
    end

    def address]
      OpenStruct.new(
        {
          lines: [
          ],
          city: '',
          state: '',
          zip: format_zip('')
        }
      )
    end

    def contact_first_name
      @contact_first_name ||= ''
    end

    def contact_last_name
      @contact_last_name ||= ''
    end
  end
end
