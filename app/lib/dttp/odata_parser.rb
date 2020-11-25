# frozen_string_literal: true

module Dttp
  class OdataParser
    class << self
      def entity_id(trainee_id, response)
        contact_url = response.headers["odata-entityid"]

        if contact_url.blank?
          raise DttpIdNotReturnedError,
                "failed to retrieve the entity ID from #{response.headers} with #{response.body} for trainee: #{trainee_id}"
        end

        extract_uuid(contact_url)
      end

      def extract_uuid(string_source)
        uuid_pattern = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
        uuid = string_source.match(uuid_pattern).to_s

        raise DttpIdNotReturnedError, "failed to extract UUID from #{string_source} for trainee: #{trainee.id}" if uuid.blank?

        uuid
      end
    end
  end
end
