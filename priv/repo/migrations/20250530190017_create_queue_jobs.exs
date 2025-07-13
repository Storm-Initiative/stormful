defmodule Stormful.Repo.Migrations.CreateQueueJobs do
  use Ecto.Migration

  def change do
    create table(:queue_jobs) do
      # "email", "ai_processing", etc.
      add :task_type, :string, null: false
      # "pending", "processing", "completed", "failed"
      add :status, :string, null: false, default: "pending"
      # JSON data for the task
      add :payload, :map, null: false
      # Future use for priority queues
      add :priority, :integer, default: 1
      # Number of retry attempts
      add :attempts, :integer, default: 0
      # Maximum retry attempts
      add :max_attempts, :integer, default: 3
      # When to run the job (for delayed jobs)
      add :scheduled_at, :utc_datetime
      # When processing started
      add :started_at, :utc_datetime
      # When job completed/failed
      add :completed_at, :utc_datetime
      # Error details for failed jobs
      add :error_message, :text
      # Optional user association
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    # Individual indexes
    create index(:queue_jobs, [:status])
    create index(:queue_jobs, [:task_type])
    create index(:queue_jobs, [:user_id])

    # Compound indexes for optimal query performance
    # Main job fetching query
    create index(:queue_jobs, [:status, :scheduled_at])
    # Rate limiting query
    create index(:queue_jobs, [:task_type, :status, :started_at])
    # Task-specific job fetching
    create index(:queue_jobs, [:task_type, :status, :scheduled_at])
  end
end
