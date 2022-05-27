# frozen_string_literal: true

module Funding
  class PayablePaymentSchedulesImporter
    include ServicePattern

    MONTH_ORDER = [8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7].freeze

    def initialize(attributes:, first_predicted_month_index:)
      @attributes = attributes
      @first_predicted_month_index = first_predicted_month_index
      @missing_providers = []
    end

    # rubocop:disable Rails/Output
    def call
      attributes.each do |id, rows|
        payable = payable(id)

        if payable.nil?
          missing_providers << missing_error_msg(id, rows.first)
          next
        end

        schedule = payable.funding_payment_schedules.create

        row_attributes = attributes[id]
        row_attributes.each do |row_hash|
          row = schedule.rows.create(description: row_hash["Description"])
          Date::MONTHNAMES.compact.each do |month_name|
            month_index = Date::MONTHNAMES.index(month_name)
            row.amounts.create(
              month: month_index,
              year: year_for_month(row_hash["Academic year"], month_index),
              amount_in_pence: row_hash[month_name].to_d * 100,
              predicted: MONTH_ORDER.index(month_index) >= MONTH_ORDER.index(first_predicted_month_index.to_i),
            )
          end
        end
      end

      missing_providers.each do |info|
        puts("Missing organisations\n")
        puts(info)
      end
    end
    # rubocop:enable Rails/Output

    def payable(_id)
      raise(NotImplementedException("implement a payable method"))
    end

    def missing_error_msg(_id, _row_details)
      raise(NotImplementedException("implement a missing_error_msg method"))
    end

  private

    attr_reader :attributes, :first_predicted_month_index, :missing_providers

    def year_for_month(year_string, month_index)
      years = year_string.split("/")
      year_string = [1, 2, 3, 4, 5, 6, 7].include?(month_index) ? "20#{years[1]}" : years[0]
      year_string.to_i
    end
  end
end
