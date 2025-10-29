defmodule StormfulWeb.SensicalCard do
  use Phoenix.Component
  import StormfulWeb.CoreComponents

  @doc """
  Renders a sensical card with consistent styling and animations.

  ## Examples

      <.sensical_card 
        title="My Sensical" 
        href="/sensicality/123" 
        variant="starred" 
      />
      
      <.sensical_card 
        title="Another Sensical" 
        href="/sensicality/456" 
        variant="regular" 
      />
  """

  attr :title, :string, required: true
  attr :href, :string, required: true
  attr :variant, :string, default: "regular", values: ~w(starred regular)
  attr :icon, :string, default: nil
  attr :class, :string, default: ""

  def sensical_card(assigns) do
    assigns = assign_variant_classes(assigns)

    ~H"""
    <.link
      navigate={@href}
      class={[
        "group relative overflow-hidden rounded-xl px-6 py-4",
        "transition-all duration-300 ease-out hover:-translate-y-1",
        @bg_classes,
        @border_classes,
        @shadow_classes,
        @class
      ]}
    >
      <!-- Subtle shine effect -->
      <div class={[
        "absolute inset-0 bg-gradient-to-r from-transparent to-transparent",
        "-translate-x-full group-hover:translate-x-full transition-transform duration-700",
        @shine_classes
      ]}>
      </div>

      <div class="relative flex items-center gap-3">
        <.icon
          name={@icon_name}
          class={[
            "w-5 h-5 transition-colors duration-300",
            @icon_classes
          ]}
        />
        <h3 class="text-lg font-semibold text-white/90 group-hover:text-white transition-colors duration-300">
          {@title}
        </h3>
      </div>
    </.link>
    """
  end

  defp assign_variant_classes(%{variant: "starred"} = assigns) do
    assigns
    |> assign(
      bg_classes:
        "bg-gradient-to-r from-yellow-600/20 to-orange-600/20 hover:from-yellow-500/30 hover:to-orange-500/30",
      border_classes: "border border-yellow-400/20 hover:border-yellow-300/40",
      shadow_classes: "hover:shadow-[0_8px_25px_rgba(251,191,36,0.2)]",
      shine_classes: "via-yellow-300/10",
      icon_name: assigns[:icon] || "hero-star",
      icon_classes: "text-yellow-300 group-hover:text-yellow-200"
    )
  end

  defp assign_variant_classes(%{variant: "regular"} = assigns) do
    assigns
    |> assign(
      bg_classes:
        "bg-gradient-to-r from-violet-600/20 to-rose-600/20 hover:from-violet-500/30 hover:to-rose-500/30",
      border_classes: "border border-violet-400/20 hover:border-violet-300/40",
      shadow_classes: "hover:shadow-[0_8px_25px_rgba(99,102,241,0.2)]",
      shine_classes: "via-blue-300/10",
      icon_name: assigns[:icon] || "hero-bolt",
      icon_classes: "text-blue-300 group-hover:text-blue-200"
    )
  end
end
