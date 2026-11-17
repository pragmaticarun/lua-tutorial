# host: love
# Run the callbacks demo under a virtual X server (no monitor needed).
xvfb-run -a love callbacks
echo "exit status: $?"
