defmodule StormfulWeb.JournalHeader do
  @moduledoc false

  use Phoenix.LiveComponent
  import StormfulWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between gap-3 sm:gap-4">
      <%!-- Journal title, mobile-first responsive design --%>
      <.cool_header big_name={@journal.title} />

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
    """
  end
end
