require_relative './lat_long'

module PDEX
  module Position
    def position
      return if address.nil?
      coords = COORDINATES[address.lines.first]
      return if coords.blank?

      {
        longitude: coords[:x],
        latitude: coords[:y]
      }
    end
  end
end
