import pymysql, sys, logging, datetime, json
from os import getenv

rds_host = getenv('DB_HOST')
username = getenv('DB_USER')
password = getenv('DB_PASS')
dbname = getenv('DB_NAME')
logger = logging.getLogger()
logger.setLevel(logging.INFO)
try:
    conn = pymysql.connect(rds_host, user=username,
                           passwd=password, db=dbname, connect_timeout=5, autocommit=True)
except:
    logger.error("ERROR: Could not connect to MySql instance.")
    sys.exit()

logger.info("SUCCESS: Connection to RDS mysql instance succeeded")

resp = dict()
resp['headers'] = {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
resp['statusCode'] = 200


def handler(event, context):
    req_time = str(datetime.datetime.now())
    user_ip = event['requestContext']['identity']['sourceIp']
    user_agent = event['requestContext']['identity']['userAgent']
    with conn.cursor() as cur:
        cur.execute("INSERT INTO Connections (User_ip,User_agent,Request_date) VALUES (%s,%s,%s)",
                    (user_ip, user_agent, req_time))
    rs = {"user_ip": user_ip, "user_agent": user_agent, "req_time": req_time}
    resp['body'] = json.dumps(rs)
    return resp


def handler2(event, context):
    result = []
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM Connections")
        for row in cur.fetchall():
            rs = {"id": row[0], "user_ip": row[1], "user_agent": row[2], "req_time": str(row[3])}
            result.append(rs)
    resp['body'] = json.dumps(result)
    return resp
