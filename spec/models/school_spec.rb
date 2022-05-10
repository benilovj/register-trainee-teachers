# frozen_string_literal: true

require "rails_helper"

describe School do
  describe "associations" do
    it { is_expected.to have_many(:lead_school_users) }
    it { is_expected.to have_many(:users).through(:lead_school_users) }
    it { is_expected.to have_many(:funding_payment_schedules) }
    it { is_expected.to have_many(:funding_trainee_summaries) }
  end

  context "callbacks" do
    it "updates the tsvector column with relevant info when the school is updated" do
      school = create(:school)
      expect {
        school.update(urn: "12345678", name: "St Leo's and Southmead/School", postcode: "sw1a 1aa", town: "london")
      }.to change { school.reload.searchable }.to(
        "'12345678':1 '1aa':13 'and':5,9 'leo':3 'leos':8 'london':15 's':4 'school':11 'southmead':10 'southmead/school':6 'st':2,7 'sw1a':12 'sw1a1aa':14",
      )
    end
  end
end
