from main import handler, handler2
import json




def test_handler():
    a = {"requestContext": {"identity": {"sourceIp": "192.158.125", "userAgent": "chrome"}}}
    json_data = json.loads(handler(a, None))
    assert 'user_ip' in json_data
    assert type(json_data['user_ip']) is str
    assert 'user_agent' in json_data
    assert type(json_data['user_agent']) is str
    assert 'req_time' in json_data
    assert type(json_data['req_time']) is str


def test_handler2():
    json_data = json.loads(handler2(None, None))
    assert type(json_data) is list
