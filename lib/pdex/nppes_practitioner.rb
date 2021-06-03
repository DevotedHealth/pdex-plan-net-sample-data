require_relative 'utils/formatting'
require_relative 'utils/position'

module PDEX
  class NPPESPractitioner
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
      OpenStruct.new(
        {
          first: first_name,
          middle: middle_name,
          last: last_name,
          prefix: raw_data['Provider Name Prefix Text']&.capitalize,
          suffix: raw_data['Provider Name Suffix Text']&.capitalize,
          credential: raw_data['Provider Credential Text']
        }
      )
    end

    def first_name
      @first_name ||= raw_data['Provider First Name']
    end

    def middle_name
      @middle_name ||= raw_data['Provider Middle Name']
    end

    def last_name
      @last_name ||= raw_data['Provider Last Name (Legal Name)']
    end

    def phone_numbers
      @phone_numbers ||= [raw_data['Provider Business Practice Location Address Telephone Number']]
    end

    def fax_numbers
      @fax_numbers ||= [raw_data['Provider Business Practice Location Address Fax Number']]
    end

    def address
      OpenStruct.new(
        {
          lines: [
            raw_data['Provider First Line Business Practice Location Address'],
            raw_data['Provider Second Line Business Practice Location Address']
          ].reject(&:blank?),
          city: raw_data['Provider Business Practice Location Address City Name'],
          state: raw_data['Provider Business Practice Location Address State Name'],
          zip: format_zip(raw_data['Provider Business Practice Location Address Postal Code'])
        }
      )
    end

    def gender
      raw_data['Provider Gender Code']
    end

    def qualifications
      provided_qualifications = (1..50).map { |index| qualification(index) }.compact
      provided_qualifications.blank? ? [default_qualification] : provided_qualifications
    end

    def qualification(index)
      keys = [
        "Healthcare Provider Taxonomy Code_#{index}",
	      "Provider License Number_#{index}",
	      "Provider License Number State Code_#{index}"
      ]

      return nil if keys.any? { |key| raw_data[key].blank? }

      OpenStruct.new(
        {
          state: raw_data["Provider License Number State Code_#{index}"],
          license_number: raw_data["Provider License Number_#{index}"],
          taxonomy_code: raw_data["Healthcare Provider Taxonomy Code_#{index}"]
        }
      )
    end

    def default_qualification
      @default_qualification
    end
  end
end
