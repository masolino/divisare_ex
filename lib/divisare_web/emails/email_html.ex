defmodule DivisareWeb.EmailHTML do
  use DivisareWeb, :html

  embed_templates "./templates/*.html", suffix: "_html"
end
