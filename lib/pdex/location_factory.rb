require 'fhir_models'
require_relative 'address'
require_relative 'telecom'
require_relative 'utils/formatting'

module PDEX
  class LocationFactory
    include Address
    include Telecom
    include Formatting
    include ShortName

    attr_reader :source_data, :pharmacy

    def initialize(nppes_data, pharmacy: false)
      @source_data = nppes_data
      @pharmacy = pharmacy
    end

    def build
      FHIR::Location.new(
        {
          id: id,
          meta: meta,
          identifier: identifier,
          status: 'active',
          name: location_name,
          description: description,
          type: type,
          telecom: telecom,
          address: address,
          position: position,
          managingOrganization: managing_organization,
        }
      )
    end

    private

    def id
      source_data.npi
    end

    def pharmacy_organization_id
      digest_name(location_name)
    end

    def organization_id
      return pharmacy_organization_id if @pharmacy
      source_data.npi
    end

    def meta
      {
        profile: [LOCATION_PROFILE_URL],
        lastUpdated: '2020-08-17T10:03:10Z'
      }
    end

    def accessibility_extension
      return if pharmacy
      {
        url: ACCESSIBILITY_EXTENSION_URL,
        valueCodeableConcept: {
          coding: [
            {
              system: ACCESSIBILITY_CODE_SYSTEM_URL,
              code: 'handiaccess',
              display: 'handicap accessible'
            }
          ],
          text: 'Offers a variety of services and programs for persons with disabilities'
        }
      }
    end

    def new_patients_extension
      return if pharmacy
      {
        url: NEW_PATIENTS_EXTENSION_URL,
        extension: [
          {
            url: ACCEPTING_NEW_PATIENTS_EXTENSION_URL,
            valueCodeableConcept: {
              coding: [
                {
                  system: ACCEPTING_PATIENTS_CODE_SYSTEM_URL,
                  code: accepting_patients_code(location_name.length)
                }
              ]
            }
          }
        ]
      }
    end

    def identifier
      {
        use: 'secondary',
        system: "https://#{format_for_url(location_name)}.com",
        value: 'main campus',
        assigner: {
          reference: "Organization/#{organization_id}",
          display: organization_name
        }
      }
    end

    def location_name
      source_data.name
    end

    def pharmacy_org_name
      short_name(source_data.name)
    end

    def organization_name
      return pharmacy_org_name if pharmacy
      source_data.name
    end

    def description
      "Main campus of #{location_name}"
    end

    def type
      return unless pharmacy
      [
        {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/v3-RoleCode',
              code: 'OUTPHARM'
            }
          ],
          text: 'Outpatient pharmacy'
        }
      ]
    end

    def managing_organization
      {
        reference: "Organization/#{organization_id}",
        display: organization_name
      }
    end

    def hours_of_operation
      [
        {
          daysOfWeek: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
          allDay: true
        }
      ]
    end

    def availability_exceptions
      'visiting hours from 6:00 am - 10:00 pm'
    end

    def position
      source_data.position
    end
  end
end
