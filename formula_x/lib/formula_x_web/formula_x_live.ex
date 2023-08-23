defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview to view and control the racing game
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Car.Controls
  alias FormulaX.Race.RaceEngine

  @impl true
  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <.speed_controls/>
        <div class="screen">
          <.background images={@race.background.left_side_images} y_position={@race.background.y_position}/>
          <div class="race">
            <div class="lanes">
              <div class="lane"></div>
              <div class="lane"></div>
              <div class="lane"></div>
            </div>
            <.cars cars={@race.cars}/>
          </div>
          <.background images={@race.background.right_side_images} y_position={@race.background.y_position}/>
        </div>
        <.direction_controls/>
      </div>
    </div>
    """
  end

  defp speed_controls(assigns) do
    ~H"""
    <div class="speed_controls">
      <a class="top" href="#" phx-click="speedup"></a>
      <a class="bottom" href="#" phx-click="slowdown"></a>
    </div>
    """
  end

  defp background(assigns) do
    ~H"""
    <div class="background" style={background_position_style(@y_position)}>
      <%= for image <- @images do %>
        <div class="image_container">
          <img src={"/images/backgrounds/#{image}"} />
        </div>
      <% end %>
    </div>
    """
  end

  defp cars(assigns) do
    ~H"""
    <div class="cars">
      <%= for car <- @cars do %>
        <img src={"/images/cars/#{car.image}"} style={car_position_style(car)}/>
      <% end %>
    </div>
    """
  end

  defp direction_controls(assigns) do
    ~H"""
    <div class="direction_controls">
      <a class="left" href="#" phx-click="move_left"></a>
      <a class="right" href="#" phx-click="move_right"></a>
    </div>
    """
  end

  @impl true
  def mount(_params, %{}, socket) do
    race =
      Race.initialize()
      |> Race.start()

    RaceEngine.start(race, self())

    socket = assign(socket, :race, race)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "speedup",
        _params,
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:speedup)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:speedup)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "slowdown",
        _params,
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:slowdown)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:slowdown)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "move_right",
        _params,
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:right)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:right)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "move_left",
        _params,
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:left)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %{
          assigns: %{
            race: race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:left)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => _another_key}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:update_visuals, race = %Race{status: status}},
        socket
      ) do
    if status == :aborted do
      RaceEngine.stop()
    end

    socket = assign(socket, :race, race)

    {:noreply, socket}
  end

  @spec car_position_style(Car.t()) :: String.t()
  defp car_position_style(%Car{
         x_position: x_position,
         y_position: y_position
       }) do
    "left: #{x_position}px; bottom: #{y_position}px;"
  end

  @spec background_position_style(Car.y_position()) :: String.t()
  defp background_position_style(y_position) when is_integer(y_position) do
    "top: #{y_position}px"
  end
end
