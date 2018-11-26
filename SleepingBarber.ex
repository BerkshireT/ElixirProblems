#************************************
#
#      filename: SleepingBarber.ex
#
#   description: Actor model solution
#                to barber problem
#
#        author: Berkshire, Tyler
#      login id: FA_18_CPS356_32
#
#         class: CPS 356
#    instructor: Perugini
#    assignment: Homework #8
#
#      assigned: November 8, 2018
#           due: November 13, 2018
#
#***********************************/
import :timer, only: [ sleep: 1 ]

defmodule SleepingBarber do

   def new_barber() do
     pid = spawn_link(__MODULE__, :listen_barber, [true])
     Process.register(pid, :barber_actor)
     pid
   end
 
   def new_waitingroom(initial_chairs) do
     pid = spawn_link(__MODULE__, :listen_waiting_room,
                      [initial_chairs, :queue.new()])
     Process.register(pid, :waitingroom_actor)
     pid
   end
 
   def new_customer(id) do
     pid = spawn_link(__MODULE__, :start_customer, [id])
     pid
   end
 
   def listen_barber(sleeping) do
      cond do
         sleeping -> IO.puts("Barber is sleeping.")
         true -> IO.puts("Barber is awake.")
      end

      receive do
         {:customer_available} ->
            cond do         	   
               sleeping -> 
                  IO.puts("Barber received customer available message.")
                  IO.puts("Barber requesting next customer.")
                  send(:waitingroom_actor, {:next_ready_customer})
                  listen_barber(false)
               true ->
                  listen_barber(false) 
            end 
         {:new_ready_customer, {customer, id}} ->
            IO.puts("Waiting room sent Customer #{id} to the barber.") 
            IO.puts("Barber serving Customer #{id}.")
            send(customer, {:you_are_being_serviced, id})
            sleep(1000)
            send(customer, {:you_are_done, id})
            IO.puts("Barber done serving Customer #{id}.")
            send(:waitingroom_actor, {:next_ready_customer})
         {:waiting_room_empty} ->
            listen_barber(true)
      end
      listen_barber(sleeping)
   end

   def spawn_customers(n) do
      new_customer(n)
      if n > 1 do
         spawn_customers(n-1)
      end
   end

   def start_customer(id) do
      IO.puts ("Customer #{id} arrived at the waiting room.")
      send(:waitingroom_actor, {:new_customer, {self(), id}})
      listen_customer(id)
   end

   def listen_customer(id) do
      receive do
         {:you_are_done, id} ->
            IO.puts("Customer #{id} left the barber shop " <> 
                     "with a clean shave and full of joy.")
            exit(:normal)
         {:you_are_being_serviced, id} ->
            IO.puts("Customer #{id} being serviced.")
            #sleep(1000)
            IO.puts("Customer #{id} done being serviced.")
         {:full, id} ->
            IO.puts("Customer #{id} just left the barber shop " <>
                     "because the barber was busy and the waiting room was full.")
            exit(:waitingroomfull)
      end
      listen_customer(id)
   end

   def listen_waiting_room(chairs_available, roomqueue) do

      IO.puts ("Chairs available: #{chairs_available}")

      receive do
         {:new_customer, {pid, id}} ->
            cond do
               chairs_available > 0 -> 
                  send(:barber_actor, {:customer_available})
                  listen_waiting_room(chairs_available - 1, :queue.in({pid, id}, roomqueue))
               true -> send(pid, {:full, id})
            end
         {:next_ready_customer} ->
            IO.puts("Waiting room received next_ready_customer message.")
            cond do
               :queue.is_empty(roomqueue) ->
                  IO.puts("Waiting room is empty") 
                  send(:barber_actor, {:waiting_room_empty})
               true ->
                  send(:barber_actor, {:new_ready_customer, :queue.get(roomqueue)})
                  listen_waiting_room(chairs_available + 1, :queue.drop(roomqueue))
            end
      end
      listen_waiting_room(chairs_available, roomqueue)
   end
   
   def wait_for_end(count) do
      cond do
         count == 0 -> :ok
         true ->
           receive do
             {:EXIT, _pid, reason} ->
               IO.puts("A customer has exited (#{reason}).")
               IO.puts("Only #{count - 1} customers left.")
               wait_for_end(count - 1)
           end
      end
   end
end

Process.flag(:trap_exit, true)
waiting_room_size = String.to_integer(hd(System.argv()))
customer_count = String.to_integer(hd(tl(System.argv())))

SleepingBarber.new_barber()
SleepingBarber.new_waitingroom(waiting_room_size)
SleepingBarber.spawn_customers(customer_count)
SleepingBarber.wait_for_end(customer_count)
