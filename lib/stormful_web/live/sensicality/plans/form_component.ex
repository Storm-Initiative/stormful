defmodule StormfulWeb.Sensicality.Plans.FormComponent do
  alias Stormful.Planning.Plan
  alias Stormful.Planning

  use StormfulWeb, :live_component

  def mount(socket) do
    {:ok, socket |> assign_plan_form(Planning.change_plan(%Plan{}))}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:current_user, assigns.current_user)
     |> assign(sensical_id: assigns.sensical_id)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="flex justify-center items-center text-xl font-bold p-2">
        Shut up everyone, here's the new plan&nbsp;&nbsp;<.icon name="hero-map" />
      </h3>

      <.form for={@plan_form} phx-submit="create-plan" phx-change="change-plan" phx-target={@myself}>
        <.input type="message_area" field={@plan_form[:title]} label="Title" />
        <div class="flex w-full justify-center">
          <.button class="mt-4 px-6 bg-indigo-700">Seems good to me[enter]</.button>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("change-plan", %{"plan" => %{"title" => title}}, socket) do
    socket = socket |> assign_plan_form(Planning.change_plan(%Plan{title: title}))

    {:noreply, socket}
  end

  def handle_event("create-plan", %{"plan" => %{"title" => title}}, socket) do
    # one last time to update the sensical <3
    plan = %{
      title: title,
      sensical_id: socket.assigns.sensical_id,
      user_id: socket.assigns.current_user.id
    }

    socket =
      case Planning.create_plan(plan) do
        {:ok, plan} ->
          notify_parent({:plan_created, plan})

          push_patch(socket, to: ~p"/sensicality/#{socket.assigns.sensical_id}")
          |> put_flash(:info, "Created successfully ⚡")

        {:error, changeset} ->
          socket |> assign(:plan_form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def assign_plan_form(socket, changeset) do
    socket |> assign(:plan_form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
