defmodule Authentication.Guardian do
  use Guardian, otp_app: :authentication
  alias TicketAuthentications.Context.Users
  alias TicketAuthentications.Context.Sessions

  def subject_for_token(%{id: id}, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    sub = to_string(id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :no_id_provided}
  end

  def resource_from_claims(%{"sub" => id}) do
    # Here we'll look up our resource from the claims, the subject can be
    # found in the `"sub"` key. In above `subject_for_token/2` we returned
    # the resource id so here we'll rely on that to look it up.
    case Users.get_user_by_id(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :no_id_provided}
  end

  def authenticate(email, pwd) do
    claims = %{}
    options = [ttl: {1, :hour}]

    with {:ok, user_data} <- Users.get_user_by_email_pwd(email, pwd),
         {:ok, jwt, opt} <- encode_and_sign(user_data, claims, options),
         {:ok, _} <- Sessions.add_session(jwt, opt["exp"], user_data.id) do
      {:ok, jwt, opt}
    else
      _ -> {:error, "Failed to Login"}
    end
  end
end
