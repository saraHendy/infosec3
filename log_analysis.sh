#!/bin/bash

LOG_FILE="huge_access.log"
REPORT_FILE="analysis_report.txt"

# 1. Request Counts
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep '\"GET ' "$LOG_FILE" | wc -l)
post_requests=$(grep '\"POST ' "$LOG_FILE" | wc -l)

# 2. Unique IPs
unique_ips=$(cut -d' ' -f1 "$LOG_FILE" | sort | uniq | wc -l)
ip_request_breakdown=$(awk '{print $1, $6}' "$LOG_FILE" | tr -d '"' | sort | uniq -c | sort -nr)

# 3. Failure Requests
failures=$(awk '$9 ~ /^[45]/ {count++} END {print count+0}' "$LOG_FILE")
fail_percentage=$(awk -v total=$total_requests -v fails=$failures 'BEGIN {printf("%.2f", (fails/total)*100)}')

# 4. Top User
top_user=$(cut -d' ' -f1 "$LOG_FILE" | sort | uniq -c | sort -nr | head -1)

# 5. Daily Request Averages
daily_avg=$(awk -F: '{print $1}' "$LOG_FILE" | cut -d[ -f2 | sort | uniq -c | awk '{sum+=$1; count++} END {print int(sum/count)}')

# 6. Days with Most Failures
top_failure_days=$(awk '$9 ~ /^[45]/ {split($4, a, ":"); gsub("\\[", "", a[1]); fails[a[1]]++} END {for (d in fails) print fails[d], d}' "$LOG_FILE" | sort -nr | head -3)

# 7. Requests Per Hour
requests_per_hour=$(awk -F: '{print $2}' "$LOG_FILE" | sort | uniq -c | sort -n)

# 8. Status Code Breakdown
status_breakdown=$(awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr)

# 9. Most Active IP by Method
most_get=$(grep '\"GET ' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1)
most_post=$(grep '\"POST ' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1)

# 10. Failure Patterns by Hour
failures_by_hour=$(awk '$9 ~ /^[45]/ {split($4, a, ":"); print a[2]}' "$LOG_FILE" | sort | uniq -c | sort -nr)

# Write to report
{
echo "=== Request Analysis Report ==="
echo ""
echo "1. Request Counts"
echo "-----------------"
echo "Total Requests: $total_requests"
echo "GET Requests: $get_requests"
echo "POST Requests: $post_requests"
echo ""
echo "2. Unique IPs"
echo "-------------"
echo "Total Unique IPs: $unique_ips"
echo "Request Breakdown per IP:"
echo "$ip_request_breakdown"
echo ""
echo "3. Failure Requests"
echo "-------------------"
echo "Failures: $failures ($fail_percentage%)"
echo ""
echo "4. Most Active IP"
echo "-----------------"
echo "$top_user"
echo ""
echo "5. Average Requests Per Day"
echo "---------------------------"
echo "$daily_avg"
echo ""
echo "6. Days with Most Failures"
echo "--------------------------"
echo "$top_failure_days"
echo ""
echo "7. Requests Per Hour"
echo "---------------------"
echo "$requests_per_hour"
echo ""
echo "8. Status Code Breakdown"
echo "------------------------"
echo "$status_breakdown"
echo ""
echo "9. Most Active IPs by Method"
echo "----------------------------"
echo "GET: $most_get"
echo "POST: $most_post"
echo ""
echo "10. Failure Request Patterns (by hour)"
echo "--------------------------------------"
echo "$failures_by_hour"
echo ""
echo "Suggestions:"
echo "============"
echo "- Consider load balancing during peak hours with most requests or failures."
echo "- Investigate frequent 4xx errors for client-side issues (e.g., 404s)."
echo "- Investigate 5xx errors for backend problems (e.g., server overload)."
echo "- Check top users (especially GET-heavy IPs) for potential scraping or abuse."
echo "- Enhance caching or implement rate limiting for most active hours."
} > "$REPORT_FILE"

echo "Analysis complete. Report saved to $REPORT_FILE"
