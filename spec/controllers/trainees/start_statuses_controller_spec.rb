# frozen_string_literal: true

require "rails_helper"

describe Trainees::StartStatusesController, type: :controller do
  include ActiveJob::TestHelper

  describe "#update" do
    let(:current_user) { build_current_user }
    let(:page_context) { nil }

    let(:send_request) do
      post(:update,
           params: {
             trainee_id: trainee,
             trainee_start_status_form: {
               "commencement_status" => "itt_started_on_time",
               "commencement_date(3i)" => "",
               "commencement_date(2i)" => "",
               "commencement_date(1i)" => "",
               context: page_context,
             },
           })
    end

    before do
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(controller).to receive(:authorize_trainee).and_return(true)
    end

    context "when the trainee is draft" do
      context "but not submission ready" do
        let(:trainee) { create(:trainee, :with_study_mode_and_course_dates) }

        it "does not submit for TRN" do
          expect(Trainees::SubmitForTrn).not_to receive(:call)
          send_request
        end
      end

      context "and submission ready" do
        let(:trainee) { create(:trainee, :completed) }

        it "submits for TRN" do
          expect(Trainees::SubmitForTrn).to receive(:call).with({ trainee: trainee })
          send_request
        end
      end
    end

    context "when the trainee is not draft" do
      let(:trainee) { create(:trainee, :submitted_for_trn) }

      it "does not submit them for TRN" do
        expect(Trainees::SubmitForTrn).not_to receive(:call)
        send_request
      end
    end

    context "updating trainee start status in a different context" do
      let(:trainee) { create(:trainee, :submitted_for_trn) }

      before { send_request }

      context "delete" do
        let(:page_context) { :delete }

        it "redirects to the delete forbidden page" do
          expect(response).to redirect_to(trainee_forbidden_deletes_path(trainee))
        end
      end

      context "withdrawal form has not started and contains no date" do
        let(:page_context) { :withdraw }

        it "redirects to the withdrawal page" do
          expect(response).to redirect_to(trainee_withdrawal_path(trainee))
        end
      end

      context "withdrawal form has started and contains a withdrawal date before the commencement date" do
        let(:trainee) { create(:trainee, :submitted_for_trn, withdraw_date: Date.new(2022, 1, 1)) }
        let(:page_context) { :withdraw }
        let(:send_request) do
          post(:update,
               params: {
                 trainee_id: trainee,
                 trainee_start_status_form: {
                   "commencement_status" => "itt_started_on_time",
                   "commencement_date(3i)" => "2",
                   "commencement_date(2i)" => "1",
                   "commencement_date(1i)" => "2022",
                   context: page_context,
                 },
               })
        end

        it "redirects to the withdrawal page" do
          expect(response).to redirect_to(trainee_confirm_withdrawal_path(trainee))
        end
      end
    end
  end
end
