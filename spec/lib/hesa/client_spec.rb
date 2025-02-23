# frozen_string_literal: true

require "rails_helper"

module Hesa
  describe Client do
    let(:url) { "http://example.com" }
    let(:mechanize) { Mechanize.new }
    let(:login_page) { double(:form) }

    subject { Client.new }

    before do
      allow(Settings.hesa).to receive(:username).and_return("test@example.com")
      allow(Settings.hesa).to receive(:password).and_return("test12345")
      allow(subject).to receive(:agent).and_return(mechanize)
      allow(subject).to receive(:login).and_return(true)
    end

    describe ".login" do
      before do
        login_form = Struct.new(:Username, :Password, :button_with).new
        allow(login_form).to receive(:Username=).with(Settings.hesa.username)
        allow(login_form).to receive(:Password=).with(Settings.hesa.password)
        allow(login_form).to receive(:button_with).with(any_args)
        allow(login_page).to receive(:form).and_return(login_form)
        allow(mechanize).to receive(:get).and_return(login_page)
        allow(mechanize).to receive(:submit)
        allow(subject).to receive(:agent).and_return(mechanize)
      end

      xit "logs in successfully" do
        expect(subject.send(:login)).to be(true)
      end
    end

    describe ".get" do
      let(:sample_page) { Struct.new(:body).new("Test") }

      before do
        allow(mechanize).to receive(:get).with(url).and_return(sample_page)
      end

      it "returns XML from URL" do
        expect(subject.get(url: url)).to eql("Test")
      end
    end

    describe ".upload_trn_file" do
      let(:sample_page) { Struct.new(:body).new("True") }
      let(:file) { double }

      before do
        allow(mechanize).to receive(:post).with(url, file: file).and_return(sample_page)
      end

      it "sends a form post request with file data" do
        subject.upload_trn_file(url: url, file: file)
      end
    end
  end
end
