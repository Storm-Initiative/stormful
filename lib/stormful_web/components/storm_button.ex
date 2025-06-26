defmodule StormfulWeb.StormButton do
  use Phoenix.Component
  import StormfulWeb.CoreComponents

  @doc """
  Renders a storm-themed button with consistent styling and animations.
  
  ## Examples
  
      <.storm_button variant="primary" type="submit">
        Save Changes
      </.storm_button>
      
      <.storm_button variant="cta" icon="hero-bolt">
        We strike, once more!
      </.storm_button>
      
      <.storm_button variant="secondary" href="/back">
        Go Back
      </.storm_button>
  """

  attr :variant, :string, default: "primary", values: ~w(primary secondary cta)
  attr :type, :string, default: nil
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :icon, :string, default: nil
  attr :icon_position, :string, default: "left", values: ~w(left right)
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def storm_button(assigns) do
    assigns = assign_variant_classes(assigns)

    ~H"""
    <%= if @href || @navigate do %>
      <.link href={@href} navigate={@navigate} class={["group relative", @class]}>
        <.button_content {assigns} />
      </.link>
    <% else %>
      <button type={@type} class={["group relative", @class]} {@rest}>
        <.button_content {assigns} />
      </button>
    <% end %>
    """
  end

  defp button_content(assigns) do
    ~H"""
    <div class={[
      "relative overflow-hidden rounded-xl font-bold transition-all duration-300 ease-out",
      "hover:-translate-y-1",
      @size_classes,
      @bg_classes,
      @border_classes,
      @shadow_classes,
      @text_classes
    ]}>
      <!-- Subtle shine effect -->
      <div class={[
        "absolute inset-0 bg-gradient-to-r from-transparent to-transparent",
        "-translate-x-full group-hover:translate-x-full transition-transform duration-700",
        @shine_classes
      ]}>
      </div>
      
      <div class="relative flex items-center justify-center gap-3">
        <%= if @icon && @icon_position == "left" do %>
          <.icon name={@icon} class={["transition-all duration-300", @icon_classes]} />
        <% end %>
        
        <span class={["transition-colors duration-300", @span_classes]}>
          <%= render_slot(@inner_block) %>
        </span>
        
        <%= if @icon && @icon_position == "right" do %>
          <.icon name={@icon} class={["transition-all duration-300", @icon_classes]} />
        <% end %>
      </div>
    </div>
    """
  end

  defp assign_variant_classes(%{variant: "cta"} = assigns) do
    assigns
    |> assign(
      size_classes: "px-8 py-4 text-xl",
      bg_classes: "bg-gradient-to-r from-yellow-600/80 to-orange-600/80 hover:from-yellow-500/90 hover:to-orange-500/90",
      border_classes: "border border-yellow-400/30 hover:border-yellow-300/50",
      shadow_classes: "hover:shadow-[0_10px_30px_rgba(251,191,36,0.3)]",
      text_classes: "text-white/90",
      shine_classes: "via-white/10",
      icon_classes: "w-6 h-6 text-yellow-200 group-hover:text-white group-hover:translate-x-1",
      span_classes: "group-hover:text-white"
    )
  end

  defp assign_variant_classes(%{variant: "primary"} = assigns) do
    assigns
    |> assign(
      size_classes: "px-6 py-3 text-base",
      bg_classes: "bg-gradient-to-r from-indigo-600/80 to-blue-600/80 hover:from-indigo-500/90 hover:to-blue-500/90",
      border_classes: "border border-indigo-400/30 hover:border-indigo-300/50",
      shadow_classes: "hover:shadow-[0_8px_25px_rgba(99,102,241,0.3)]",
      text_classes: "text-white/90",
      shine_classes: "via-white/8",
      icon_classes: "w-5 h-5 text-indigo-200 group-hover:text-white",
      span_classes: "group-hover:text-white"
    )
  end

  defp assign_variant_classes(%{variant: "secondary"} = assigns) do
    assigns
    |> assign(
      size_classes: "px-4 py-2 text-sm",
      bg_classes: "bg-gradient-to-r from-slate-600/60 to-slate-700/60 hover:from-slate-500/70 hover:to-slate-600/70",
      border_classes: "border border-slate-400/20 hover:border-slate-300/30",
      shadow_classes: "hover:shadow-[0_6px_20px_rgba(71,85,105,0.2)]",
      text_classes: "text-white/80",
      shine_classes: "via-white/6",
      icon_classes: "w-4 h-4 text-slate-300 group-hover:text-white",
      span_classes: "group-hover:text-white"
    )
  end
end