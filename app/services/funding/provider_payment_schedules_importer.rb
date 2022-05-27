# frozen_string_literal: true

module Funding
  class ProviderPaymentSchedulesImporter < PayablePaymentSchedulesImporter
    def payable(id)
      Provider.find_by(accreditation_id: id)
    end

    def missing_error_msg(id, row_details)
      "Provider Accreditation ID: #{id} (#{row_details['Provider name']})"
    end
  end
end
