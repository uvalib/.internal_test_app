module Libra2

  module BasicMetadata

    extend ActiveSupport::Concern

    included do
      property :part_of, predicate: RDF::Vocab::DC.isPartOf

      property :contributor, predicate: RDF::Vocab::DC.contributor do |index|
        index.as :stored_searchable, :facetable
      end

      property :creator, predicate: RDF::Vocab::DC.creator, multiple: false do |index|
      #property :creator, predicate: RDF::Vocab::DC.creator do |index|
        index.as :stored_searchable, :facetable
      end

      property :description, predicate: RDF::Vocab::DC.description, multiple: false do |index|
      #property :description, predicate: RDF::Vocab::DC.description do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :publisher, predicate: RDF::Vocab::DC.publisher, multiple: false do |index|
      #property :publisher, predicate: RDF::Vocab::DC.publisher do |index|
        index.as :stored_searchable, :facetable
      end

      property :date_created, predicate: RDF::Vocab::DC.created, multiple: false do |index|
      #property :date_created, predicate: RDF::Vocab::DC.created do |index|
        index.as :stored_searchable
      end

      property :date_uploaded, predicate: RDF::Vocab::DC.dateSubmitted, multiple: false do |index|
        index.type :date
        index.as :stored_sortable
      end

      property :date_modified, predicate: RDF::Vocab::DC.modified, multiple: false do |index|
        index.type :date
        index.as :stored_sortable
      end

      property :subject, predicate: RDF::Vocab::DC.subject do |index|
        index.as :stored_searchable, :facetable
      end

      property :language, predicate: RDF::Vocab::DC.language, multiple: false do |index|
      #property :language, predicate: RDF::Vocab::DC.language do |index|
        index.as :stored_searchable, :facetable
      end

      property :rights, predicate: RDF::Vocab::DC.rights do |index|
        index.as :stored_searchable
      end

      property :resource_type, predicate: RDF::Vocab::DC.type, multiple: false do |index|
      #property :resource_type, predicate: RDF::Vocab::DC.type do |index|
        index.as :stored_searchable, :facetable
      end

      property :identifier, predicate: RDF::Vocab::DC.identifier, multiple: false do |index|
        index.as :stored_searchable
      end

      property :based_near, predicate: RDF::Vocab::FOAF.based_near do |index|
        index.as :stored_searchable, :facetable
      end

      property :tag, predicate: RDF::Vocab::DC.relation do |index|
        index.as :stored_searchable, :facetable
      end

      property :related_url, predicate: RDF::RDFS.seeAlso
    end
  end
end
