import requests

APP_URL = "http://34.123.107.19:80/"

def test_deployment():
    try:
        response = requests.get(APP_URL)
        if response.status_code == 200:
            print("✅ Test passed: App is live!")
        else:
            print(f"❌ Test failed: Status code {response.status_code}")
            exit(1)
    except requests.exceptions.RequestException as e:
        print(f"❌ Test failed: Could not reach app. Error: {e}")
        exit(1)

if __name__ == "__main__":
    test_deployment()
