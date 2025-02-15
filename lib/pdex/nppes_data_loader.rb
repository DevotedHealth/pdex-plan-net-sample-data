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
    def load(mode)
        load_managing_organizations
        load_networks
        load_organizations
        if mode == :providers
          puts "Loading practitioners"
          load_practitioners
        end
        if mode == :pharmacy
          puts "Loading pharmacies"
          load_pharmacies
          puts "Loading pharmacy orgs"
          load_pharmacy_orgs
        end
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
        mut = Mutex.new
        q = SizedQueue.new(100)
        threads = []
        2.times do
          threads << Thread.new do
            while !q.closed? || (q.closed? && !q.empty?) do
              elem = q.pop
              next unless elem
              transformed = PDEX::NPPESPractitioner.new(elem)
              mut.synchronize do
                NPPESDataRepo.practitioners << transformed
              end
            end
          end
        end

        Dir.glob(File.join(PRACTITIONER_FILES_DIR, '*.csv')) do |filename|
          puts "Loading #{filename}"
          CSV.foreach(filename, headers: true) do |row|
            q.push(row)
          end
        end
        q.close
        threads.map(&:join)
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
        unique_org_names = {}
        NPPESDataRepo.pharmacies.each do |pharmacy|
          name = short_name(pharmacy.name)
          if unique_org_names[name].nil?
            unique_org_names[name] = [pharmacy]
          else
            unique_org_names[name].push(pharmacy)
          end
        end

        unique_org_names.keys.each do |name|
          if unique_org_names[name].length == 1
            NPPESDataRepo.pharmacy_orgs << PDEX::PharmacyOrgData.new(unique_org_names[name][0], name)
          else
            # We can't reliably put an address/phone number on the pharmacy org if we know there is more than one
            NPPESDataRepo.pharmacy_orgs << PDEX::PharmacyOrgData.new(nil, name)
          end
        end
      end
    end
  end
end
