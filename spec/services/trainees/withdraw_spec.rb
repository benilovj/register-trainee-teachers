# frozen_string_literal: true

require "rails_helper"

module Trainees
  describe Withdraw do
    let(:trainee) { create(:trainee, hesa_id: nil) }

    describe "#call" do
      context "passed a non-HESA trainee that has had attributes set" do
        it "persists any changes" do
          trainee.first_names = "Edmund"
          described_class.call(trainee: trainee)
          trainee.reload
          expect(trainee.first_names).to eq("Edmund")
        end

        it "queues a withdrawal to DQT when `withdrawal` option is set" do
          expect(Dqt::WithdrawTraineeJob).to receive(:perform_later).with(trainee)
          described_class.call(trainee: trainee)
        end
      end

      context "passed a HESA trainee that has had attributes set" do
        let(:trainee) { create(:trainee, hesa_id: "12345678") }

        it "persists any changes" do
          trainee.first_names = "Edmund"
          described_class.call(trainee: trainee)
          trainee.reload
          expect(trainee.first_names).to eq("Edmund")
        end

        it "queues a withdrawal to DQT when `withdrawal` option is set" do
          expect(Dqt::WithdrawTraineeJob).not_to receive(:perform_later).with(trainee)
          described_class.call(trainee: trainee)
        end
      end
    end
  end
end
