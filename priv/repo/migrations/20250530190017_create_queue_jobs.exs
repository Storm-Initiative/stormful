defmodule Stormful.Repo.Migrations.CreateQueueJobs do
  use Ecto.Migration

  def change do
    create table(:queue_jobs) do
      add :task_type, :string, null: false # "email", "ai_processing", etc.
      add :status, :string, null: false, default: "pending" # "pending", "processing", "completed", "failed"
      add :payload, :map, null: false # JSON data for the task
      add :priority, :integer, default: 1 # Future use for priority queues
      add :attempts, :integer, default: 0 # Number of retry attempts
      add :max_attempts, :integer, default: 3 # Maximum retry attempts
      add :scheduled_at, :utc_datetime # When to run the job (for delayed jobs)
      add :started_at, :utc_datetime # When processing started
      add :completed_at, :utc_datetime # When job completed/failed
      add :error_message, :text # Error details for failed jobs
      add :user_id, references(:users, on_delete: :delete_all) # Optional user association

      timestamps()
    end

    # Individual indexes
    create index(:queue_jobs, [:status])
    create index(:queue_jobs, [:task_type])
    create index(:queue_jobs, [:user_id])

    # Compound indexes for optimal query performance
    create index(:queue_jobs, [:status, :scheduled_at])  # Main job fetching query
    create index(:queue_jobs, [:task_type, :status, :started_at])  # Rate limiting query
    create index(:queue_jobs, [:task_type, :status, :scheduled_at])  # Task-specific job fetching
  end
end
