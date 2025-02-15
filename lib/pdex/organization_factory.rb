require 'fhir_models'
require_relative 'address'
require_relative 'telecom'
require_relative 'utils/states'
require_relative 'utils/nucc_codes'

module PDEX
  class OrganizationFactory
    include Address
    include Telecom

    attr_reader :source_data, :resource_type, :profile, :payer, :managing_org, :pharmacy, :npi 

    def initialize(nppes_organization, payer: false, managing_org: false, pharmacy: false)
      @source_data = nppes_organization
      @resource_type = 'organization'
      @profile = ORGANIZATION_PROFILE_URL
      @payer = payer
      @managing_org = managing_org
      @pharmacy = pharmacy
      @npi = source_data.npi 
    end

    def build
      FHIR::Organization.new(build_params)
    end

    private

    def build_params
      params = {
        id: id,
        meta: meta,
        active: true,
        type: type,
        name: name,
        telecom: telecom,
        address: address_with_geolocation,
      }

      params.merge(identifier: identifier) if !identifier.nil?

      return params if payer || managing_org

      # params.merge(contact: contact)
      params
    end

    def id
      "organization-#{source_data.npi}"
    end

    def meta
      {
        profile: [profile],
        lastUpdated: '2020-08-17T10:03:10Z'
      }
    end

    def pharmacy_org_identifier
      {
        use: 'official',
        system: 'http://i.made/this/up',
        value: '',
      }
   
    end

    def identifier
      return nil if @pharmacy || @npi.nil? || @npi.length > 10
      {
        use: 'official',
        system: 'http://hl7.org/fhir/sid/us-npi',
        value: @npi,
        assigner: {
          display: 'Centers for Medicare and Medicaid Services'
        }
      }
    end

    def type
      if payer
        payertype
      elsif  managing_org || pharmacy
        factype
      else
        prvgrptype
      end
    end

    def prvgrptype
      [
        {
          coding: [
            {
              system: ORGANIZATION_TYPE_SYSTEM_URL,
              code: 'prvgrp',
              display: 'Provider Group'
            }
          ],
          text: 'A healthcare provider entity'
        }
      ]
    end

    def payertype
      [
        {
          coding: [
            {
              system: ORGANIZATION_TYPE_SYSTEM_URL,
              code: 'payer',
              display: 'Payer'
            }
          ],
          text: 'Payer'
        }
      ]
    end

    def factype
      [
        {
          coding: [
            {
              system: ORGANIZATION_TYPE_SYSTEM_URL,
              code: 'fac',
              display: 'Facility'
            }
          ],
          text: 'A physical healthcare facility.'
        }
      ]
    end

    def name
      source_data.name
    end

    def contact
      {
        purpose: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/contactentity-type',
              code: 'ADMIN',
              display: 'Administrative'
            }
          ]
        },
        name: {
          use: 'official',
          text: "#{source_data.contact_first_name} #{source_data.contact_last_name}",
          family: source_data.contact_last_name,
          given: [source_data.contact_first_name]
        },
        telecom: [],
        address: address
      }
    end
  end
end
