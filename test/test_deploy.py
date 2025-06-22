import unittest
import requests
import os

class TestDeploy(unittest.TestCase):

    def setUp(self):
        # Get URL from environment or default (for local testing)
        self.url = os.getenv("APP_URL", "http://localhost")

    def test_homepage_status_ok(self):
        """Check homepage returns HTTP 200"""
        try:
            response = requests.get(self.url, timeout=5)
            self.assertEqual(response.status_code, 200, f"Expected 200 but got {response.status_code}")
        except requests.RequestException as e:
            self.fail(f"Request failed: {e}")

    def test_homepage_content(self):
        """Check homepage contains expected content"""
        try:
            response = requests.get(self.url, timeout=5)
            self.assertIn("Hello", response.text, "Expected content not found on page")
        except requests.RequestException as e:
            self.fail(f"Request failed: {e}")

if __name__ == '__main__':
    unittest.main()
