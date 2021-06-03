# frozen_string_literal: true

module TraineeStatusCard
  class View < GovukComponent::Base
    attr_reader :state, :count, :target

    STATUS_COLOURS = {
      draft: "grey",
      submitted_for_trn: "turquoise",
      trn_received: "blue",
      recommended_for_award: "purple",
      awarded: "",
      deferred: "yellow",
      withdrawn: "red",
    }.freeze

    def initialize(state:, count:, target:)
      @state = state
      @target = target
      @count = count
    end

    def state_name
      I18n.t("activerecord.attributes.trainee.states.#{state}")
    end

    def status_colour
      STATUS_COLOURS[state.to_sym]
    end
  end
end
