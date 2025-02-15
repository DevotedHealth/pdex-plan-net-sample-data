require_relative './insurance_plan_factory'
require_relative './organization_factory'
require_relative './network_factory'
require_relative './location_factory'
require_relative './endpoint_factory'
require_relative './organization_generator'
require_relative './pharmacy_organization_generator'
require_relative './practitioner_generator'

module PDEX
  class FHIRGenerator
    RESOURCE_TYPES = [
      # TODO
      # 'InsurancePlan',
      # 'Network',
      'Organization',
      'OrganizationAffiliation',
      'Location',
      'Endpoint',
      'HealthcareService',
      'Practitioner',
      'PractitionerRole'
    ]

    class << self
      def generate(mode)
        puts "create_output_directories"
        create_output_directories
        if mode == :providers
          puts "generate_practitioners"
          generate_practitioners
        end
        if mode == :pharmacy
           puts "generate_pharmacies"
           generate_pharmacies
           puts "generate_pharmacy_orgs"
           generate_pharmacy_orgs
        end
        puts "complete"
      end

      private

      def create_output_directories
        RESOURCE_TYPES.each do |resource_type|
          FileUtils.mkdir_p("output/#{resource_type}")
        end
      end

      def write_resource(resource)
        File.write("output/#{resource.resourceType}/#{resource.id}.json", resource.to_json)
      end

      def generate_resources(data, &block)
        data.each do |nppes_data|
          write_resource(block.call(nppes_data))
        end
      end

      def generate_insurance_plans
        generate_resources(PDEX::NPPESDataRepo.plans) do |nppes_data|
          PDEX::InsurancePlanFactory.new(nppes_data).build
        end
      end

      def generate_managing_orgs
        generate_resources(PDEX::NPPESDataRepo.managing_orgs) do |nppes_data|
          PDEX::OrganizationFactory.new(nppes_data, managing_org: true).build
        end
      end

      def generate_payers
        generate_resources(PDEX::NPPESDataRepo.payers) do |nppes_data|
          PDEX::OrganizationFactory.new(nppes_data, payer: true).build
        end
      end

      def generate_networks
        generate_resources(PDEX::NPPESDataRepo.networks) do |nppes_data|
          PDEX::NetworkFactory.new(nppes_data).build
        end
      end

      def generate_locations
        generate_resources(PDEX::NPPESDataRepo.organizations) do |nppes_data|
          PDEX::LocationFactory.new(nppes_data).build
        end
      end

      def generate_endpoints
        generate_resources(PDEX::NPPESDataRepo.organizations) do |nppes_data|
          PDEX::EndpointFactory.new(nppes_data, 'Organization').build
        end
      end

      # Generate Organizations, HealthcareServices, and OrganizationAffiliations
      def generate_organizations
        PDEX::NPPESDataRepo.organizations.each do |nppes_data|
          PDEX::OrganizationGenerator.new(nppes_data).generate.each do |resource|
            write_resource(resource)
          end
        end
      end

      # Generate Practitioners and PractitionerRoles
      def generate_practitioners

        mut = Mutex.new
        q = SizedQueue.new(100)
        threads = []
        2.times do
          threads << Thread.new do
            while !q.closed? || (q.closed? && !q.empty?) do
              elem = q.pop
              next unless elem
              PDEX::PractitionerGenerator.new(elem).generate.each do |resource|
                write_resource(resource)
              end
            end
          end
        end

        PDEX::NPPESDataRepo.practitioners.each do |nppes_data|
          q.push(nppes_data)
        end
        q.close
        threads.map(&:join)
      end

      def generate_pharmacies
         generate_resources(PDEX::NPPESDataRepo.pharmacies) do |nppes_data|
          PDEX::LocationFactory.new(nppes_data, pharmacy: true).build
        end
      end

      def generate_pharmacy_orgs
        mut = Mutex.new
        q = SizedQueue.new(100)
        threads = []
        2.times do
          threads << Thread.new do
            while !q.closed? || (q.closed? && !q.empty?) do
              elem = q.pop
              next unless elem
              PDEX::PharmacyOrganizationGenerator.new(elem).generate.each do |resource|
                write_resource(resource)
              end
            end
          end
        end

        # Pharmacy_orgs is a PharmacyOrgData, not an NPPES data... 
        PDEX::NPPESDataRepo.pharmacy_orgs.each do |nppes_data|
          q.push(nppes_data)
        end
        q.close
        threads.map(&:join)
      end
    end
  end
end
