defmodule Stormful.Repo do
  use Ecto.Repo,
    otp_app: :stormful,
    adapter: Ecto.Adapters.Postgres
end
