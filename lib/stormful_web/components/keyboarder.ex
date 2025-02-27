defmodule StormfulWeb.Keyboarder do
  use Phoenix.Component
  import StormfulWeb.CoreComponents

  attr :controlful, :boolean, required: true
  attr :keyboarder, :boolean, required: true

  def controlful_panel(assigns) do
    ~H"""
    """
  end

  attr :char, :string, required: true
  attr :keyboarder, :boolean, required: true

  def controlful_indicator_span(assigns) do
    ~H"""
    <span class={["hidden lg:block text-xs font-normal", @keyboarder && "animate-icondance text-lg"]}>
      ({@char})
    </span>
    """
  end

  attr :char, :string, required: true
  attr :name, :string, required: true
  attr :keyboarder, :boolean, required: true

  def controlful_indicator_powered_paragraph(assigns) do
    ~H"""
    <p class="flex flex-col items-center">
      {@name}<.controlful_indicator_span char={@char} keyboarder={@keyboarder} />
    </p>
    """
  end

  slot :inner_block, required: true
  slot :title, required: true

  def beautiful_section(assigns) do
    ~H"""
    <div class="p-2 border-2 border-black">
      <h4 class="text-lg underline font-bold mb-2 text-center">
        {render_slot(@title)}
      </h4>

      {render_slot(@inner_block)}
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
      {render_slot(@inner_block)}
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
      {render_slot(@inner_block)}
    </button>
    """
  end
end
