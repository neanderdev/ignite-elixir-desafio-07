defmodule GithubWeb.UsersController do
  use GithubWeb, :controller

  alias Github.User
  alias GithubWeb.{Auth.Guardian, FallbackController}

  action_fallback FallbackController

  def create(conn, params) do
    with {:ok, %User{} = user} <- Github.create_user(params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user, %{}, ttl: {15, :seconds}) do
      conn
      |> put_status(:created)
      |> render("create.json", token: token, user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, %User{} = user} <- Github.get_user_by_id(id) do
      conn
      |> put_status(:ok)
      |> render("user.json", user: user)
    end
  end

  def sign_in(conn, params) do
    with {:ok, token} <- Guardian.authenticate(params) do
      conn
      |> put_status(:ok)
      |> render("sign_in.json", token: token)
    end
  end

  def index(conn, _params) do
    %Plug.Conn{
      private: %{
        guardian_default_token: token,
        guardian_default_claims: claims
      }
    } = conn

    with {:ok, users} <- Github.get_users(),
         {:ok, %{token: token, claims: _claims}} =
           GithubWeb.Auth.Guardian.refresh_token(token, claims) do
      conn
      |> put_status(:ok)
      |> render("list_users.json", users: users, token: token)
    end
  end
end
