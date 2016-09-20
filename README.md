# ft-chat
Fault tolerant chat, developed for FLISOL 2016

## Technologies used

- Elixir
- Cowboy WebServer
- CoffeeScript
- Angular

## Basic explanation

This project is an example of a fault-tolerant service implemented in Elixir.

The project uses a WebSocket server to enable realtime communication between multiple (web) clients, 
the most basic setup has three chat nodes, this will allow any node to go down without interrupting the 
service for any of the connected clients.

## Fault tolerance

### Server Side

Fault tolerance is achieved by using _chat room_ replication among the cluster's nodes. The cluster uses a [Hash ring](https://en.wikipedia.org/wiki/Consistent_hashing)
to create and locate chat rooms in the cluster.

Each chat room is located in at least two nodes whenever it is created, allowing any node to go down without causing service downtime.

### Client Side

The client uses a basic re-connection algorithm for re-connecting to chat nodes, in case the current connection goes down. 
This is completely transparent to the user.

