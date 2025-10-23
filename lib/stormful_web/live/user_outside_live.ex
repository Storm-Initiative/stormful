defmodule StormfulWeb.UserOutsideLive do
  use StormfulWeb, :live_view

  import StormfulWeb.CoreComponents
  alias Stormful.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Outside Integrations
      <:subtitle>Manage API tokens for external services</:subtitle>
    </.header>

    <div class="max-w-4xl mx-auto">
      <!-- Settings Navigation -->
      <div class="bg-white/10 backdrop-blur-sm shadow rounded-lg mb-8">
        <div class="border-b border-white/20">
          <nav class="-mb-px flex space-x-8 px-6">
            <.link
              navigate={~p"/users/settings"}
              class="py-4 px-1 border-b-2 border-transparent font-medium text-sm text-white/70 hover:text-white hover:border-white/30 whitespace-nowrap"
            >
              Account Security
            </.link>
            <.link
              navigate={~p"/users/profile"}
              class="py-4 px-1 border-b-2 border-transparent font-medium text-sm text-white/70 hover:text-white hover:border-white/30 whitespace-nowrap"
            >
              Profile
              <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-400 text-yellow-900">
                Beta
              </span>
            </.link>
            <button
              type="button"
              class="py-4 px-1 border-b-2 font-medium text-sm whitespace-nowrap border-white text-white"
            >
              Outside
              <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-400 text-yellow-900">
                Beta
              </span>
            </button>
          </nav>
        </div>
      </div>
      
    <!-- Token Management -->
      <div class="space-y-6">
        <!-- Generate new token -->
        <div class="bg-white/10 backdrop-blur-sm shadow rounded-lg p-6">
          <h3 class="text-lg font-medium text-white mb-4">Generate New Token</h3>
          <p class="text-sm text-gray-300 mb-4">
            Tokens let you authenticate with external services. They are shown only once, so copy them immediately!
          </p>
          <button
            phx-click="generate_token"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
          >
            Generate Token
          </button>
          <%= if @new_token do %>
            <div class="mt-4 p-4 bg-gray-800 rounded-md">
              <p class="text-sm font-medium text-white mb-2">Your new token:</p>
              <code class="block bg-black/50 p-2 rounded text-sm font-mono break-all">
                {@new_token}
              </code>
              <p class="mt-2 text-xs text-yellow-400">
                Store this token safely. It won't be shown again.
              </p>
            </div>
          <% end %>
        </div>
        
    <!-- List tokens -->
        <div class="bg-white/10 backdrop-blur-sm shadow rounded-lg p-6">
          <h3 class="text-lg font-medium text-white mb-4">Your Tokens</h3>
          <%= if Enum.empty?(@tokens) do %>
            <p class="text-sm text-gray-400">You have no active tokens.</p>
          <% else %>
            <table class="min-w-full divide-y divide-gray-700">
              <thead class="bg-gray-50/5">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Created
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-700">
                <%= for token <- @tokens do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                      {token.inserted_at |> Calendar.strftime("%b %d, %Y %H:%M")}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm">
                      <button
                        phx-click="revoke_token"
                        phx-value-token-id={token.id}
                        class="text-red-400 hover:text-red-300"
                      >
                        Revoke
                      </button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    tokens = Accounts.list_user_api_tokens(user)

    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Stormful.PubSub, "user_api_tokens:#{user.id}")

    socket =
      socket
      |> assign(:tokens, tokens)
      |> assign(:new_token, nil)

    {:ok, socket}
  end

  def handle_info({:new_token}, socket) do
    # refetch all again
    tokens = Accounts.list_user_api_tokens(socket.assigns.current_user)
    {:noreply, assign(socket, tokens: tokens)}
  end

  def handle_event("generate_token", _params, socket) do
    user = socket.assigns.current_user
    new_token = Accounts.create_user_api_token(user)
    tokens = Accounts.list_user_api_tokens(user)
    {:noreply, assign(socket, tokens: tokens, new_token: new_token)}
  end

  def handle_event("revoke_token", %{"token-id" => token_id}, socket) do
    _ = Accounts.revoke_api_token(socket.assigns.current_user.id, token_id)
    tokens = Accounts.list_user_api_tokens(socket.assigns.current_user)
    {:noreply, assign(socket, tokens: tokens)}
  end
end
