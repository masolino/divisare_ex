defmodule DivisareWeb.Plugs.DeviseSession do
  import Plug.Conn
  require Logger

  @iterations 1000
  @key_size 64
  @cipher :aes_256_cbc
  @cookie_name "_divisare_com_session"

  def init(default), do: default

  def call(conn, _opts) do
    session_cookie = get_session_cookie(conn, @cookie_name)

    if session_cookie do
      Logger.debug("Session cookie found: #{inspect(session_cookie)}")

      with {:ok, session_data} <- verify_and_decrypt(session_cookie),
           {:ok, user_id} <- extract_user_id(session_data) do
        Logger.info("User is logged in with ID: #{user_id}")

        conn
        # |> put_session(:data, session_data)
        |> assign(:current_user_id, user_id)
      else
        {:error, reason} ->
          Logger.error("Failed to verify and decode session: #{inspect(reason)}")
          conn
      end
    else
      Logger.debug("No session cookie found")
      conn
    end
  end

  defp get_session_cookie(conn, cookie_name) do
    conn
    |> get_req_header("cookie")
    |> List.first()
    |> parse_cookies()
    |> Map.get(cookie_name)
  end

  defp parse_cookies(cookie_header) when is_binary(cookie_header) do
    cookie_header
    |> String.split("; ")
    |> Enum.map(fn cookie ->
      [key, value] = String.split(cookie, "=", parts: 2)
      {key, value}
    end)
    |> Enum.into(%{})
  end

  defp parse_cookies(_), do: %{}

  defp verify_and_decrypt(cookie) do
    cookie = URI.decode_www_form(cookie)

    secret_key_base = Application.get_env(:divisare, :session_secret_key_base)
    encrypted_cookie_salt = Application.get_env(:divisare, :session_cookie_salt)
    signed_cookie_salt = Application.get_env(:divisare, :session_signed_cookie_salt)

    # Generate keys using :crypto directly to match Ruby's OpenSSL::PKCS5.pbkdf2_hmac_sha1
    secret =
      :crypto.pbkdf2_hmac(:sha, secret_key_base, encrypted_cookie_salt, @iterations, @key_size)
      # AES-256-CBC key length is 32 bytes
      |> binary_part(0, 32)

    sign_secret =
      :crypto.pbkdf2_hmac(:sha, secret_key_base, signed_cookie_salt, @iterations, @key_size)

    # Verify
    [data, digest] = String.split(cookie, "--")
    computed_digest = :crypto.mac(:hmac, :sha, sign_secret, data) |> Base.encode16(case: :lower)

    if !Plug.Crypto.secure_compare(digest, computed_digest) do
      {:error, "Invalid message"}
    else
      # Decrypt
      encrypted_message = Base.decode64!(data)
      [encrypted_data, iv] = String.split(encrypted_message, "--") |> Enum.map(&Base.decode64!/1)

      with {:ok, decrypted_data} <- decrypt(encrypted_data, secret, iv),
           {:ok, session_data} <- Jason.decode(decrypted_data) do
        {:ok, session_data}
      else
        error -> error
      end
    end
  end

  defp decrypt(encrypted_data, key, iv) do
    decrypted_data = :crypto.crypto_one_time(@cipher, key, iv, encrypted_data, false)
    {:ok, unpad(decrypted_data)}
  rescue
    e -> {:error, "Decryption failed: #{inspect(e)}"}
  end

  defp unpad(data) do
    padding_size = :binary.last(data)

    <<unpadded_data::binary-size(byte_size(data) - padding_size),
      _padding::binary-size(padding_size)>> = data

    unpadded_data
  end

  defp extract_user_id(%{"warden.user.person.key" => [[user_id], _]}), do: {:ok, user_id}
  defp extract_user_id(_), do: {:error, "user_id not found in session cookie"}
end
