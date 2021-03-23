# frozen_string_literal: true

require "rails_helper"

module Diversities
  describe EthnicBackgroundForm, type: :model do
    let(:params) { {} }
    let(:trainee) { create(:trainee, :diversity_disclosed) }
    let(:form_store) { class_double(FormStore) }

    subject { described_class.new(trainee, params, form_store) }

    before do
      allow(form_store).to receive(:get).and_return(nil)
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:ethnic_background) }
    end

    describe "#stash" do
      it "uses FormStore to temporarily save the fields under a key combination of trainee ID and ethnic_background" do
        expect(form_store).to receive(:set).with(trainee.id, :ethnic_background, subject.fields)

        subject.stash
      end
    end

    describe "#save!" do
      let(:ethnic_background) { Dttp::CodeSets::Ethnicities::MAPPING.keys.sample }

      before do
        allow(form_store).to receive(:get).and_return({ "ethnic_background" => ethnic_background })
        allow(form_store).to receive(:set).with(trainee.id, :ethnic_background, nil)
      end

      it "takes any data from the form store and saves it to the database" do
        expect { subject.save! }.to change(trainee, :ethnic_background).to(ethnic_background)
      end
    end
  end
end
