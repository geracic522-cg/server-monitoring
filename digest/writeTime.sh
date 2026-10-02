cat > ~/time_resync.sh << 'EOF'
#!/bin/bash
DEVICE="${1:-md1}"
LOGFILE="$HOME/resync-timing.log"
POLL_SECONDS=30

echo "Watching /dev/${DEVICE} for a resync..."

while ! grep -A2 "^${DEVICE} " /proc/mdstat | grep -q "recovery"; do
    sleep "$POLL_SECONDS"
done

START_EPOCH=$(date +%s)
START_HUMAN=$(date -d "@${START_EPOCH}" '+%Y-%m-%d %H:%M:%S')
echo "Resync on ${DEVICE} detected as running -- timer started at ${START_HUMAN}"

while grep -A2 "^${DEVICE} " /proc/mdstat | grep -q "recovery"; do
    PROGRESS=$(grep -A3 "^${DEVICE} " /proc/mdstat | grep -oP 'recovery = \K[0-9.]+%' )
    echo "  ...still running (${PROGRESS:-unknown}%) at $(date '+%H:%M:%S')"
    sleep "$POLL_SECONDS"
done

END_EPOCH=$(date +%s)
END_HUMAN=$(date -d "@${END_EPOCH}" '+%Y-%m-%d %H:%M:%S')

ELAPSED_SECONDS=$((END_EPOCH - START_EPOCH))
ELAPSED_MINUTES=$(awk "BEGIN { printf \"%.1f\", ${ELAPSED_SECONDS}/60 }")

RESULT="Resync on /dev/${DEVICE}: started ${START_HUMAN}, finished ${END_HUMAN}, total runtime: ${ELAPSED_MINUTES} minutes (${ELAPSED_SECONDS}s)"

echo "$RESULT"
echo "$RESULT" >> "$LOGFILE"
