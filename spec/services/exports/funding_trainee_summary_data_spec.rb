# frozen_string_literal: true

require "rails_helper"

module Exports
  describe FundingTraineeSummaryData do
    let!(:lead_school) {create(:school, lead_school: true)}
    let!(:trainee_summary) {create(:trainee_summary, :for_school)}
    let!(:trainee_summary_row) { create(:trainee_summary_row, trainee_summary: trainee_summary, lead_school_urn: lead_school.urn)}
    let!(:tiered_bursary_amount) {create(:trainee_summary_row_amount, :with_tiered_bursary, row: trainee_summary_row)}

    before do
      create(:academic_cycle, :current)
    end

    subject { described_class.new(lead_school) }

    describe "#data" do
      let(:expected_output) do
        {
          "Funding type" => tiered_bursary_amount.payment_type,
          "Route" => trainee_summary_row.route,
          "Course" => trainee_summary_row.subject,
          "Lead school" => trainee_summary_row.lead_school_name,
          "Tier" => tiered_bursary_amount.tier,
          "Number of trainees" => tiered_bursary_amount.number_of_trainees,
          "Amount per trainee" => "£#{tiered_bursary_amount.amount_in_pence.to_f / 100}",
          "Total" => "£#{tiered_bursary_amount.number_of_trainees * tiered_bursary_amount.amount_in_pence.to_f / 100}"
        }
      end

      it "sets the correct headers" do
        expect(subject.data).to include(expected_output.keys.join(","))
      end

      it "sets the correct row values" do
        expect(subject.data).to include(expected_output.values.join(","))
      end
    end
  end
end
