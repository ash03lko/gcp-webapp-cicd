import unittest
import requests
import os

class TestDeploy(unittest.TestCase):
    def test_homepage(self):
        # APP_URL should be set as environment variable in Cloud Build test step
        app_url = os.getenv('APP_URL')
        if not app_url:
            self.fail("APP_URL environment variable not set")

        response = requests.get(app_url)
        self.assertEqual(response.status_code, 200, f"Expected 200 OK but got {response.status_code}")

if __name__ == '__main__':
    unittest.main()
