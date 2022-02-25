# frozen_string_literal: true

require "rails_helper"

module Hesa
  describe RetrieveCollectionJob do
    context "feature flag is off" do
      before { disable_features :sync_from_hesa }

      it "doesn't create a HesaCollectionRequest" do
        expect { described_class.new.perform }.not_to change { HesaCollectionRequest.count }
      end

      it "doesn't call the HESA API" do
        expect(Hesa::Client).not_to receive(:get)
        described_class.new.perform
      end
    end

    context "feature flag is on" do
      let(:trainee) { build(:trainee) }
      let(:current_reference) { "C123" }
      let(:next_date) { DateTime.parse("10/01/2022").utc.iso8601 }
      let(:expected_url) { "https://datacollection.hesa.ac.uk/apis/itt/1.1/CensusData/#{current_reference}/#{next_date}" }
      let(:hesa_api_stub) { ApiStubs::HesaApi.new }
      let(:hesa_xml) { ApiStubs::HesaApi.new.raw_xml }
      let(:ukprn) { hesa_api_stub.student_attributes[:ukprn] }
      let(:last_hesa_collection_request) { HesaCollectionRequest.last }

      before do
        enable_features :sync_from_hesa
        allow(Settings.hesa).to receive(:current_collection_reference).and_return("C123")
        allow(HesaCollectionRequest).to receive(:next_from_date).and_return(next_date)
        allow(Hesa::Client).to receive(:get).and_return(hesa_api_stub.raw_xml)
        allow(Trainees::CreateFromHesa).to receive(:call).and_return([trainee, ukprn])
      end

      it "calls the HESA API" do
        expect(Hesa::Client).to receive(:get).with(url: expected_url)
        described_class.new.perform
      end

      it "creates or updates a trainee from a student node element" do
        expect(Trainees::CreateFromHesa).to(receive(:call).with(student_node: instance_of(Nokogiri::XML::Element)))
        described_class.new.perform
      end

      describe "HesaCollectionRequest" do
        before { described_class.new.perform }

        it "marks the import as successful" do
          expect(last_hesa_collection_request.state).to eq("import_successful")
        end

        it "creates a HesaCollectionRequest" do
          expect { described_class.new.perform }.to change { HesaCollectionRequest.count }.by(1)
        end

        it "stores the xml" do
          expect(last_hesa_collection_request.response_body).to eq(hesa_xml)
        end

        it "stores the requested_at" do
          Timecop.freeze do
            expected_time = Time.zone.now
            expect(last_hesa_collection_request.requested_at.tv_sec).to eq(expected_time.tv_sec)
          end
        end

        it "stores updates_since" do
          expect(last_hesa_collection_request.updates_since).to eq(next_date)
        end
      end

      context "invalid data" do
        let(:trainee) { build(:trainee, provider: nil).tap(&:save) }

        it "sends an error message to Sentry" do
          expect(Sentry).to receive(:capture_message).with("HESA import failed (errors: #{trainee.errors.full_messages}), (ukprn: #{ukprn})")
          described_class.new.perform
        end

        it "marks the import as failed" do
          described_class.new.perform
          expect(last_hesa_collection_request.state).to eq("import_failed")
        end
      end
    end
  end
end
