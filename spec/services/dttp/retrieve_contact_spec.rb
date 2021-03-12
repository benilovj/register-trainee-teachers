# frozen_string_literal: true

require "rails_helper"

module Dttp
  describe RetrieveContact do
    describe "#call" do
      let(:contact_entity_id) { SecureRandom.uuid }
      let(:trainee) { create(:trainee, dttp_id: contact_entity_id) }
      let(:filters) { "emailaddress1,firstname,lastname,contactid" }
      let(:path) { "/contacts(#{trainee.dttp_id})?$select=#{filters}" }

      before do
        allow(AccessToken).to receive(:fetch).and_return("token")
        allow(Client).to receive(:get).with(path).and_return(dttp_response)
      end

      context "filtered params" do
        let(:parsed_response) do
          {
            "contactid" => "XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
            "firstname" => "John",
            "lastname" => "Smith",
          }
        end
        let(:dttp_response) { double(code: 200, body: parsed_response.to_json) }

        it "returns a parsed response" do
          expect(described_class.call(trainee: trainee)).to eq(parsed_response)
        end
      end

      context "HTTP error" do
        let(:status) { 400 }
        let(:body) { "error" }
        let(:headers) { { foo: "bar" } }
        let(:dttp_response) { double(code: status, body: body, headers: headers) }

        it "raises a HttpError error with the response body as the message" do
          expect(Client).to receive(:get).with(path).and_return(dttp_response)
          expect {
            described_class.call(trainee: trainee)
          }.to raise_error(Dttp::RetrieveContact::HttpError, "status: #{status}, body: #{body}, headers: #{headers}")
        end
      end
    end
  end
end
