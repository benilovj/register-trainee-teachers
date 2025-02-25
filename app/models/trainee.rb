# frozen_string_literal: true

class Trainee < ApplicationRecord
  include Sluggable
  include PgSearch::Model
  include Discard::Model

  belongs_to :provider
  belongs_to :apply_application, optional: true

  belongs_to :dttp_trainee,
             foreign_key: :dttp_id,
             primary_key: :dttp_id,
             inverse_of: :trainee,
             optional: true,
             class_name: "Dttp::Trainee"

  belongs_to :hesa_student,
             foreign_key: :hesa_id,
             primary_key: :hesa_id,
             inverse_of: :trainee,
             optional: true,
             class_name: "Hesa::Student"

  belongs_to :lead_school, optional: true, class_name: "School"
  belongs_to :employing_school, optional: true, class_name: "School"
  belongs_to :course_allocation_subject, optional: true, class_name: "AllocationSubject"

  belongs_to :published_course,
             ->(trainee) { where(accredited_body_code: trainee.provider.code) },
             class_name: "Course",
             foreign_key: :course_uuid,
             primary_key: :uuid,
             inverse_of: :trainees,
             optional: true

  belongs_to :start_academic_cycle, optional: true, class_name: "AcademicCycle"
  belongs_to :end_academic_cycle, optional: true, class_name: "AcademicCycle"

  has_many :degrees, dependent: :destroy
  has_many :nationalisations, dependent: :destroy, inverse_of: :trainee
  has_many :nationalities, through: :nationalisations
  has_many :trainee_disabilities, dependent: :destroy, inverse_of: :trainee
  has_many :disabilities, through: :trainee_disabilities

  has_one :hesa_metadatum, class_name: "Hesa::Metadatum"

  attribute :progress, Progress.to_type

  delegate :award_type,
           :requires_placement_details?,
           :requires_schools?,
           :requires_employing_school?,
           :early_years_route?,
           :undergrad_route?,
           :requires_itt_start_date?,
           :requires_study_mode?,
           :requires_degree?,
           to: :training_route_manager

  delegate :update_training_route!, to: :route_data_manager

  validates :training_route, presence: {
    message: I18n.t("activerecord.errors.models.trainee.attributes.training_route"),
  }

  enum training_route: TRAINING_ROUTES

  enum training_initiative: ROUTE_INITIATIVES

  enum bursary_tier: BURSARY_TIERS

  enum locale_code: { uk: 0, non_uk: 1 }

  enum gender: {
    male: 0,
    female: 1,
    other: 2,
    gender_not_provided: 3,
  }

  enum commencement_status: COMMENCEMENT_STATUSES

  enum diversity_disclosure: {
    Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_disclosed] => 0,
    Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_not_disclosed] => 1,
  }

  enum disability_disclosure: {
    Diversities::DISABILITY_DISCLOSURE_ENUMS[:disabled] => 0,
    Diversities::DISABILITY_DISCLOSURE_ENUMS[:no_disability] => 1,
    Diversities::DISABILITY_DISCLOSURE_ENUMS[:not_provided] => 2,
  }

  enum ethnic_group: {
    Diversities::ETHNIC_GROUP_ENUMS[:asian] => 0,
    Diversities::ETHNIC_GROUP_ENUMS[:black] => 1,
    Diversities::ETHNIC_GROUP_ENUMS[:mixed] => 2,
    Diversities::ETHNIC_GROUP_ENUMS[:white] => 3,
    Diversities::ETHNIC_GROUP_ENUMS[:other] => 4,
    Diversities::ETHNIC_GROUP_ENUMS[:not_provided] => 5,
  }

  enum withdraw_reason: {
    WithdrawalReasons::UNKNOWN => 0,
    WithdrawalReasons::FOR_ANOTHER_REASON => 1,
    WithdrawalReasons::DEATH => 2,
    WithdrawalReasons::EXCLUSION => 3,
    WithdrawalReasons::FINANCIAL_REASONS => 4,
    WithdrawalReasons::GONE_INTO_EMPLOYMENT => 5,
    WithdrawalReasons::HEALTH_REASONS => 6,
    WithdrawalReasons::PERSONAL_REASONS => 7,
    WithdrawalReasons::TRANSFERRED_TO_ANOTHER_PROVIDER => 8,
    WithdrawalReasons::WRITTEN_OFF_AFTER_LAPSE_OF_TIME => 9,
    WithdrawalReasons::DID_NOT_PASS_ASSESSMENT => 10,
    WithdrawalReasons::DID_NOT_PASS_EXAMS => 11,
  }

  enum study_mode: TRAINEE_STUDY_MODE_ENUMS

  enum course_education_phase: {
    COURSE_EDUCATION_PHASE_ENUMS[:primary] => 0,
    COURSE_EDUCATION_PHASE_ENUMS[:secondary] => 1,
    COURSE_EDUCATION_PHASE_ENUMS[:early_years] => 2,
  }

  enum state: {
    draft: 0,
    submitted_for_trn: 1,
    trn_received: 2,
    recommended_for_award: 3,
    withdrawn: 4,
    deferred: 5,
    awarded: 6,
  } do
    event :submit_for_trn do
      before do
        self.submitted_for_trn_at = Time.zone.now
        apply_application&.update!(invalid_data: nil)
      end

      transition %i[draft deferred] => :submitted_for_trn
    end

    event :receive_trn do
      transition %i[submitted_for_trn deferred trn_received] => :trn_received
    end

    event :recommend_for_award do
      before do
        self.recommended_for_award_at = Time.zone.now
      end

      transition %i[trn_received] => :recommended_for_award
    end

    event :withdraw do
      transition %i[submitted_for_trn trn_received deferred] => :withdrawn
    end

    event :defer do
      transition %i[submitted_for_trn trn_received] => :deferred
    end

    event :award do
      before do
        raise StateTransitionError, "Cannot transition to :awarded without an awarded_at date" if awarded_at.blank?
      end

      transition %i[recommended_for_award] => :awarded
    end
  end

  COMPLETE_STATES = %w[recommended_for_award withdrawn awarded].freeze
  IN_TRAINING_STATES = %w[submitted_for_trn trn_received recommended_for_award].freeze

  pg_search_scope :with_name_trainee_id_or_trn_like,
                  against: %i[first_names middle_names last_name trainee_id trn],
                  using: { tsearch: { prefix: true } }

  scope :ordered_by_updated_at, -> { order(updated_at: :desc) }
  scope :ordered_by_last_name, -> { order(last_name: :asc) }

  # NOTE: Enforce subquery to remove duplications and allow for chain-ability.
  scope :with_subject_or_allocation_subject, (lambda do |subject|
    where(
      id: distinct.select("trainees.id")
        .joins(join_allocation_subjects_clause)
        .where("LOWER(course_subject_one) = :subject OR LOWER(course_subject_two) = :subject OR LOWER(course_subject_three) = :subject OR LOWER(allocation_subjects.name) = :subject", subject: subject.downcase),
    )
  end)

  scope :course_not_yet_started, -> { where("itt_start_date > ?", Time.zone.now).where.not(state: %i[draft deferred withdrawn]) }

  scope :in_training, -> { where(state: IN_TRAINING_STATES, itt_start_date: Date.new..Time.zone.now) }

  scope :with_award_states, (lambda do |*award_states|
    qts_states = award_states.select { |s| s.start_with?("qts") }.map { |s| genericize_state(s) }
    eyts_states = award_states.select { |s| s.start_with?("eyts") }.map { |s| genericize_state(s) }

    where(training_route: EARLY_YEARS_TRAINING_ROUTES.keys, state: eyts_states).or(
      where(state: qts_states).where.not(training_route: EARLY_YEARS_TRAINING_ROUTES.keys),
    )
  end)

  scope :with_manual_application, -> { where(apply_application: nil, created_from_dttp: false, hesa_id: nil) }
  scope :with_apply_application, -> { where.not(apply_application: nil) }
  scope :created_from_dttp, -> { where(created_from_dttp: true) }

  # We only look for the HESA ID to determine if a trainee record came from HESA.
  # Even though some records imported from DTTP will have a HESA ID, their original source is HESA so we chose this implementation
  scope :imported_from_hesa, -> { where.not(hesa_id: nil) }

  scope :complete_for_filter, -> { where(submission_ready: true).or(where(state: COMPLETE_STATES)).or(where(id: imported_from_hesa)) }
  scope :incomplete_for_filter, -> { where.not(id: complete_for_filter) }

  scope :on_early_years_routes, -> { where(training_route: EARLY_YEARS_TRAINING_ROUTES.keys) }

  audited associated_with: :provider
  has_associated_audits

  auto_strip_attributes(
    :first_names,
    :middle_names,
    :last_name,
    :address_line_one,
    :address_line_two,
    :town_city,
    :postcode,
    :email,
    :international_address,
    :ethnic_background,
    :additional_ethnic_background,
    :trn,
    :additional_withdraw_reason,
    :region,
    :hesa_id,
    :course_subject_one,
    :course_subject_two,
    :course_subject_three,
    :additional_withdraw_reason,
    squish: true,
    nullify: false,
  )

  before_save :clear_employing_school_id, if: :employing_school_not_applicable?
  before_save :clear_lead_school_id, if: :lead_school_not_applicable?
  before_save :set_submission_ready, if: :completion_trackable?

  def trn_requested!(dttp_id, placement_assignment_dttp_id)
    update!(dttp_id: dttp_id, placement_assignment_dttp_id: placement_assignment_dttp_id)
  end

  def trn_received!(new_trn = nil)
    raise(StateTransitionError, "Cannot transition to :trn_received without a trn") unless new_trn || trn

    # Skip deferred and withdrawn to avoid state change but to still register trn
    receive_trn! unless deferred? || withdrawn?

    # A deferred trainee will probably already have a trn - don't overwrite that!
    update!(trn: new_trn) unless trn
  end

  def award_qts!(awarded_at)
    self.awarded_at = awarded_at
    award!
  end

  def dttp_id=(value)
    raise(LockedAttributeError, "dttp_id update failed for trainee ID: #{id}, with value: #{value}") if dttp_id.present?

    super
  end

  def sha
    Digest::SHA1.hexdigest(value_digest)
  end

  def self.join_allocation_subjects_clause
    Arel.sql(<<~SQL)
      LEFT JOIN subject_specialisms AS specialism ON specialism.name = trainees.course_subject_one OR specialism.name = trainees.course_subject_two OR specialism.name = trainees.course_subject_three
      LEFT JOIN allocation_subjects ON specialism.allocation_subject_id = allocation_subjects.id
    SQL
  end

  def training_route_manager
    @training_route_manager ||= TrainingRouteManager.new(self)
  end

  def available_courses
    return provider.courses.order(:name) if apply_application?

    provider.courses.where(route: training_route).order(:name) if TRAINING_ROUTES_FOR_COURSE.keys.include?(training_route)
  end

  def clear_disabilities
    disabilities.clear
  end

  def apply_application?
    apply_application.present?
  end

  def course_age_range
    [course_min_age, course_max_age].compact
  end

  def course_age_range=(range)
    self.course_min_age, self.course_max_age = range
  end

  def course_subjects
    [course_subject_one, course_subject_two, course_subject_three].compact_blank
  end

  def route_data_manager
    @route_data_manager ||= RouteDataManager.new(trainee: self)
  end

  def self.genericize_state(state)
    if state.end_with?("awarded")
      "awarded"
    elsif state.end_with?("recommended")
      "recommended_for_award"
    else
      state
    end
  end

  def timeline
    Rails.cache.fetch([self, :timeline]) do
      Trainees::CreateTimeline.call(trainee: self)
    end
  end

  def set_early_years_course_details
    if early_years_route?
      course_subject = CourseSubjects::EARLY_YEARS_TEACHING
      self.course_subject_one = course_subject
      self.course_age_range = AgeRange::ZERO_TO_FIVE
      self.course_allocation_subject = SubjectSpecialism.find_by(name: course_subject)&.allocation_subject
      self.course_education_phase = COURSE_EDUCATION_PHASE_ENUMS[:early_years]
    end
  end

  def invalid_apply_data?
    apply_application&.invalid_data.present?
  end

  def hpitt_provider?
    @hpitt_provider ||= provider&.hpitt_postgrad?
  end

  def course_duration_in_years
    return unless itt_start_date && itt_end_date

    ((itt_end_date - itt_start_date) / 365).ceil
  end

  def starts_course_in_the_future?
    itt_start_date&.future?
  end

  def awaiting_action?
    !COMPLETE_STATES.include?(state)
  end

  def short_name
    [
      first_names,
      last_name,
    ].select(&:present?).join(" ").presence
  end

  def inactive?
    if state == "awarded"
      AcademicCycle.for_date(awarded_at) != AcademicCycle.for_date(Time.zone.now)
    else
      state == "withdrawn"
    end
  end

  def full_name
    [
      first_names,
      middle_names,
      last_name,
    ].select(&:present?).join(" ").presence
  end

  def duplicate?
    Trainee.where(first_names: first_names, last_name: last_name, date_of_birth: date_of_birth, email: email).count > 1
  end

  def hesa_record?
    hesa_id.present?
  end

  def record_source
    return "hesa" if hesa_record?

    return "apply" if apply_application?

    return "dttp" if  created_from_dttp?

    "manual"
  end

  def academic_cycle
    AcademicCycle.for_date(commencement_date || itt_start_date)
  end

