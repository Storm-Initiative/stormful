defmodule Stormful.PlanningTest do
  use Stormful.DataCase

  alias Stormful.Planning

  describe "plans" do
    alias Stormful.Planning.Plan

    import Stormful.PlanningFixtures

    @invalid_attrs %{title: nil}

    test "list_plans/0 returns all plans" do
      plan = plan_fixture()
      assert Planning.list_plans() == [plan]
    end

    test "get_plan!/1 returns the plan with given id" do
      plan = plan_fixture()
      assert Planning.get_plan!(plan.id) == plan
    end

    test "create_plan/1 with valid data creates a plan" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Plan{} = plan} = Planning.create_plan(valid_attrs)
      assert plan.title == "some title"
    end

    test "create_plan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Planning.create_plan(@invalid_attrs)
    end

    test "update_plan/2 with valid data updates the plan" do
      plan = plan_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Plan{} = plan} = Planning.update_plan(plan, update_attrs)
      assert plan.title == "some updated title"
    end

    test "update_plan/2 with invalid data returns error changeset" do
      plan = plan_fixture()
      assert {:error, %Ecto.Changeset{}} = Planning.update_plan(plan, @invalid_attrs)
      assert plan == Planning.get_plan!(plan.id)
    end

    test "delete_plan/1 deletes the plan" do
      plan = plan_fixture()
      assert {:ok, %Plan{}} = Planning.delete_plan(plan)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_plan!(plan.id) end
    end

    test "change_plan/1 returns a plan changeset" do
      plan = plan_fixture()
      assert %Ecto.Changeset{} = Planning.change_plan(plan)
    end
  end
end
