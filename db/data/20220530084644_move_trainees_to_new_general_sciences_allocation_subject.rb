# frozen_string_literal: true

class MoveTraineesToNewGeneralSciencesAllocationSubject < ActiveRecord::Migration[6.1]
  BIOLOGY_ALLOCATION_SUBJECT_ID = AllocationSubject.where(name: AllocationSubjects::BIOLOGY).id
  GENERAL_SCIENCES_ALLOCATION_SUBJECT_ID = AllocationSubject.where(name: AllocationSubjects::GENERAL_SCIENCES).id

  def up
    biology_trainees = Trainee.where(allocation_subject_id: BIOLOGY_ALLOCATION_SUBJECT_ID)

    biology_trainees.each do |trainee|
      if trainee.course_subject_one == "general sciences"
        trainee.update(course_allocation_subject_id: GENERAL_SCIENCES_ALLOCATION_SUBJECT_ID, applying_for_bursary: false)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
