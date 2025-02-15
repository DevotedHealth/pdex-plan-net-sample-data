require_relative 'utils/formatting'
require_relative 'utils/position'

module PDEX
  class NPPESNetwork
    include Formatting
    include Position

    attr_reader :raw_data

    def initialize(raw_data)
      @raw_data = raw_data.freeze
    end

    def npi
      raw_data['hpid']
    end

    def type
      {
        code: raw_data['prov_type_code'],
        display: raw_data['prov_type_display'],
        text: raw_data['prov_type_text']
      }
    end

    def name
      raw_data['name']
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
          lines: [raw_data['address']],
          city: raw_data['city'],
          state: raw_data['state'],
          zip: format_zip(raw_data['zip'])
        }
      )
    end

    def contact_first_name
      @contact_first_name ||= ''
    end

    def contact_last_name
      @contact_last_name ||= ''
    end

    def part_of_id
      # TODO NPI
      raw_data['partof_id']
    end

    def part_of_name
      raw_data['partof_display'].split(' of').first
    end
  end
end
