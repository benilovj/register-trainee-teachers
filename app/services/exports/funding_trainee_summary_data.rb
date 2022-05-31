# frozen_string_literal: true

module Exports
  class FundingTraineeSummaryData
    VULNERABLE_CHARACTERS = %w[= + - @].freeze

    def initialize(school)
      @data_for_export = format_rows(school)
    end

    def data
      header_row ||= data_for_export.first&.keys

      CSV.generate(headers: true) do |rows|
        rows << header_row

        data_for_export.map(&:values).each do |value|
          rows << value.map { |v| sanitise(v) }
        end
      end
    end

    def filename
      "#{Time.zone.now.strftime('%Y-%m-%d_%H-%M_%S')}_Register-trainee-teachers_exported_records.csv"
    end

    private

      attr_reader :data_for_export

      def format_rows(school)
        trainee_summary_rows = Funding::TraineeSummaryRow.where(lead_school_urn: school.urn)
        trainee_summary_rows.map do |row|
          trainee_summary_row_amount = Funding::TraineeSummaryRowAmount.where(funding_trainee_summary_row_id: row.id).first
          {
            "Funding type" => trainee_summary_row_amount.payment_type,
            "Route" => row.route,
            "Course" => row.subject,
            "Lead school" => row.lead_school_name,
            "Tier" => trainee_summary_row_amount.tier.present? ? trainee_summary_row_amount.tier : "Not applicable",
            "Number of trainees" => trainee_summary_row_amount.number_of_trainees,
            "Amount per trainee" => to_pounds(trainee_summary_row_amount.amount_in_pence),
            "Total" => to_pounds(trainee_summary_row_amount.number_of_trainees * trainee_summary_row_amount.amount_in_pence)
          }
        end
      end

      def sanitise(value)
        return value unless value.is_a?(String)

        value.start_with?(*VULNERABLE_CHARACTERS) ? value.prepend("'") : value
      end

      def to_pounds(value_in_pence)
        "£#{value_in_pence.to_f/100}"
      end
  end
end
