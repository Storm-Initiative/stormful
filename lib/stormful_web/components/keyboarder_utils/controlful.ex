defmodule StormfulWeb.BaseUtil.Controlful do
  use StormfulWeb, :live_view

  defmacro __using__(_opts) do
    quote do
      defp assign_controlful(socket) do
        socket |> assign(:controlful, false) |> assign(:keyboarder, false)
      end

      defp controlfulness(socket) do
        case {socket.assigns.controlful, socket.assigns.keyboarder} do
          {true, false} ->
            socket
            |> assign(:controlful, false)

          {false, false} ->
            assign(socket, :controlful, true)

          {_, true} ->
            assign(socket, :keyboarder, false)
        end
      end

      defp escape_controlful_and_keyboarder(socket) do
        socket |> assign(:keyboarder, false) |> assign(:controlful, false)
      end

      defp activate_keyboarder_for_real(socket) do
        if socket.assigns.controlful == true do
          socket
          |> assign(:keyboarder, true)
          |> assign(:controlful, false)
          |> push_event("focus-keyboarder", %{})
        else
          socket
        end
      end

      # def handle_event("keyup", %{"key" => "Control"}, socket) do
      #   {:noreply, socket |> controlfulness}
      # end

      # def handle_event("keyup", %{"key" => "Tab"}, socket) do
      #   {:noreply, socket |> activate_keyboarder_for_real}
      # end

      # def handle_event("keyup", %{"key" => "Escape"}, socket) do
      #   {:noreply, socket |> escape_controlful_and_keyboarder}
      # end

      # def handle_event("keyup", _, socket) do
      #   {:noreply, socket |> escape_controlful_and_keyboarder}
      # end
    end
  end
end
