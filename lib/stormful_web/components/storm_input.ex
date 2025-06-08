defmodule StormfulWeb.StormInput do
  @moduledoc false

  use Phoenix.LiveComponent
  import StormfulWeb.CoreComponents
  alias Stormful.Attention
  alias Stormful.TaskManagement
  alias Stormful.FlowingThoughts
  alias Stormful.FlowingThoughts.Wind
  alias Stormful.AiRelated.ThoughtExtractionHelper

  require Logger

  def render(assigns) do
    ~H"""
    <div class="bg-indigo-900 p-4 text-xl m-4">
      <div class="max-w-7xl mx-auto">
        <.form
          phx-target={@myself}
          for={@wind_form}
          phx-submit="save"
          phx-change="change_wind"
          class="flex flex-col gap-4 items-center"
        >
          <div class="flex-grow w-full text-2xl">
            <.input
              type="message_area"
              field={@wind_form[:words]}
              placeholder="write your thoughts here"
              label="The Storm Input"
              label_centered={true}
            />
          </div>
          <.button
            type="submit"
            class="px-6 py-3 bg-indigo-500 hover:bg-indigo-400 text-white font-semibold
                   rounded-lg transition-colors flex items-center gap-2"
          >
            <span>⚡</span>
            <span>Enter</span>
          </.button>
        </.form>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign_clear_wind_form()}
  end

  def handle_event("change_wind", %{"wind" => %{"words" => words}}, socket) do
    {:noreply, socket |> assign_wind_form(FlowingThoughts.change_wind(%Wind{words: words}))}
  end

  def handle_event(
        "save",
        %{"wind" => %{"words" => words}},
        socket
      ) do
    sensical = socket.assigns.sensical

    first_of_words = String.first(words)

    case first_of_words do
      "?" ->
        [_head | tail] = String.split(words, "", trim: true)
        meaty_part = tail |> Enum.join("")

        case TaskManagement.create_todo_for_sensicals_preferred_plan(
               socket.assigns.current_user.id,
               sensical.id,
               meaty_part
             ) do
          {:ok, _todo} ->
            {:noreply, socket |> assign_clear_wind_form()}

          {:error, changeset} ->
            {:noreply, socket |> assign_wind_form(changeset)}
        end

      "!" ->
        [_head | tail] = String.split(words, "", trim: true)
        meaty_part = tail |> Enum.join("")

        case Attention.create_headsup(
               socket.assigns.current_user.id,
               sensical.id,
               meaty_part
             ) do
          {:ok, _headsup} ->
            {:noreply, socket |> assign_clear_wind_form()}

          {:error, changeset} ->
            {:noreply, socket |> assign_wind_form(changeset)}
        end

      _ ->
        case FlowingThoughts.create_wind(%{
               sensical_id: sensical.id,
               words: words,
               user_id: socket.assigns.current_user.id
             }) do
          {:ok, wind} ->
            # Queue a light AI task to analyze the thought
            queue_ai_analysis_for_thought(wind, socket.assigns.current_user)

            {:noreply, socket |> assign_clear_wind_form()}

          {:error, changeset} ->
            {:noreply, socket |> assign_wind_form(changeset)}
        end
    end
  end

  defp assign_wind_form(socket, changeset) do
    socket
    |> assign(:wind_form, to_form(changeset))
  end

  defp assign_clear_wind_form(socket) do
    socket |> assign_wind_form(FlowingThoughts.change_wind(%Wind{}))
  end

  defp queue_ai_analysis_for_thought(wind, user) do
    # Create a prompt to analyze the user's thought
    prompt = """
    The JSON structure should be:

    {
      "type": "reminder",
      "what": "the reminder that needs to be done/set-up",
      "when": "a string for the reminder, can be relative or absolute with annotations, like relative:day:+1, absolute:2025-06-08 12:00"
      "the_time_of_the_day_if_day": "the time of the day if the system provides days"
      "location": "the location if the user provides it"
    }

    User generally tells when they need something done by a specific time. We extract date/time in a unique way:
    - User says tomorrow -> relative:day:+1
    - User says in 2 hours -> relative:minute:+120
    - User says in 2 days -> relative:day:+2
    - User says in 2 weeks -> relative:week:+2
    - User says in 2 months -> relative:month:+2
    - User says in 2 years -> relative:year:+2
    - User says in 2 hours -> relative:minute:+120
    - User says in 2 days -> relative:day:+2
    - User says 2025-06-08 -> absolute:2025-06-08
    - User says 2025-06-08 12:00 -> absolute:2025-06-08 12:00
    - User says 2025-06-08 12:00:00 -> absolute:2025-06-08 12:00:00
    - User says 2025-06-08 12:00:00.000 -> absolute:2025-06-08 12:00:00.000
    - User says 2025-06-08 12:00:00.000+03:00 -> absolute:2025-06-08 12:00:00.000
    - User says 2025-06-08 12:00:00.000+03:00 -> absolute:2025-06-08 12:00:00.000

    Beware: if user provides absolute, they might mean in mm/dd/yyyy format, but we need yyyy-mm-dd format. If you ever get confused, leave the field empty:
    - User says 06/08/2025 -> confused_ask:2025-06-08
    - User says 06/08/2025 12:00 -> confused_ask:2025-06-08 12:00
    - User says 06/08/2025 12:00:00 -> confused_ask:2025-06-08 12:00:00
    - User says 06/08/2025 12:00:00.000 -> confused_ask:2025-06-08 12:00:00.000
    - User says 06/08/2025 12:00:00.000+03:00 -> confused_ask:2025-06-08 12:00:00.000
    - User says 06/08/2025 12:00:00.000+03:00 -> confused_ask:2025-06-08 12:00:00.000

    Program will take care of that afterwards, don't worry about it.

    You also might want to provide the_time_of_the_day_if_day, which is the time of the day if the user says a day. You may go logical here, if undecided, leave it null. Should always provide in 24-hour format. But yeah, if user says:
    - I got to go to school tomorrow -> the_time_of_the_day_if_day: 09:00
    - I got to go to school in 2 hours -> the_time_of_the_day_if_day: null
    - I will take a good looking person to dinner tomorrow -> the_time_of_the_day_if_day: 18:00

    User may specify the location too, location is optional, if not provided or not clear, leave it null.
    - I got to go to the dentist tomorrow -> location: null
    - dentist appointment tomorrow at Stonefruit Bakery -> location: "Stonefruit Bakery"

    For example, if the user says "I got to go to the dentist tomorrow", and user timezone is UTC+0, you should respond with:
    {
      "type": "reminder",
      "what": "Go to the dentist",
      "when": "relative:day:+1"
      "the_time_of_the_day_if_day": "09:00"
      "location": null
    }

    Or when user says "I got a dentist appointment in 2 hours at Stonefruit Bakery", and user timezone is UTC+0, you should respond with:
    {
      "type": "reminder",
      "what": "Go to the dentist",
      "when": "relative:minute:+120"
      "the_time_of_the_day_if_day": null
      "location": "Stonefruit Bakery"
    }


    Please try to respond in the language of the user.

    If user provides a data that is not a reminder, you should respond with null.

    User will provide a thought, and you need to extract if it has a reminder that needs to be done/set-up. Please be mindful of the user's timezone. Also keep in mind about date/time related stuff as I mentioned above, you need to be extra careful with timezone, it is very important for our user's experience. Please only provide the JSON structure, no other text:

    "#{wind.words}"
    """

    # Queue the thought extraction task
    case ThoughtExtractionHelper.complete_async(
           "deepseek/deepseek-chat-v3-0324",
           prompt,
           max_tokens: 150,
           temperature: 0.7,
           user_id: user.id
         ) do
      {:ok, job} ->
        Logger.info(
          "📅 Queued thought extraction for '#{String.slice(wind.words, 0, 50)}...' - Job ID: #{job.id}"
        )

      # Calendar events are now automatically created when the AI detects reminders!
      # The thought extraction worker will:
      # 1. Process the AI response
      # 2. Parse it for calendar events (JSON format)
      # 3. Automatically send calendar invitations via email
      # 4. Log the results in the worker output

      {:error, reason} ->
        Logger.error("Failed to queue thought extraction: #{inspect(reason)}")
    end
  end
end
