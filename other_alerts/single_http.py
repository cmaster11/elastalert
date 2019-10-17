import json
import requests
from requests import RequestException
from elastalert.alerts import Alerter, DateTimeEncoder
from elastalert.util import EAException, elastalert_logger, lookup_es_key


class HTTPSinglePostAlerter(Alerter):
    """ Sends grouped matches by HTTP POST. Encoded with JSON. """

    def __init__(self, rule):
        super(HTTPSinglePostAlerter, self).__init__(rule)
        post_url = self.rule.get('http_single_post_url')
        if isinstance(post_url, str):
            post_url = [post_url]
        self.post_url = post_url
        self.post_proxy = self.rule.get('http_single_post_proxy')
        self.post_payload = self.rule.get('http_single_post_payload', {})
        self.post_static_payload = self.rule.get('http_single_post_static_payload', {})
        self.post_all_values = self.rule.get('http_single_post_all_values', not self.post_payload)
        self.post_http_headers = self.rule.get('http_single_post_headers', {})
        self.timeout = self.rule.get('http_single_post_timeout', 10)

    def alert(self, matches):
        """ Will trigger a POST to the specified endpoint(s) containing all matches. """

        matches_payloads = []

        for match in matches:
            match_payload = match if self.post_all_values else {}
            match_payload.update(self.post_static_payload)
            for post_key, es_key in list(self.post_payload.items()):
                match_payload[post_key] = lookup_es_key(match, es_key)

            matches_payloads.append(match_payload)

        payload = {
            'rule': self.rule['name'],
            'title': self.create_title(matches),
            'body': self.create_alert_body(matches),
            'matches': matches_payloads,
        }

        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json;charset=utf-8"
        }
        headers.update(self.post_http_headers)
        proxies = {'https': self.post_proxy} if self.post_proxy else None
        for url in self.post_url:
            try:
                response = requests.post(url, data=json.dumps(payload, cls=DateTimeEncoder),
                                         headers=headers, proxies=proxies, timeout=self.timeout)
                response.raise_for_status()
            except RequestException as e:
                raise EAException("Error posting HTTP Post alert: %s" % e)
        elastalert_logger.info("HTTP Post alert sent.")

    def get_info(self):
        return {'type': 'http_single_post',
                'http_single_post_webhook_url': self.post_url}
