#************************************
#
#      filename: Party.ex
#
#   description: Simulate Party with
#                actor model
#
#        author: Berkshire, Tyler
#      login id: FA_18_CPS356_32
#
#         class: CPS 356
#    instructor: Perugini
#    assignment: Homework #9
#
#      assigned: November 13, 2018
#           due: November 20, 2018
#
#***********************************/
import :timer, only: [ sleep: 1 ]

defmodule Party do

   def newPledge(kegSize) do
      pid = spawn_link(__MODULE__, :listen_pledge, [kegSize, true])
      Process.register(pid, :pledge_actor)
      pid
   end

   def newKeg(size) do
      pid = spawn_link(__MODULE__, :listen_keg, [size, 0, :queue.new()])
      Process.register(pid, :keg_actor)
      pid
   end

   def newGuest(number, servings, totalGuests) do
      pid = spawn_link(__MODULE__, :startGuest, [number, servings, totalGuests])
      pid
   end

   def startGuest(number, servings, totalGuests) do
      send(:keg_actor, {:new_guest, {self(), number, servings}})
      if totalGuests - number == totalGuests - 1 do
         send(:keg_actor, {:drink})
      end
      listen_guest(number)
   end

   def spawnGuests(guests, servings, totalGuests) do
      newGuest(guests, servings, totalGuests)
      if guests > 1 do
         spawnGuests(guests - 1, servings, totalGuests)
      end
   end

   def listen_pledge(kegSize, sleeping) do
      if sleeping do
         IO.puts("Pledge is sleeping in the toolshed.")
      end

      receive do
         {:refill_keg, guest} ->
            IO.puts("Guest #{elem(guest, 1)} just woke up the pledge.")
            IO.puts("Pledge just woke up.")
            send(:keg_actor, {:fill, kegSize, guest})
            listen_pledge(kegSize, false)
         {:full} ->
            send(:keg_actor, {:drink})
            listen_pledge(kegSize, true)
      end
   end

   def listen_keg(servingsLeft, refills, guests) do
      receive do
         {:new_guest, guest} ->
            listen_keg(servingsLeft, refills, :queue.in(guest, guests))
         {:drink} ->
            cond do
               :queue.is_empty(guests) ->
                  exit(:done)
               elem(:queue.get(guests), 2) == 0 ->
                  send(elem(:queue.get(guests), 0), {:done})
                  listen_keg(servingsLeft, refills, :queue.drop(guests))
               true ->
                  IO.puts("Guest #{elem(:queue.get(guests), 1)} is attempting to retrieve a serving.")
                  cond do
                     servingsLeft == 0 ->
                        cond do
                           true ->
                              send(:pledge_actor, {:refill_keg, :queue.get(guests)})
                              listen_keg(servingsLeft, refills, :queue.drop(guests))
                        end
                     true ->
                        IO.puts("Guest #{elem(:queue.get(guests), 1)} is drinking.")
                        sleep(250)
                        IO.puts("Guest #{elem(:queue.get(guests), 1)} is done drinking. " <>
                              "[refill #{refills} has #{servingsLeft - 1} servings remaining]")
                        send(elem(:queue.get(guests), 0), {:drank, elem(:queue.get(guests), 2)})
                        listen_keg(servingsLeft - 1, refills, :queue.drop(guests))
                  end
            end
         {:fill, kegSize, guest} ->
            IO.puts("Pledge just refilled the keg.")
            send(:pledge_actor, {:full})
            listen_keg(kegSize, refills + 1, :queue.in(guest, guests))
      end

   end

   def listen_guest(number) do
      receive do
         {:drank, drinksToGo} ->
            send(:keg_actor, {:new_guest, {self(), number, drinksToGo - 1}})
            send(:keg_actor, {:drink})
            listen_guest(number)
         {:done} ->
            send(:keg_actor, {:drink})
            exit(:done_drinking)
      end
   end

   def waitForEnd(guests) do
      cond do
         guests == 0 ->
            :party_over
         true ->
            receive do
               {:EXIT, _pid, reason} ->
                  IO.puts("A guest is tired and is leaving the party (#{reason}).")
                  IO.puts("#{guests - 1} guest(s) remain.")
                  waitForEnd(guests - 1)
            end
      end
   end
end

Process.flag(:trap_exit, true)
Party.newPledge(String.to_integer(hd(System.argv())))
Party.newKeg(String.to_integer(hd(System.argv())))
Party.spawnGuests(String.to_integer(hd(tl(System.argv()))), String.to_integer(hd(tl(tl(System.argv())))),
                  String.to_integer(hd(tl(System.argv()))))
Party.waitForEnd(String.to_integer(hd(tl(System.argv()))))
