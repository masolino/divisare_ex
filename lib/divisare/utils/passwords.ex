defmodule Divisare.Utils.Passwords do
  @moduledoc "Utils for passwords handling."

  @doc """
  Generates a new password hash compatible with Ruby's `devise` gem.
  """
  def hash_password(password) do
    Bcrypt.Base.hash_password(password, Bcrypt.Base.gen_salt(10, true))
  end

  @doc """
  Verifies a password hash compatible with Ruby's `devise` gem.
  """
  def verify_password(password, hash) do
    Bcrypt.verify_pass(password, hash)
  end

  @doc """
  Generates a new token. Not compatible with Ruby's `devise` gem.
  """
  def generate_random_token() do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.encode64()
    encrypted_token = digest_token(raw_token)

    {raw_token, encrypted_token}
  end

  @doc """
  Verifies a password reset token.
  """
  def digest_token(raw_token) do
    secret_key = Application.get_env(:divisare, DivisareWeb.Endpoint)[:secret_key_base]

    :crypto.mac(:hmac, :sha256, secret_key, raw_token)
    |> Base.encode16()
    |> String.downcase()
  end
end
