require_relative './healthcare_service_factory'
require_relative './nppes_data_repo'
require_relative './organization_factory'
require_relative './pharmacy_organization_affiliation_factory'
require_relative './utils/nucc_constants'

module PDEX

  class PharmacyOrganizationGenerator < OrganizationGenerator
    include ShortName

    def generate
      locations = pharmacies_by_organization(organization)
      [organization, organization_affiliation(locations)].concat(organization_services(locations))
    end

    private

    # call with pharmacy flag, or call pharmacy_org_data with appropriate arguments
    def organization
      PDEX::OrganizationFactory.new(nppes_data, pharmacy:true).build
    end

    def organization_affiliation(locs)
      PDEX::PharmacyOrganizationAffiliationFactory.new(
        nppes_data,
        networks: networks,
        services: organization_services(locs),
        managing_org: nil,
        locations: locs
      ).build
    end

    def pharmacies_by_organization(organization)
      PDEX::NPPESDataRepo.pharmacies.filter {|pharm| short_name(pharm.name) == organization.name}
    end

    def provided_by
      {
        reference: "Organization/organization-#{nppes_data.npi}",
        display: nppes_data.name
      }
    end

   # Add a single service -- pharmacy...
    def organization_services(locs)
      @organization_services ||= [ PDEX::HealthcareServiceFactory.new(
        nppes_data, 
        locations: locs,
        provided_by: provided_by, 
        category_type: HEALTHCARE_SERVICE_CATEGORY_TYPES[:pharmacy]
      ).build ]
    end
  end
end
