#!/usr/bin/env bash
set -e
# echo "curl.sh PARAMS: $@"

# Defaults for parameters
METHOD=post
EXTRACMD=
JQ_QUERY=
MESSAGE=
HEADERS=
USER=
URL=

for i in "$@"
do
case $i in
  --user=*)
    USER="${i#*=}"
    shift # past argument=value
  ;;
  -endpoint=*|--endpoint=*)
    ENDPOINT="${i#*=}"
    shift # past argument=value
  ;;
  --message=*)
    MESSAGE="${i#*=}"
    shift # past argument=value
  ;;
  -h=*|--headers=*)
    HEADERS="${i#*=}"
    shift # past argument=value
  ;;
  -m=*|--method=*)
    METHOD="${i#*=}"
    shift # past argument=value
  ;;
  --url=*)
    URL="${i#*=}"
    shift # past argument=value
  ;;
  -jq=*|--jq=*)
    JQ_QUERY="${i#*=}"
    shift # past argument=value
  ;;
  -cmd=*|--cmd=*)
    EXTRACMD="${i#*=}"
    shift # past argument=value
  ;;
  *)
  # unknown option
  ;;
esac
done

# reusable functions
die() { (echo ""; echo "[`date`] ERROR: ./curl.sh '$ENDPOINT': $@" >&2 ); exit 1; } 
out() { echo [`date`] $@; }

# validating arguments
if ! [ "$URL" ]; then die "Expected URL"; fi
if ! [ "$ENDPOINT" ]; then die "Expected endpoint"; fi
if ! [ "$METHOD" ]; then die "Expected METHOD"; fi

# starting
[[ "$MESSAGE" != "" ]] && (out $MESSAGE)

# prepare request
echo "$HEADERS" | sed -e $'s/,/\\\n/g' > /curl/output/curl_headers
cat /dev/stdin > /curl/output/curl_request
# delete temp body storage - if it was there
find -wholename "/curl/output/$ENDPOINT" -exec rm {} \;
find -wholename "/curl/output/$ENDPOINT.out" -exec rm {} \;

echo "================= core $METHOD start: ==================="
echo "== URL:     $URL"
echo "== USER:    $USER"
echo "== JQ:      $JQ_QUERY"
echo "== HEADERS: `cat /curl/output/curl_headers`"
echo "== REQUEST: `cat /curl/output/curl_request`"

AUTH=
if [ "$USER" != "" ]; then AUTH="--user $USER"; fi
CMD="curl -w %{http_code} -s -v $AUTH -H @/curl/output/curl_headers -o /curl/output/$ENDPOINT $URL $EXTRACMD"
if [[ "${METHOD^^}" == "POST" ]]; then
  if [ -s "/curl/output/curl_request" ]; then CMD="$CMD -d @/curl/output/curl_request"; fi
fi
echo "== COMMAND: $CMD"

code=0
statuscode=$($CMD) || code=$?
export LAST_HTTP_CODE=$(echo $statuscode | awk '{print substr($0,0,4)}')
export LAST_HTTP_BODY=$(cat /curl/output/$ENDPOINT)
echo "== cUrl ExitCode: $code"
echo "== cUrl StatusCode: $statuscode"
echo "== cUrl LAST_HTTP_CODE: $LAST_HTTP_CODE"
echo "== cUrl body saved: /curl/output/$ENDPOINT"

# # Run curl in a separate command, capturing output of -w "%{http_code}" into statuscode
# # and sending the content to a file with -o >(cat >/curl/output/$ENDPOINT)
if [ "$code" != "0" ]; then
  echo "== CORE REQUEST FAILURE. LAST RESPONSE:"
  cat /curl/output/$ENDPOINT
  die "HTTP request failed ($LAST_HTTP_CODE) in response from $ENDPOINT"
fi

if ! [[ "$LAST_HTTP_CODE" =~ ^2 ]]; then
  echo "== CORE POST FAILURE. LAST RESPONSE:"
  cat /curl/output/$ENDPOINT
  die "HTTP request failed ($LAST_HTTP_CODE) in response from $ENDPOINT"
fi

if [[ "$JQ_QUERY" != ""  ]]; then
  cat /curl/output/$ENDPOINT | jq -r $JQ_QUERY > "/curl/output/$ENDPOINT.out"
  export JQ_RESULT=$(cat /curl/output/$ENDPOINT.out)
  if [ "$JQ_RESULT" == "" ]; then
    die "Expected \"$JQ_QUERY\" in response from $ENDPOINT"
  fi
  if [ "${JQ_RESULT^^}" == "NULL" ]; then
    die "Result of \"$JQ_QUERY\" should not be NULL in response from $ENDPOINT"
  fi
  out "JQ RESULT: $JQ_RESULT"
fi