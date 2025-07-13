defmodule StormfulWeb.Layouts do
  use StormfulWeb, :html
  import StormfulWeb.MainAppHeader

  embed_templates "layouts/*"
end
