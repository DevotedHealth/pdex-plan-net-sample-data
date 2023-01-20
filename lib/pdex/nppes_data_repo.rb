module PDEX
  class NPPESDataRepo
    class << self
      def plans
        @plans ||= []
      end

      def payers
        @payers ||= []
      end

      def managing_orgs
        @managing_orgs ||= []
      end

      def networks
        @networks ||= []
      end

      def organizations
        @organizations ||= []
      end

      def practitioners
        @practitioners ||= []
      end

      def organization_networks
        @organization_networks ||= {}
      end

      def pharmacies
        @pharmacies ||= []
      end

      def pharmacy_orgs
        @pharmacy_orgs ||= []
      end

      # Use MA data if state has no data
      DEFAULT_STATE = 'MA'

      def networks_by_state(state)
        networks.filter{|network| network.address.state == state}
      end

      def managing_orgs_by_state(state)
        managing_orgs.filter{|org| org.address.state == state}
      end

      def organizations_by_state(state)
        organizations.filter{|org| org.address.state == state}
      end
    end
  end
end
