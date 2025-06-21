import unittest
import requests

class TestDeploy(unittest.TestCase):

    def test_homepage_pass(self):
        """Test homepage returns HTTP 200."""
        try:
            response = requests.get("http://localhost", timeout=5)
            self.assertEqual(response.status_code, 200, f"Expected 200 but got {response.status_code}")
        except Exception as e:
            self.fail(f"Request to http://localhost failed: {e}")

    def test_homepage_fail(self):
        """Intentional fail: Expect homepage not to return 404 (will fail if it's 404)."""
        try:
            response = requests.get("http://localhost", timeout=5)
            self.assertNotEqual(response.status_code, 404, "Unexpected 404 error")
        except Exception as e:
            self.fail(f"Request to http://localhost failed: {e}")

if __name__ == '__main__':
    unittest.main()

