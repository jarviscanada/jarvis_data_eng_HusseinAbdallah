# get arguments from command
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# check number of arguments
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)

# get usage info
memory_free=$(echo "$vmstat_mb" | awk '{print $4}'| tail -n1 | xargs)
cpu_idle=$(echo "$vmstat_mb" | tail -1 | awk '{print $15}')
cpu_kernel=$(echo "$vmstat_mb" | tail -1 | awk '{print $14}')
disk_io=$(vmstat -d | tail -1 | awk '{print $10}')
disk_available=$(df -BM / | tail -1 | awk '{print $4}' | sed 's/M//')
timestamp=$(vmstat -t | tail -1 | awk '{print $18 " " $19}')

# find matching id
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')";

# create insert statement
insert_stmt="INSERT INTO host_usage(timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available) VALUES('$timestamp', $host_id, $memory_free, $cpu_idle, $cpu_kernel, $disk_io, $disk_available);"

export PGPASSWORD=$psql_password 
#Insert
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"

#check for errors
if [ $? -eq 0 ]; then
  echo "Data inserted successfully."
else
  echo "Error inserting data."
fi
