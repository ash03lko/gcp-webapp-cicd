import unittest
import requests
import os

class TestDeploy(unittest.TestCase):
    def test_homepage(self):
        app_url = os.getenv('APP_URL', 'http://localhost:8080')
        response = requests.get(app_url)
        self.assertEqual(response.status_code, 200, f"Expected 200 OK but got {response.status_code}")

if __name__ == '__main__':
    unittest.main()
