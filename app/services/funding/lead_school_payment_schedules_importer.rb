# frozen_string_literal: true

module Funding
  class LeadSchoolPaymentSchedulesImporter < PayablePaymentSchedulesImporter
    def payable(id)
      School.find_by(urn: id)
    end

    def missing_error_msg(id, row_details)
      "Lead school URN: #{id} (#{row_details['Lead school name']})"
    end
  end
end
