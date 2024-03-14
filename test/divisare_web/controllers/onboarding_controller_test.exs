defmodule DivisareWeb.OnboardingControllerTest do
  use DivisareWeb.ConnCase

  # import Divisare.AccountsFixtures

  # @create_attrs %{email: "some email", name: "some name"}
  # @update_attrs %{email: "some updated email", name: "some updated name"}
  # @invalid_attrs %{email: nil, name: nil}

  # describe "index" do
  #   test "lists all people", %{conn: conn} do
  #     conn = get(conn, ~p"/people")
  #     assert html_response(conn, 200) =~ "Listing People"
  #   end
  # end

  # describe "new onboarding" do
  #   test "renders form", %{conn: conn} do
  #     conn = get(conn, ~p"/people/new")
  #     assert html_response(conn, 200) =~ "New Onboarding"
  #   end
  # end

  # describe "create onboarding" do
  #   test "redirects to show when data is valid", %{conn: conn} do
  #     conn = post(conn, ~p"/people", onboarding: @create_attrs)

  #     assert %{id: id} = redirected_params(conn)
  #     assert redirected_to(conn) == ~p"/people/#{id}"

  #     conn = get(conn, ~p"/people/#{id}")
  #     assert html_response(conn, 200) =~ "Onboarding #{id}"
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(conn, ~p"/people", onboarding: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "New Onboarding"
  #   end
  # end

  # describe "edit onboarding" do
  #   setup [:create_onboarding]

  #   test "renders form for editing chosen onboarding", %{conn: conn, onboarding: onboarding} do
  #     conn = get(conn, ~p"/people/#{onboarding}/edit")
  #     assert html_response(conn, 200) =~ "Edit Onboarding"
  #   end
  # end

  # describe "update onboarding" do
  #   setup [:create_onboarding]

  #   test "redirects when data is valid", %{conn: conn, onboarding: onboarding} do
  #     conn = put(conn, ~p"/people/#{onboarding}", onboarding: @update_attrs)
  #     assert redirected_to(conn) == ~p"/people/#{onboarding}"

  #     conn = get(conn, ~p"/people/#{onboarding}")
  #     assert html_response(conn, 200) =~ "some updated email"
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, onboarding: onboarding} do
  #     conn = put(conn, ~p"/people/#{onboarding}", onboarding: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "Edit Onboarding"
  #   end
  # end

  # describe "delete onboarding" do
  #   setup [:create_onboarding]

  #   test "deletes chosen onboarding", %{conn: conn, onboarding: onboarding} do
  #     conn = delete(conn, ~p"/people/#{onboarding}")
  #     assert redirected_to(conn) == ~p"/people"

  #     assert_error_sent 404, fn ->
  #       get(conn, ~p"/people/#{onboarding}")
  #     end
  #   end
  # end

  # defp create_onboarding(_) do
  #   onboarding = onboarding_fixture()
  #   %{onboarding: onboarding}
  # end
end
