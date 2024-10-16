defmodule StormfulWeb.Keyboarder do
  use Phoenix.Component
  import StormfulWeb.CoreComponents

  attr :controlful, :boolean, required: true
  attr :keyboarder, :boolean, required: true

  def controlful_panel(assigns) do
    ~H"""
    <div
      inert
      class={[
        "fixed hidden flex-col lg:flex gap-2 lg:items-center w-full max-w-2xl top-0 bg-zinc-800/50 text-white px-8 py-0 text-xl z-[51] opacity-50",
        @controlful && "opacity-75",
        @keyboarder && "opacity-95 bg-inherit"
      ]}
      phx-window-keydown="keydown"
      phx-window-keyup="keyup"
    >
      <div>
        <p>
          <%= case {@controlful, @keyboarder} do %>
            <% {false, false} -> %>
              <p class="py-4">
                To activate Keyboarder, press CTRL twice!
              </p>
            <% {true, false} -> %>
              <p class="py-4">
                Press CTRL once more to activate Keyboarder!
              </p>
            <% {_, true} -> %>
              <div class="relative w-screen h-screen" inert>
                <div class="bg-indigo-900 absolute flex w-full h-full pt-8 flex-col items-center gap-4">
                  <p class="font-bold text-2xl underline">
                    Keyboarder is active!
                    Press ESC or CTRL to cancel Keyboarder
                  </p>
                  <div class="underline extrabold">
                    Current context related shortcuts <.icon name="hero-arrow-turn-right-down" />
                  </div>
                </div>
              </div>
            <% {nil, nil} -> %>
              To activate Keyboarder, press CTRL twice!
          <% end %>
        </p>
      </div>
    </div>
    """
  end

  attr :char, :string, required: true
  attr :keyboarder, :boolean, required: true

  def controlful_indicator_span(assigns) do
    ~H"""
    <span class={["hidden lg:block text-xs font-normal", @keyboarder && "animate-icondance text-lg"]}>
      (<%= @char %>)
    </span>
    """
  end

  attr :char, :string, required: true
  attr :name, :string, required: true
  attr :keyboarder, :boolean, required: true

  def controlful_indicator_powered_paragraph(assigns) do
    ~H"""
    <p class="flex flex-col items-center">
      <%= @name %><.controlful_indicator_span char={@char} keyboarder={@keyboarder} />
    </p>
    """
  end

  slot :inner_block, required: true
  slot :title, required: true

  def beautiful_section(assigns) do
    ~H"""
    <div class="p-2 border-2 border-black">
      <h4 class="text-lg underline font-bold mb-2 text-center">
        <%= render_slot(@title) %>
      </h4>

      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a button, in a pill style, as inactive.
                                                                                            
  ## Examples
                                                                                            
      <.inactive_pill_style_button>Send!</.inactive_pill_style_button>
      <.inactive_pill_style_buttonphx-click="go" class="ml-2">Send!</.inactive_pill_style_button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def inactive_pill_style_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-full bg-white hover:bg-zinc-400 py-2 px-3 border-zinc-500 border-2",
        "text-sm font-semibold leading-6 text-zinc-900 active:text-zinc-900/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a button, in a pill style, as active.
                                                                                            
  ## Examples
                                                                                            
      <.active_pill_style_button>Send!</.active_pill_style_button>
      <.active_pill_style_buttonphx-click="go" class="ml-2">Send!</.active_pill_style_button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def active_pill_style_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-full bg-zinc-900 hover:bg-zinc-400 py-2 px-3 border-zinc-400 border-2",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
