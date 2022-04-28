# frozen_string_literal: true

module Funding
  module Parsers
    class ProviderPaymentSchedules < PaymentSchedulesBase
      class << self
        def id_column
          "Provider ID"
        end
      end
    end
  end
end
