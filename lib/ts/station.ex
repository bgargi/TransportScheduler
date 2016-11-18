# Module to create station process and FSM and handle local variable updates

defmodule Station do
  use GenStateMachine

  # Client

  def start_link() do
    GenStateMachine.start_link(Station, {:nodata, nil})
  end

  def update(station,  %StationStruct{} = newVars) do
    GenStateMachine.cast(station, {:update, newVars})
  end

  def get_vars(station) do
    GenStateMachine.call(station, :get_vars)
  end
  
  def get_state(station) do
    GenStateMachine.call(station, :get_state)
  end

  def receive_at_src(nc, src, itinerary) do
    GenStateMachine.cast(src, {:receive_at_src, nc, src, itinerary})
  end

  def send_to_stn(nc, src, dst, itinerary) do
    GenStateMachine.cast(dst, {:receive_at_stn, nc, src, itinerary})
  end

  def send_to_NC(server, itinerary) do
    StationConstructor.receive_from_dest(server, itinerary)
  end

  # Server (callbacks)

  def handle_event(:cast, {:update, oldVars}, state, vars) do
    #IO.puts "update"
    schedule = Enum.sort(oldVars.schedule)
    newVars =  %StationStruct{locVars: oldVars.locVars, schedule: schedule, station_number: oldVars.station_number, station_name: oldVars.station_name, pid: oldVars.pid, congestion_low: oldVars.congestion_low, congestion_high: oldVars.congestion_high, choose_fn: oldVars.choose_fn}
    case(newVars.locVars.disturbance) do
      "yes"	->
	{:next_state, :disturbance, newVars}
      "no"	-> 
	case(newVars.locVars.congestion) do
	  "none"	->
	    {:next_state, :delay, newVars}
	  "low"		->
	    # {congestionDelay, y} = Code.eval_string(newVars.congestion_low, [delay: newVars.locVars.delay])
	    # congestionDelay = StationFunctions.compute_congestion_delay1(newVars.locVars.delay, newVars.congestion_low)
	    congestionDelay = StationFunctions.func(newVars.choose_fn).(newVars.locVars.delay, newVars.congestion_low)

	    {x, updateLocVars} = Map.get_and_update(newVars.locVars, :congestionDelay, fn delay -> {delay, congestionDelay} end)
	    updateVars = %StationStruct{locVars: updateLocVars, schedule: newVars.schedule }
	    {:next_state, :delay, updateVars}
	  "high"	->
	    # {congestionDelay, y} = Code.eval_string(newVars.congestion_high, [delay: newVars.locVars.delay])
	    # congestionDelay = StationFunctions.compute_congestion_delay1(newVars.locVars.delay, newVars.congestion_high)
	    congestionDelay = StationFunctions.func(newVars.choose_fn).(newVars.locVars.delay, newVars.congestion_high)

	    {x, updateLocVars} = Map.get_and_update(newVars.locVars, :congestionDelay, fn delay -> {delay, congestionDelay} end)
	    updateVars = %StationStruct{locVars: updateLocVars, schedule: newVars.schedule }
	    {:next_state, :delay, updateVars}
	  _				->
	    {:next_state, :delay, newVars}	
	end
      _			->
	{:next_state, :delay, newVars}
    end          
  end

  def handle_event({:call, from}, :get_vars, state, vars) do
    {:next_state, state, vars, [{:reply, from, vars}]}
  end

  def handle_event({:call, from}, :get_state, state, vars) do
    {:next_state, state, vars, [{:reply, from, state}]}
  end

  def check_neighbours(src, time) do
    schedule = Station.get_vars(src).schedule
    nextList = Enum.filter(schedule, fn(x) -> x.dept_time > time end)
  end

  def function(nc, src, itinerary, dstSched) do
    newItinerary = [itinerary|dstSched]
    [query|tail] = itinerary
    IO.puts "in fn"
    IO.inspect newItinerary
    dst = StationConstructor.lookup_code(nc, dstSched.dst_station)
    if (dst == query.dst_station) do
      Station.send_to_nc(nc, itinerary)
    else
      Station.send_to_stn(nc, src, dst, newItinerary)
    end
  end

  def handle_event(:cast, {:receive_at_src, nc, src, itinerary}, state, vars) do
    [query|tail] = itinerary
    IO.puts "in src"
    IO.inspect query
    #IO.puts query
    nextList = Station.check_neighbours(src, query.arrival_time)
    Enum.each(nextList, fn(x) -> function(nc, src, itinerary, x) end)
    {:next_state, state, vars}
  end

  def handle_event(:cast, {:receive_at_stn, nc, src, itinerary}, state, vars) do
    # newNode = Station.check_neighbours() with time passed from itinerary head
    #[query | tail] = itinerary
    #time = query.time
    #neighbours = Station.check_neighbours(src, time)
    IO.puts "in stn"
    dstSched =  %{vehicleID: 2222, src_station: 1, dst_station: 2, dept_time: "13:12:00", arrival_time: "14:32:00", mode_of_transport: "train"}
    function(nc, src, itinerary, dstSched)
    #newItinerary = [itinerary | newNode]
    #IO.puts newItinerary
    {:next_state, state, vars}
  end

  def handle_event(event_type, event_content, state, vars) do
    # Call the default implementation from GenStateMachine
    super(event_type, event_content, state, vars)
  end
end
