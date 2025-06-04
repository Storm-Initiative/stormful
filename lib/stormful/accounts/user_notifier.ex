defmodule Stormful.Accounts.UserNotifier do
  @moduledoc """
  Handles sending user-related emails with support for background processing and scheduling.

  This module now supports:
  - Immediate email delivery (using `deliver/3`)
  - Background email processing (using `deliver_via_queue/4`)
  - Scheduled email delivery (using `deliver_via_queue/4` with `delay_minutes` option)

  ## Examples

      # Send immediately
      deliver_immediately("user@example.com", "Subject", "Body")

      # Send via background queue
      deliver_via_queue("user@example.com", "Subject", "Body", user_id: 123)

      # Schedule for later
      deliver_via_queue("user@example.com", "Subject", "Body", user_id: 123, delay_minutes: 30)

      # Or use the convenience function
      deliver_scheduled_email("user@example.com", "Subject", "Body", 30, user_id: 123)
  """
  import Swoosh.Email

  alias Stormful.Mailer
  alias Stormful.Queue

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Stormful", StormfulWeb.Endpoint.config(:email_from)})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  # Queues the email for background delivery using our queue system.
  # Now supports scheduling emails to be sent later!
  defp deliver_via_queue(recipient, subject, body, opts \\ []) do
    email_payload = %{
      "to" => recipient,
      "subject" => subject,
      "body" => body,
      "from" => "Stormful <#{StormfulWeb.Endpoint.config(:email_from)}>",
      "template" => nil,
      "html_body" => ""
    }

    # Handle delay_minutes option for scheduling
    queue_opts = case Keyword.get(opts, :delay_minutes) do
      nil ->
        # No delay, send immediately (use existing opts without delay_minutes)
        Keyword.delete(opts, :delay_minutes)

      minutes when is_integer(minutes) and minutes > 0 ->
        scheduled_at = DateTime.add(DateTime.utc_now(), minutes * 60, :second)
        opts
        |> Keyword.delete(:delay_minutes)
        |> Keyword.put(:scheduled_at, scheduled_at)

      _ ->
        # Invalid delay_minutes, send immediately
        Keyword.delete(opts, :delay_minutes)
    end

    case Queue.enqueue_email(email_payload, queue_opts) do
      {:ok, job} ->
        delay_info = case Keyword.get(opts, :delay_minutes) do
          nil -> "immediately"
          minutes -> "in #{minutes} minutes"
        end

        {:ok, %{
          job_id: job.id,
          recipient: recipient,
          subject: subject,
          scheduled_for: delay_info,
          scheduled_at: Keyword.get(queue_opts, :scheduled_at)
        }}

      {:error, changeset} ->
        # Fallback to direct delivery if queue fails
        deliver(recipient, subject, body)
    end
  end

  @doc """
  Deliver instructions to confirm account.
  Now uses background processing for better user experience!
  """
  def deliver_confirmation_instructions(user, url) do
    body = """

    ==============================

    Hey there #{user.email}!!

    So glad to have you on board!

    Welcome to Stormful! Let's dive Into the Storm! 🌩️

    Yea, well; firstly please confirm your account by visiting the URL below:

    #{url}

    If you did not create this account, please ignore this. But please beware that someone is trying to impersonate you!

    If you have any questions, don't hesitate to reach out, right from the email that sent you this message!

    ==============================
    """

    deliver_via_queue(
      user.email,
      "Confirmation instructions",
      body,
      user_id: user.id
    )
  end

  @doc """
  Deliver instructions to reset a user password.
  Now uses background processing for better user experience!
  """
  def deliver_reset_password_instructions(user, url) do
    body = """

    ==============================

    Salutations, #{user.email}!

    Click the link below to reset that old password of yours in a flash:

    #{url}

    If you did not request this change, please ignore this. But please beware that someone is trying to impersonate you!

    If you have any questions, don't hesitate to reach out, right from the email that sent you this message!

    ==============================
    """

    deliver_via_queue(
      user.email,
      "Reset password instructions",
      body,
      user_id: user.id
    )
  end

  @doc """
  Deliver instructions to update a user email.
  Now uses background processing for better user experience!
  """
  def deliver_update_email_instructions(user, url) do
    body = """

    ==============================

    Hey there #{user.email}!

    Use the link below to change your email, and get back to the Storm:

    #{url}

    If you did not request this change, please ignore this. But please beware that someone is trying to impersonate you!

    If you have any questions, don't hesitate to reach out, right from the email that sent you this message!

    ==============================
    """

    deliver_via_queue(
      user.email,
      "Update email instructions",
      body,
      user_id: user.id
    )
  end

  @doc """
  Send a welcome email to new users.
  Uses our queue system with a 5-minute delay for better user experience!
  """
  def deliver_welcome_email(user) do
    body = """

    ==============================

    So, let's begin, #{user.email}!

    First of all, we'd like to say this from the bottom of our hearts:

    Welcome to Stormful! 🎉

    If you have any questions, don't hesitate to reach out!

    Best regards,
    Storm Initiative

    ==============================
    """

    deliver_scheduled_email(
      user.email,
      "Welcome to Stormful! 🎉",
      body,
      5,
      user_id: user.id
    )
  end

  @doc """
  For backwards compatibility or urgent emails that need immediate delivery.
  """
  def deliver_immediately(recipient, subject, body) do
    deliver(recipient, subject, body)
  end

  @doc """
  Convenience function to schedule an email for delivery after a specified delay.

  ## Parameters
  - `recipient` - Email address to send to
  - `subject` - Email subject line
  - `body` - Email body content
  - `delay_minutes` - Number of minutes to wait before sending
  - `opts` - Additional options (e.g., user_id)

  ## Examples

      # Send welcome email in 5 minutes
      deliver_scheduled_email(user.email, "Welcome!", body, 5, user_id: user.id)

      # Send reminder email in 24 hours (1440 minutes)
      deliver_scheduled_email(user.email, "Reminder", body, 1440, user_id: user.id)
  """
  def deliver_scheduled_email(recipient, subject, body, delay_minutes, opts \\ []) do
    all_opts = Keyword.put(opts, :delay_minutes, delay_minutes)
    deliver_via_queue(recipient, subject, body, all_opts)
  end

  @doc """
  Get the status of a queued email job.
  """
  def get_email_status(job_id) do
    case Queue.get_job(job_id) do
      nil -> {:error, :not_found}
      job -> {:ok, %{status: job.status, attempts: job.attempts, error: job.error_message}}
    end
  end
end
