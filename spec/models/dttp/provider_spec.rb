# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dttp::Provider, type: :model do
  subject { create(:dttp_provider) }

  it { is_expected.to have_db_index(:dttp_id) }

  describe "associations" do
    it {
      expect(subject).to belong_to(:provider)
      .class_name("::Provider")
      .with_primary_key(:dttp_id)
      .with_primary_key(:dttp_id)
      .optional
    }
  end
end
