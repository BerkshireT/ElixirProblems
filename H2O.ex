#************************************
#
#      filename: H2O.ex
#
#   description: Simulate H2O with
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

defmodule H2O do

   def newChemistManager() do
      pid = spawn_link(__MODULE__, :listen_chemist_manager,
                       [:queue.new(), :queue.new()])
      Process.register(pid, :manager_actor)
      pid
   end

   def listen_chemist_manager(hydrogenQ, oxygenQ) do
      receive do
         {:H_available, hydrogen} ->
            send(:manager_actor, {:make_molecule})
            listen_chemist_manager(:queue.in(hydrogen, hydrogenQ), oxygenQ)
         {:O_available, oxygen} ->
            send(:manager_actor, {:make_molecule})
            listen_chemist_manager(hydrogenQ, :queue.in(oxygen, oxygenQ))
         {:make_molecule} ->
            cond do
               :queue.len(hydrogenQ) >= 2 and :queue.len(oxygenQ) >= 1 ->
                  h1 = :queue.get(hydrogenQ)
                  hydrogenQ = :queue.drop(hydrogenQ)
                  IO.puts("Chemist Manager is making H2O molecule out of " <>
                          "Hydrogen atom #{elem(h1, 1)}, " <>
                          "Hydrogen atom #{elem(:queue.get(hydrogenQ), 1)}, " <>
                          "Oxygen atom #{elem(:queue.get(oxygenQ), 1)}.")
                  send(elem(h1, 0), {:molecule_made})
                  send(elem(:queue.get(hydrogenQ), 0), {:molecule_made})
                  send(elem(:queue.get(oxygenQ), 0), {:molecule_made})
                  sleep(250)
                  listen_chemist_manager(:queue.drop(hydrogenQ), :queue.drop(oxygenQ))
               true ->
                  listen_chemist_manager(hydrogenQ, oxygenQ)
            end
      end
   end

   def listen_hydrogen() do
      receive do
         {:molecule_made} ->
            exit(:hydrogen_normal)
      end
   end

   def listen_oxygen() do
      receive do
         {:molecule_made} ->
            exit(:oxygen_normal)
      end
   end

   def start_hydrogen(number) do
      IO.puts("Hydrogen atom #{number} is ready.")
      send(:manager_actor, {:H_available, {self(), number}})
      listen_hydrogen()
   end

   def start_oxygen(number) do
      IO.puts("Oxygen atom #{number} is ready.")
      send(:manager_actor, {:O_available, {self(), number}})
      listen_oxygen()
   end

   def newHorO(number, hydrogen) do
      cond do
         hydrogen ->
            pid = spawn_link(__MODULE__, :start_hydrogen, [number])
            pid
         true ->
            pid = spawn_link(__MODULE__, :start_oxygen, [number])
            pid
      end
   end

   def spawnHorO(count, hydrogen) do
      cond do
         hydrogen ->
            newHorO(count, true)
         true ->
            newHorO(count, false)
      end
      if count > 1 do
         spawnHorO(count - 1 , hydrogen)
      end
   end

   def waitForEnd(elementsLeft) do
      cond do
         elementsLeft == 0 ->
            IO.puts("The chemist manager has shutdown (manager_normal).")
         true ->
            receive do
               {:EXIT, _pid, reason} ->
                  IO.puts("An element has exited (#{reason}).")
                  IO.puts("Only #{elementsLeft - 1} elements left.")
                  waitForEnd(elementsLeft - 1)
            end
      end
   end

end

Process.flag(:trap_exit, true)
H2O.newChemistManager()

hydrogen = String.to_integer(hd(System.argv()))
oxygen = String.to_integer(hd(tl(System.argv())))
elements = hydrogen + oxygen

H2O.spawnHorO(hydrogen, true)
H2O.spawnHorO(oxygen, false)
H2O.waitForEnd(elements)
