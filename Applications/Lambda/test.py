from main import handler, handler2
import json

a = {"requestContext": {"identity": {"sourceIp": "192.158.125", "userAgent": "chrome"}}}


def test_handler():
    json_data = handler(a, None)
    assert type(json_data) is dict
    assert 'user_ip' in json_data['body']
    assert 'user_agent' in json_data['body']
    assert 'req_time' in json_data['body']


def test_handler2():
    json_data = handler2(None, None)
    assert type(json_data) is dict
    assert 'user_ip' in json_data['body']
    assert 'user_agent' in json_data['body']
    assert 'req_time' in json_data['body']
