module Demo
  # Like bin/rails db:seed:replant, but keeps Solid Queue's tables: its processes shut down once their rows are gone.
  def self.reset!
    connection = ActiveRecord::Base.connection

    ActiveRecord::Base.transaction do
      connection.truncate_tables(*connection.tables.grep_v(/\Asolid_queue_/))
      Rails.application.load_seed
    end
  end
end
