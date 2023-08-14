defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview that runs the race
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Background

  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <.speed_controls/>
        <div class="screen">
          <.background images={@race.background.left_side_images} y_position={@race.background.y_position}/>
          <div class="race">
            <div class="tracks">
              <div class="track"></div>
              <div class="track"></div>
              <div class="track"></div>
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
      <a class="top" href="#" phx-click="accelerate"></a>
      <a class="bottom" href="#" phx-click="decelerate"></a>
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

  def mount(_params, %{}, socket) do
    race = Race.initialize()

    {:ok, assign(socket, :race, race)}
  end

  def handle_event("start_race", _params, socket = %{race: race}) do
    race =
      race
      |> Race.start()

    {:ok, assign(socket, :race, race)}
  end

  def handle_event(
        "accelerate",
        _params,
        socket = %{
          assigns: %{
            race: race = %Race{background: background}
          }
        }
      ) do
    background = Background.offset(background)

    race = %Race{race | background: background}

    {:noreply, assign(socket, :race, race)}
  end

  def handle_event("decelerate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("move_right", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("move_left", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            race: race = %Race{background: background}
          }
        }
      ) do
    background = Background.offset(background)

    race = %Race{race | background: background}

    {:noreply, assign(socket, :race, race)}
  end

  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowLeft"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowRight"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => _another_key}, socket) do
    {:noreply, socket}
  end

  def handle_event("abort_race", _params, socket = %{race: race}) do
    race = Race.abort(race)

    {:ok, assign(socket, :race, race)}
  end

  def handle_event("complete_race", _params, socket = %{race: race}) do
    race = Race.complete(race)

    {:ok, assign(socket, :race, race)}
  end

  defp car_position_style(%Car{
         x_position: x_position,
         y_position: y_position
       }) do
    "left: #{x_position}px; bottom: #{y_position}px;"
  end

  defp background_position_style(y_position) do
    "top: #{y_position}px"
  end
end
