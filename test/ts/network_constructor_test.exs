defmodule NetworkConstructorTest do
	@moduledoc """
	Module to test NetworkConstructor
	Create new NC process and add stations to its registry
	Use InputParser to create new stations
	Use message passing to find best itinerary
	"""
	use ExUnit.Case, async: true

	test "Start new NC and add new Station process" do
		assert NetworkConstructor.lookup_name(NetworkConstructor, "VascoStation")==
		:error
		assert NetworkConstructor.create(NetworkConstructor, "TestStation", 12)==:ok
		{:ok, _}=NetworkConstructor.lookup_name(NetworkConstructor,
			"TestStation")
	end

	test "Add new Stations using InputParser" do
		assert {:ok, pid}=InputParser.start_link
		stn_map=InputParser.get_station_map(pid)
		_=InputParser.get_schedules(pid)
		for stn_key<-Map.keys(stn_map) do
			stn_code=Map.get(stn_map, stn_key)
			stn_struct=InputParser.get_station_struct(pid, stn_key)
			assert NetworkConstructor.create(NetworkConstructor, stn_key, stn_code)==
			:ok
			{:ok, {_, station}}=NetworkConstructor.lookup_name(NetworkConstructor,
				stn_key)
			Station.update(station, %StationStruct{})
			Station.update(station, stn_struct)
		end
		{:ok, {_, _}}=NetworkConstructor.lookup_name(NetworkConstructor,
			"Alnavar Junction")
	end

	test "Complete test" do
		assert {:ok, pid}=InputParser.start_link
		stn_map=InputParser.get_station_map(pid)
		_=InputParser.get_schedules(pid)
		for stn_key<-Map.keys(stn_map) do
			stn_code=Map.get(stn_map, stn_key)
			stn_struct=InputParser.get_station_struct(pid, stn_key)
			assert NetworkConstructor.create(NetworkConstructor, stn_key, stn_code)==
			:ok
			{:ok, {_, station}}=NetworkConstructor.lookup_name(NetworkConstructor,
				stn_key)
			Station.update(station, stn_struct)
		end
		{:ok, {code1, stn1}}=NetworkConstructor.lookup_name(NetworkConstructor,
			"Madgaon")
		{:ok, {code2, _}}=NetworkConstructor.lookup_name(NetworkConstructor,
			"Ratnagiri")
		itinerary=[%{src_station: code1, dst_station: code2, arrival_time: 0,
			     end_time: 86_400}]
		query=List.first(itinerary)
		API.start_link
		API.put("conn", query, [])
		API.put({"times", query}, [])
		NetworkConstructor.add_query(NetworkConstructor, query, "conn")
		itinerary=[Map.put(query, :day, 0)]
		{:ok, pid}=QC.start_link
		API.put(query, {self(), pid, System.system_time(:milliseconds)})
		NetworkConstructor.send_to_src(NetworkConstructor, stn1, itinerary)
		Process.send_after(self(), :timeout, 500)
		receive do
			:timeout->
				NetworkConstructor.del_query(NetworkConstructor, query)
				_=API.get("conn")
				API.remove({"times", query})
				API.remove("conn")
				API.remove(query)
				QC.stop(pid)
			:release->
				_=API.get("conn")
				API.remove({"times", query})
				API.remove("conn")
				API.remove(query)
				QC.stop(pid)
		end
	end

end
