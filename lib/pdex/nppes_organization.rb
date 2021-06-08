require_relative 'utils/formatting'
require_relative 'utils/lat_long'
require_relative 'utils/position'

module PDEX
  class NPPESOrganization
    include Formatting
    include Position

    attr_reader :raw_data

    def initialize(raw_data)
      @raw_data = raw_data.freeze
    end

    def npi
      @npi ||= raw_data['NPI']
    end

    def name
      raw_data['Provider Organization Name (Legal Business Name)']
    end

    def phone_numbers
      @phone_numbers ||= []
    end

    def fax_numbers
      @fax_numbers ||= []
    end

    def address
      OpenStruct.new(
        {
          lines: [
            raw_data['Provider First Line Business Mailing Address'],
            raw_data['Provider Second Line Business Mailing Address']
          ].reject(&:blank?),
          city: raw_data['Provider Business Mailing Address City Name'],
          state: raw_data['Provider Business Mailing Address State Name'],
          zip: format_zip(raw_data['Provider Business Mailing Address Postal Code'])
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
