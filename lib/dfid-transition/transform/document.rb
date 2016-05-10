require 'securerandom'
require 'cgi'
require 'govuk/presenters/govspeak'
require 'dfid-transition/transform/html'

module DfidTransition
  LINKED_DEVELOPMENT_OUTPUT_URI =
    %r{http://linked-development.org/r4d/output/(?<id>[0-9]+?)/}
  ORGANISATION_CONTENT_ID       = "b994552-7644-404d-a770-a2fe659c661f".freeze

  module Transform
    class Document
      attr_reader :solution
      attr_accessor :content_id

      def initialize(solution)
        @solution = solution
        @content_id = SecureRandom.uuid
      end

      def original_id
        match = solution[:output].to_s.match(/\/(?<id>[0-9]+?)\//)
        match[:id]
      end

      def original_url
        output_url = solution[:output].to_s
        match = output_url.match LINKED_DEVELOPMENT_OUTPUT_URI
        if match
          "http://r4d.dfid.gov.uk/Output/#{match[:id]}/Default.aspx"
        else
          output_url
        end
      end

      def title
        title = solution[:title].to_s
        unescaped_title = DfidTransition::Transform::Html.unescape_three_times(title)
        unescaped_title.strip
      end

      def summary
        "This is an example summary for output #{original_id}. The citation would ordinarily
         appear here but we need CABI to include that data in their triples."
      end

      def base_path
        "/dfid-research-outputs/#{original_id}"
      end

      def metadata
        {
          document_type: "dfid_research_output",
          country: countries
        }
      end

      def public_updated_at
        solution[:date].to_s
      end

      def countries
        solution[:countryCodes].to_s.split(' ')
      end

      def format_specific_metadata
        { country: countries }
      end

      def organisations
        [ORGANISATION_CONTENT_ID]
      end

      def details
        {
          body: abstract,
          metadata: metadata
          # change_history: change_history
        }

        # Attachments would be handled here
        #.tap do |details_hash|
        #  details_hash[:attachments] = attachments if document.attachments
        #end
      end

      def abstract
        unescaped_abstract = DfidTransition::Transform::Html.unescape_three_times(
          solution[:abstract].to_s)

        Govuk::Presenters::Govspeak.present(unescaped_abstract)
      end

      def body
        details[:body]
      end

      def to_json
        {
          content_id:        content_id,
          base_path:         base_path,
          title:             title,
          description:       summary,
          document_type:     'dfid_research_output',
          schema_name:       "specialist_document",
          publishing_app:    "specialist-publisher",
          rendering_app:     "specialist-frontend",
          locale:            "en",
          phase:             'live',
          public_updated_at: public_updated_at,
          details:           details,
          routes:            [
                               {
                                 path: base_path,
                                 type: "exact",
                               }
                             ],
          redirects:         [],
          update_type:       'minor',
          organisations:     organisations
        }
      end
    end
  end
end