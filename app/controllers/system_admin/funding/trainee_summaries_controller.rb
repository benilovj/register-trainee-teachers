# frozen_string_literal: true

module SystemAdmin
  module Funding
    class TraineeSummariesController < ApplicationController
      def show
        respond_to do |format|
          format.html do
            @trainee_summary_view = ::Funding::TraineeSummaryView.new(trainee_summary: trainee_summary)
            @navigation_view = ::Funding::NavigationView.new(organisation: organisation, system_admin: true)

            @start_year = current_academic_cycle.start_year
            @end_year = current_academic_cycle.end_year

            render("funding/trainee_summaries/show")
          end
          format.csv do
            send_data(data_export.csv, filename: data_export.filename, disposition: :attachment)
          end
        end
      end

    private

      def organisation
        @organisation ||= params[:provider_id].present? ? Provider.find(params[:provider_id]) : School.find(params[:lead_school_id])
      end

      def trainee_summary
        @trainee_summary ||= organisation.funding_trainee_summaries&.order(:created_at)&.last
      end

      def current_academic_cycle
        @current_academic_cycle ||= AcademicCycle.current
      end

      def data_export
        @data_export ||= Exports::FundingTraineeSummaryData.new(trainee_summary, organisation.name)
      end
    end
  end
end
