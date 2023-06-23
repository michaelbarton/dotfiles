#!/bin/bash

# Define the Kubernetes service names and ports to forward
service_name=${1:?"Usage: $0 <service> <port>"}
service_port=${2:?"Usage: $0 <service> <port>"}

# Start port forwarding for both services
kubectl port-forward service/$service_name $service_port:$service_port &

# Store the PIDs of the port forwarding processes
pid=$!

# Define the cleanup function to shut down the port forwarding processes
cleanup() {
    echo "Cleaning up..."
    kill $pid
}

# Register the cleanup function to be called when the script is interrupted with Ctrl+C
trap cleanup INT

# Wait for the port forwarding processes to finish
wait
