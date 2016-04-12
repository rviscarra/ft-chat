#!/bin/bash

function cleanup {
  echo 'Cleaning up ...'
  pkill -P $$
}

trap cleanup SIGINT SIGTERM EXIT

elixir --cookie pmfVB5bT1tw2pIjWflzph --sname node1@localhost -S mix run_node --port 8000 --no-halt & 
elixir --cookie pmfVB5bT1tw2pIjWflzph --sname node2@localhost -S mix run_node --port 8001 --no-halt & 
iex --cookie pmfVB5bT1tw2pIjWflzph --sname node3@localhost -S mix run_node --port 8002

