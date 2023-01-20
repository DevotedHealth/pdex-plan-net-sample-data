STDOUT.sync = true
require 'csv'
require 'pry'
require_relative 'lib/pdex'

mode = ENV['LOAD'] == 'pharmacy' ? :pharmacy : :providers

puts "Loading NPPES data"
PDEX::NPPESDataLoader.load(mode)

puts "Generating FHIR data"
PDEX::FHIRGenerator.generate(mode)
