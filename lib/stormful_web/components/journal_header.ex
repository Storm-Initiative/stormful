defmodule StormfulWeb.JournalHeader do
  @moduledoc false

  use Phoenix.LiveComponent
  import StormfulWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div>
      <%!-- Greeting phrase at the top --%>
      <div
        :if={
          assigns[:profile] && @profile && @profile.greeting_phrase && @profile.greeting_phrase != ""
        }
        class="text-center mb-10 relative"
      >
        <div class="inline-flex items-center gap-3 px-6 py-3 rounded-2xl">
          <.icon name="hero-sparkles" class="w-6 h-6 text-yellow-500" />
          <span class="text-3xl font-bold bg-gradient-to-r from-orange-400 to-pink-400 bg-clip-text text-transparent tracking-wide">
            {@profile.greeting_phrase}
          </span>
        </div>
      </div>

      <div class="flex items-center justify-between gap-3 sm:gap-4">
        <%!-- Journal title, mobile-first responsive design --%>
        <%= if @journal do %>
          <.cool_header big_name={@journal.title} />
        <% end %>

        <%!-- Controls: action buttons --%>
        <div class="flex gap-2 sm:gap-3 justify-end">
          <div class="flex gap-2">
            <.button
              :if={@journal}
              phx-click="edit_current_journal"
              class="flex-shrink-0 bg-yellow-600 hover:bg-yellow-500"
              title="Edit journal title"
            >
              <.icon name="hero-pencil" class="w-4 h-4" />
              <span class="ml-1">Edit</span>
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
