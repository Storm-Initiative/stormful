defmodule StormfulWeb.Boards.FormLive do
  use StormfulWeb, :live_component
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div>
      Create a board
    </div>
    """
  end
end
