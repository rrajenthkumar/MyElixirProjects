defmodule FormulaX.CarControl.CrashDetection do
  @moduledoc """
  This module is used to detect crash with a car or with an obstacle
  """

  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle

  @car_length Parameters.car_length()
  # Obstacles have been set to the same length as cars
  @obstacle_length Parameters.car_length()

  @doc """
  Please note that the race and car structs passed into this function have already been updated with the forward or sideward movement for which the possibility of crash is checked.
  The term 'querying car' in this module refers to the car that is requesting the crash check.
  """
  @spec crash?(Race.t(), Car.t(), :front | :left | :right) :: boolean()
  def crash?(
        race = %Race{},
        querying_car = %Car{},
        _crash_check_side = :front
      ) do
    crash_with_car?(race, querying_car, :front)
    |> case do
      false -> crash_with_obstacle?(race, querying_car)
      result -> result
    end
  end

  def crash?(
        race = %Race{},
        querying_car = %Car{},
        crash_check_side
      )
      when crash_check_side in [:left, :right] do
    querying_car_lane = Car.get_lane(querying_car)

    case querying_car_lane do
      # Crash with a background item outside tracks
      :out_of_tracks ->
        true

      _querying_car_lane ->
        crash_with_car?(race, querying_car, crash_check_side)
        |> case do
          false -> crash_with_obstacle?(race, querying_car)
          result -> result
        end
    end
  end

  ### Crash check with another car

  @spec crash_with_car?(Race.t(), Car.t(), :front | :left | :right) :: boolean()
  defp crash_with_car?(race = %Race{}, querying_car = %Car{}, crash_check_side)
       when crash_check_side in [:front, :left, :right] do
    race
    |> get_crashable_cars(querying_car, crash_check_side)
    |> Enum.any?(fn car ->
      cars_at_same_position?(car, querying_car) or
        cars_just_touching?(car, querying_car) or
        cars_overlapping?(car, querying_car)
    end)
  end

  @spec get_crashable_cars(Race.t(), Car.t(), :front | :left | :right) :: list(Car.t())
  defp get_crashable_cars(
         race = %Race{},
         querying_car = %Car{y_position: querying_car_y_position},
         _crash_check_side = :front
       ) do
    race
    # Since the movement that could possibly cause the crash has already happened all the crashable cars will be in the same lane as the querying car
    |> get_same_lane_cars(querying_car)
    # We remove the cars behind the querying car
    |> Enum.reject(fn car -> car.y_position < querying_car_y_position end)
  end

  defp get_crashable_cars(
         race = %Race{},
         querying_car = %Car{y_position: querying_car_y_position},
         crash_check_side
       )
       when crash_check_side in [:left, :right] do
    race
    # Since the movement that could possibly cause the crash has already happened all the crashable cars will be in the same lane as the querying car
    |> get_same_lane_cars(querying_car)
    # We remove the cars ouside the region from one car length behind querying car to one car length in front of the querying car
    |> Enum.reject(fn car ->
      car.y_position < querying_car_y_position - @car_length or
        car.y_position > querying_car_y_position + @car_length
    end)
  end

  @spec get_same_lane_cars(Race.t(), Car.t()) :: list(Car.t())
  defp get_same_lane_cars(
         race = %Race{},
         querying_car = %Car{
           id: querying_car_id
         }
       ) do
    querying_car_lane = Car.get_lane(querying_car)

    race
    |> Race.get_lanes_and_cars_map()
    |> Map.get(querying_car_lane, [])
    |> Enum.reject(fn car -> car.id == querying_car_id end)
  end

  @spec cars_at_same_position?(Car.t(), Car.t()) :: boolean()
  defp cars_at_same_position?(%Car{y_position: car_1_y_position}, %Car{
         y_position: car_2_y_position
       }) do
    car_1_y_position == car_2_y_position
  end

  @spec cars_just_touching?(Car.t(), Car.t()) :: boolean()
  defp cars_just_touching?(%Car{y_position: car_1_y_position}, %Car{
         y_position: car_2_y_position
       }) do
    car_1_y_position + @car_length == car_2_y_position or
      car_1_y_position == car_2_y_position + @car_length
  end

  @spec cars_overlapping?(Car.t(), Car.t()) :: boolean()
  defp cars_overlapping?(%Car{y_position: car_1_y_position}, %Car{
         y_position: car_2_y_position
       }) do
    # Car_1 front wheels between Car_2 front and rear wheels or
    # Car_1 rear wheels between Car_2 front and rear wheels
    (car_1_y_position + @car_length > car_2_y_position and
       car_1_y_position < car_2_y_position) or
      (car_1_y_position > car_2_y_position and
         car_1_y_position < car_2_y_position + @car_length)
  end

  ### Crash check with an obstacle

  @spec crash_with_obstacle?(Race.t(), Car.t()) :: boolean()
  defp crash_with_obstacle?(
         race = %Race{},
         querying_car = %Car{}
       ) do
    race
    |> get_crashable_obstacles(querying_car)
    |> Enum.any?(fn obstacle ->
      obstacle_y_position = Obstacle.get_y_position(obstacle, race)

      at_same_position_with_obstacle?(querying_car, obstacle_y_position) or
        touching_obstacle?(querying_car, obstacle_y_position) or
        overlap_with_obstacle?(querying_car, obstacle_y_position)
    end)
  end

  @spec get_crashable_obstacles(Race.t(), Car.t()) :: list(Obstacle.t())
  defp get_crashable_obstacles(
         race = %Race{},
         querying_car = %Car{y_position: querying_car_y_position}
       ) do
    race
    |> get_same_lane_obstacles(querying_car)
    # We remove the obstacles behind the querying car
    |> Enum.reject(fn obstacle ->
      obstacle_y_position = Obstacle.get_y_position(obstacle, race)
      obstacle_y_position < querying_car_y_position
    end)
  end

  @spec get_same_lane_obstacles(Race.t(), Car.t()) :: list(Obstacle.t())
  defp get_same_lane_obstacles(
         race = %Race{},
         querying_car = %Car{}
       ) do
    querying_car_lane = Car.get_lane(querying_car)

    race
    |> Race.get_lanes_and_obstacles_map()
    |> Map.get(querying_car_lane, [])
  end

  @spec at_same_position_with_obstacle?(Car.t(), Parameters.rem()) :: boolean()
  defp at_same_position_with_obstacle?(
         %Car{y_position: car_y_position},
         obstacle_y_position
       )
       when is_float(obstacle_y_position) do
    obstacle_y_position == car_y_position
  end

  @spec touching_obstacle?(Car.t(), Parameters.rem()) :: boolean()
  defp touching_obstacle?(%Car{y_position: car_y_position}, obstacle_y_position)
       when is_float(obstacle_y_position) do
    obstacle_y_position + @obstacle_length == car_y_position or
      car_y_position + @car_length == obstacle_y_position
  end

  @spec overlap_with_obstacle?(Car.t(), Parameters.rem()) :: boolean()
  defp overlap_with_obstacle?(%Car{y_position: car_y_position}, obstacle_y_position)
       when is_float(obstacle_y_position) do
    # Car front wheels between obstacle start and end or
    # Car rear wheels between obstacle start and end
    (car_y_position + @car_length > obstacle_y_position and
       car_y_position < obstacle_y_position) or
      (car_y_position > obstacle_y_position and
         car_y_position < obstacle_y_position + @obstacle_length)
  end
end
