defmodule CotoamiWeb.CotonomaView do
  use CotoamiWeb, :view
  alias CotoamiWeb.{CotonomaView, CotoView, AmishiView}

  def render("index.json", %{global: global_cotonomas, recent: recent_cotonomas}) do
    %{
      global: render_many(global_cotonomas, __MODULE__, "cotonoma_holder.json"),
      recent: render_many(recent_cotonomas, __MODULE__, "cotonoma_holder.json")
    }
  end

  def render("super_and_sub.json", %{super: super_cotonomas, sub: sub_cotonomas}) do
    %{
      super: render_many(super_cotonomas, __MODULE__, "cotonoma_holder.json"),
      sub: render_many(sub_cotonomas, __MODULE__, "cotonoma_holder.json")
    }
  end

  def render("cotonomas.json", %{cotonomas: cotonomas}) do
    render_many(cotonomas, __MODULE__, "cotonoma.json")
  end

  def render("cotonoma_holders.json", %{cotonomas: cotonomas}) do
    render_many(cotonomas, __MODULE__, "cotonoma_holder.json")
  end

  def render("cotonoma_holder.json", %{cotonoma: cotonoma}) do
    posted_in =
      case cotonoma.coto do
        nil -> nil
        %Ecto.Association.NotLoaded{} -> nil
        coto -> render_relation(coto.posted_in, CotonomaView, "cotonoma.json")
      end

    reposted_in = Map.get(cotonoma, :reposted_in, [])

    %{
      cotonoma: render_one(cotonoma, __MODULE__, "cotonoma.json"),
      posted_in: posted_in,
      reposted_in: render_relations(reposted_in, CotonomaView, "cotonoma.json")
    }
  end

  def render("cotonoma.json", %{cotonoma: cotonoma}) do
    %{
      id: cotonoma.id,
      key: cotonoma.key,
      name: cotonoma.name,
      shared: cotonoma.shared,
      pinned: cotonoma.pinned,
      timeline_revision: cotonoma.timeline_revision,
      graph_revision: cotonoma.graph_revision,
      coto_id: cotonoma.coto_id,
      owner: render_relation(cotonoma.owner, AmishiView, "amishi.json"),
      inserted_at: cotonoma.inserted_at |> to_unixtime(),
      updated_at: cotonoma.updated_at |> to_unixtime(),
      last_post_timestamp: cotonoma.last_post_timestamp |> to_unixtime()
    }
  end

  def render("export.json", %{cotonoma: cotonoma}) do
    %{
      id: cotonoma.id,
      key: cotonoma.key,
      name: cotonoma.name,
      shared: cotonoma.shared,
      pinned: cotonoma.pinned,
      timeline_revision: cotonoma.timeline_revision,
      graph_revision: cotonoma.graph_revision,
      inserted_at: cotonoma.inserted_at |> to_unixtime(),
      updated_at: cotonoma.updated_at |> to_unixtime(),
      last_post_timestamp: cotonoma.last_post_timestamp |> to_unixtime()
    }
  end

  def render("cotos.json", %{cotonoma: cotonoma} = paginated_cotos) do
    %{
      cotonoma: render_one(cotonoma, __MODULE__, "cotonoma_holder.json"),
      paginated_cotos: render(CotoView, "paginated_cotos.json", paginated_cotos)
    }
  end

  def render("random.json", %{cotos: cotos}) do
    render(CotoView, "cotos.json", cotos: cotos)
  end
end
