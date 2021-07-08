require_relative 'utils/formatting'
require_relative 'utils/lat_long'
require_relative 'utils/position'

module PDEX
  class PharmacyOrgData
    include Formatting
    include Position
    include ShortName

    attr_reader :pharmacy, :name

    def initialize(pharmacy, name)
      @pharmacy = pharmacy
      @name = name 
    end

    def npi
      digest_short_name(@name)
    end

    def phone_numbers
      return @pharmacy.phone_numbers if !@pharmacy.nil?
      @phone_numbers
    end

    def fax_numbers
      @fax_numbers ||= []
    end

    def address
      return @pharmacy.address if !@pharmacy.nil?
    end

    def contact_first_name
      @contact_first_name ||= ''
    end

    def contact_last_name
      @contact_last_name ||= ''
    end
  end
end
