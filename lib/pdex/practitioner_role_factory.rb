require 'fhir_models'
require 'securerandom'
require_relative 'fhir_elements'
require_relative 'telecom'
require_relative 'utils/formatting'
require_relative 'utils/randoms'

module PDEX
  class PractitionerRoleFactory
    include Formatting
    include FHIRElements
    include Telecom
    include Randoms

    attr_reader :source_data, :organization_data, :network_data 

    def initialize(nppes_data, organization:, networks:)
      @source_data = nppes_data
      @organization_data = organization
      @network_data = networks
    end

    def build
      FHIR::PractitionerRole.new(
        {
          id: id,
          meta: meta,
          identifier: identifier,
          active: true,
          extension: extensions,
          practitioner: practitioner,
          organization: organization,
          code: code,
          specialty: specialty,
          location: location,
          healthcareService: services,
          telecom: telecom,
          availableTime: available_time
        }
      )
    end

    private

    def id
      "practitioner-role-#{source_data.npi}"
    end

    def meta
      {
        profile: [PRACTITIONER_ROLE_PROFILE_URL],
        lastUpdated: '2020-08-17T10:03:10Z'
      }
    end

    def identifier
      return nil
      # return nil if organization_data.nil?
      # {
      #   use: 'secondary',
      #   type: {
      #     coding: [
      #       {
      #         system: 'http://terminology.hl7.org/CodeSystem/v2-0203',
      #         code: 'PRN',
      #         display: 'Provider Number'
      #       }
      #     ],
      #     text: 'Hospital ID'
      #   },
      #   system: "https://#{format_for_url(organization_data.name)}.com",
      #   value: SecureRandom.hex(7)
      # }
    end

    def extensions
      return nil if network_data.nil?
      network_data.map do |network|
        {
          url: NETWORK_REFERENCE_EXTENSION_URL,
          valueReference: {
            reference: "Organization/#{network.npi}",
            display: network.name
          }
        }
      end
    end

    def practitioner
      {
        reference: "Practitioner/practitioner-#{source_data.npi}",
        display: "#{source_data.name.first} #{source_data.name.last}"
      }
    end

    def organization
      return nil if organization_data.nil?
      {
        reference: "Organization/#{organization_data.npi}",
        display: organization_data.name
      }
    end

    def code
      [
        {
          coding: [
            {
              system: PRACTITIONER_ROLE_VALUE_SET_URL,
              code: 'ph',
              display: 'Physician'
            }
          ]
        }
      ]
    end

    def specialty
      source_data.qualifications
        .map { |qualification| nucc_codeable_concept(qualification) }
        .first
    end

    def location
      return nil if organization_data.nil?
      [
        {
          reference: "Location/#{organization_data.npi}",
          display: organization_data.name
        }
      ]
    end

    def available_time
      nil
    end

    def services
      return nil if organization_data.nil?
      [
        {
          reference: "HealthcareService/#{format_for_url(category_type(organization_data.name))[0..30]}-healthcareservice-#{organization_data.npi}",
          display: organization_data.name
        }
      ]
    end
  end
end
