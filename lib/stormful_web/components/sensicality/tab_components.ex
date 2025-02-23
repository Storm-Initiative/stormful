defmodule StormfulWeb.SensicalityComponents.TabComponents do
  use Phoenix.Component
  import StormfulWeb.CoreComponents

  attr :current_tab, :string, required: true
  attr :current_action, :atom, required: true

  attr :tabs, :list,
    default: [
      %{
        id: "thoughts",
        icon: "hero-chat-bubble-oval-left",
        from_gradient: "from-purple-400",
        to_gradient: "to-pink-400"
      },
      %{
        id: "todos",
        icon: "hero-check-circle",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      },
      %{
        id: "heads-ups",
        icon: "hero-exclamation-circle",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      },
      %{
        id: "ai-related",
        icon: "hero-bolt",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      },
      %{
        id: "resources",
        icon: "hero-building-storefront",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      },
      %{
        id: "archive",
        icon: "hero-archive-box",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      },
      %{
        id: "command-center",
        icon: "hero-command-line",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      },
      %{
        id: "statistics",
        icon: "hero-chart-bar",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      },
      %{
        id: "settings",
        icon: "hero-cog",
        from_gradient: "from-cyan-400",
        to_gradient: "to-blue-400"
      }
    ]

  def sensicality_tab_bar(assigns) do
    ~H"""
    <div class="fixed left-0 top-0 h-screen w-16 bg-slate-800/90 backdrop-blur-lg z-[2] hover:w-20 transition-all duration-300 ease-out-expo group border-r border-white/5">
      <div class="h-full flex flex-col items-center py-10 space-y-4 overflow-y-auto">
        <!-- Go-to-top button -->
        <div
          class="mb-4 p-2 rounded-lg hover:bg-white/5 cursor-pointer transition-all"
          title="Scroll to top"
          phx-hook="SensicalityGeneralScroller"
          id="sensicality-top-scroller"
        >
          <.icon
            name="hero-chevron-double-up"
            class="h-8 w-8 text-white/80 hover:text-white hover:scale-110 transition-transform"
          />
        </div>
        
    <!-- Tab buttons -->
        <%= for tab <- @tabs do %>
          <.sensicality_tab_button tab={tab} current_tab={@current_tab} />
        <% end %>
      </div>
    </div>
    """
  end

  defp sensicality_tab_button(assigns) do
    ~H"""
    <button
      class="relative w-full px-2 py-3 group"
      phx-click="select_tab"
      phx-value-tab={@tab.id}
      title={String.replace(@tab.id, "_", " ") |> String.capitalize()}
    >
      <div class={[
        "absolute inset-0 -z-10 rounded-r-lg opacity-0 transition-all",
        "group-hover:opacity-20",
        if @current_tab == @tab.id do
          "#{@tab.from_gradient} #{@tab.to_gradient} opacity-40"
        else
          "bg-gray-400"
        end
      ]}>
      </div>

      <div class={[
        "absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 rounded-r-full transition-all",
        if @current_tab == @tab.id do
          "#{@tab.from_gradient} #{@tab.to_gradient} opacity-100 scale-y-100"
        else
          "opacity-0 scale-y-50 group-hover:opacity-40 group-hover:scale-y-75"
        end
      ]}>
      </div>

      <.icon
        name={@tab.icon}
        class={[
          "h-6 w-6 mx-auto transition-all duration-300 ease-out-back",
          if @current_tab == @tab.id do
            "text-white scale-125 drop-shadow-lg group-hover:scale-150"
          else
            "text-white/60 group-hover:text-white/90 group-hover:scale-110"
          end
        ]}
      />
    </button>
    """
  end
end
