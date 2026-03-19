export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

CONF=../postgrest.conf

if [ ! -f "$CONF" ]; then
    echo "Error : file not found : $CONF" >&2
    exit 1
fi

DB_NAME=$(
  sed -nE 's/^db-uri[[:space:]]*=[[:space:]]*"?postgres:\/\/[^:"]+:[^@"\/]+@[^:"]+:[0-9]+\/([^"?]+)"?[[:space:]]*$/\1/p' \
  "$CONF"
)

if [ -z "$DB_NAME" ]; then
    echo "Error : db-uri not found or invalid in $CONF" >&2
    exit 2
fi

echo "database name: $DB_NAME"
