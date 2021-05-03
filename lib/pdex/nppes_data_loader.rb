require 'csv'
require_relative 'nppes_data_repo'
require_relative 'shortname'

module PDEX

  class NPPESDataLoader

    DATA_DIR = File.join(__dir__, '..', '..', 'sample-data')
    MANAGING_ORG_DIR = File.join(DATA_DIR, 'managing_orgs')
    ORGANIZATION_FILES_DIR = File.join(DATA_DIR, 'organizations')
    PHARMACY_FILES_DIR = File.join(DATA_DIR, 'pharmacies')
    PRACTITIONER_FILES_DIR = File.join(DATA_DIR, 'practitioners')
    NETWORK_FILES_DIR = File.join(DATA_DIR, 'networks')

    class << self
    include ShortName
    def load
        load_managing_organizations
        load_networks
        load_organizations
        load_practitioners
        load_pharmacies
        load_pharmacy_orgs
      end

      private

      def load_managing_organizations
        Dir.glob(File.join(MANAGING_ORG_DIR, '*.csv')) do |filename|
          CSV.foreach(filename, headers: true) do |row|
            if insurance_plan? row
              NPPESDataRepo.plans << PDEX::NPPESManagingOrg.new(row)
            elsif managing_org? row
              NPPESDataRepo.managing_orgs << PDEX::NPPESManagingOrg.new(row, managing_org: true)
            elsif payer? row
              NPPESDataRepo.payers << PDEX::NPPESManagingOrg.new(row, payer: true)
            end
          end
        end
      end

      def insurance_plan?(row)
        row['is_plan'].downcase == 'true' && row['type'].downcase == 'ins'
      end

      def managing_org?(row)
        row['type'].downcase == 'prov' && row['is_plan'].downcase == 'false'
      end

      def payer?(row)
        row['type'].downcase == 'ins'
      end

      def load_networks
        Dir.glob(File.join(NETWORK_FILES_DIR, '*.csv')) do |filename|
          CSV.foreach(filename, headers: true) do |row|
            NPPESDataRepo.networks << PDEX::NPPESNetwork.new(row)
          end
        end
      end

      def load_organizations
        Dir.glob(File.join(ORGANIZATION_FILES_DIR, '*.csv')) do |filename|
          CSV.foreach(filename, headers: true) do |row|
            NPPESDataRepo.organizations << PDEX::NPPESOrganization.new(row)
          end
        end
      end

      def load_practitioners
        Dir.glob(File.join(PRACTITIONER_FILES_DIR, '*.csv')) do |filename|
          CSV.foreach(filename, headers: true) do |row|
            NPPESDataRepo.practitioners << PDEX::NPPESPractitioner.new(row)
          end
        end
      end

      def load_pharmacies
        Dir.glob(File.join(PHARMACY_FILES_DIR, '*.csv')) do |filename|
          CSV.foreach(filename, headers: true) do |row|
            NPPESDataRepo.pharmacies << PDEX::PharmacyData.new(row)
          end
        end
      end

      def load_pharmacy_orgs
        # - iterate through NPPESDataRepo.pharmacies and generate PharmacyOrg
        #   objects to hold the data
        # - add the pharmacy orgs to NPPESDataRepo.pharmacy_orgs

        unique_org_names = NPPESDataRepo.pharmacies.map{ |pharmacy| short_name(pharmacy.name)}.uniq.sort 
         unique_org_names.each {|name| 
          NPPESDataRepo.pharmacy_orgs << PDEX::PharmacyOrgData.new(name)
        }
      end
    end
  end
end
