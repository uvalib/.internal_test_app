module CurationConcerns
  module SingleResult
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:find_one]
    end

    def find_one(solr_parameters)
      solr_parameters[:fq] << "_query_:\"{!field f=id}#{blacklight_params.fetch(:id)}\""
    end
  end
end
