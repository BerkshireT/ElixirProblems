#************************************
#
#      filename: Bakery.ex
#
#   description: Simulate Bakery with
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

defmodule Bakery do

   def newGrocer() do
      pid = spawn_link(__MODULE__, :listen_grocer, [])
      Process.register(pid, :grocer_actor)
      pid
   end

   def newBaker() do
      pid = spawn_link(__MODULE__, :start_baker, [])
      Process.register(pid, :baker_actor)
      pid
   end

   def start_baker() do
      send(:grocer_actor, {:ready, 1})
      listen_baker()
   end

   def listen_grocer() do
       receive do
         {:ready, number} ->
            cond do
               number == 1 ->
                  IO.puts("Grocer just put sauce and cheese on table.")
               number == 2 ->
                  IO.puts("Grocer just put cheese and dough on table.")
               true ->
                  IO.puts("Grocer just put dough and sauce on table.")
            end
            send(:baker_actor, {:bake, number})
            listen_grocer()
      end
   end

   def listen_baker() do
      receive do
         {:bake, number} ->
            cond do
               number == 1 ->
                  IO.puts("Dough baker baking a pizza.")
                  sleep(250)
                  IO.puts("Dough baker done baking pizza.")
               number == 2 ->
                  IO.puts("Sauce baker baking a pizza.")
                  sleep(250)
                  IO.puts("Sauce baker done baking pizza.")
               true ->
                  IO.puts("Cheese baker baking a pizza.")
                  sleep(250)
                  IO.puts("Cheese baker done baking pizza.")
            end
            IO.puts("")
            send(:grocer_actor, {:ready, rem(number, 3) + 1})
            listen_baker()
      end
   end
end

Process.flag(:trap_exit, true)
Bakery.newGrocer()
Bakery.newBaker()