private

  def value_digest
    # this returns a comma separated string of values from this object and it's associations
    # we use this to determine if we need to update DTTP. We use values only and exclude nils to avoid
    # sending updates when we add a field to the schema.

    exclude_list = %w[created_at updated_at dttp_update_sha progress submission_ready]

    trainee_values = serializable_hash.reject { |k, _v| exclude_list.include?(k) }.values.compact

    (
      trainee_values + [degrees, nationalities, disabilities].flat_map do |assoc|
        assoc.map(&:serializable_hash).flat_map(&:values).compact
      end
    ).join(",")
  end

  def clear_employing_school_id
    self.employing_school_id = nil
  end

  def clear_lead_school_id
    self.lead_school_id = nil
  end

  def completion_trackable?
    changed? && awaiting_action?
  end

  def set_submission_ready
    # Use the TRN validator when dealing with drafts trainees and if they're also an apply draft.
    # Before trn submission, when invalid_data on an apply application is cleared, the application is
    # updated but not the trainee. The trainee will be set to submitted_for_trn by the transition
    # callbacks but theoritically still a draft as it hasn't been saved so we need to check for this.
    draft_or_just_changed_from_draft = draft? || (state_changed? && state_was == "draft")
    draft_and_apply = draft_or_just_changed_from_draft && apply_application?

    validate_trn = draft_and_apply || draft?

    submission_klass = validate_trn ? Submissions::TrnValidator : Submissions::MissingDataValidator
    self.submission_ready = submission_klass.new(trainee: self).valid?
  end
end
