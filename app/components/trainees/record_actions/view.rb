# frozen_string_literal: true

module Trainees
  module RecordActions
    class View < GovukComponent::Base
      attr_reader :trainee

      def initialize(trainee)
        @trainee = trainee
      end
    end
  end
end
