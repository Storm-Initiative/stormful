defmodule StormfulWeb.BaseUtil.KeyboardSupport do
  use StormfulWeb, :live_view

  defmacro __using__(_opts) do
    quote do
      # def handle_event("keydown", _, socket) do
      #   {:noreply, socket}
      # end
    end
  end
end
