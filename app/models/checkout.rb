# Books a trial class for a child, saving a new parent or child in the same transaction.
class Checkout
  include ActiveModel::Model

  attr_accessor :trial_class, :parent_name, :parent_email, :student_id, :student_name
  attr_writer :parent
  attr_reader :booking

  validate :one_child_chosen
  validate :parent_and_student_valid

  def parent
    @parent ||= Parent.new(name: parent_name, email: parent_email)
  end

  def student
    @student ||= student_id.present? ? parent.students.find_by(id: student_id) : Student.new(parent:, name: student_name)
  end

  # Children the parent can pick from; a new parent has none yet.
  def existing_students
    parent.students.order(:name)
  end

  def save
    return false if invalid?

    ActiveRecord::Base.transaction do
      parent.save!
      student.save!
      @booking = Booking.hold_seat!(trial_class:, student:)
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    error.record.errors.full_messages.each { errors.add(:base, _1) }
    false
  end

  private
    def one_child_chosen
      if student_id.present? && student_name.present?
        errors.add(:base, "Choose one of your children or add a new one, not both")
      elsif student.nil?
        errors.add(:base, "Choose one of your children")
      end
    end

    def parent_and_student_valid
      [ parent, student ].compact.select(&:invalid?).each do |record|
        record.errors.full_messages.each { errors.add(:base, _1) }
      end
    end
end
