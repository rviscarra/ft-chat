#!/bin/bash

function cleanup {
  echo 'Cleaning up ...'
  pkill -P $$
}

trap cleanup SIGINT SIGTERM EXIT
mix compile

tmux -L ft_chat new-session -d "elixir --cookie pmfVB5bT1tw2pIjWflzph --sname node1@localhost -S mix run_node --port 8000 --no-halt"
tmux -L ft_chat split-window "elixir --cookie pmfVB5bT1tw2pIjWflzph --sname node2@localhost -S mix run_node --port 8001 --no-halt"
tmux -L ft_chat split-window "iex --cookie pmfVB5bT1tw2pIjWflzph --sname node3@localhost -S mix run_node --port 8002"
tmux -L ft_chat select-layout even-vertical
tmux -L ft_chat attach
