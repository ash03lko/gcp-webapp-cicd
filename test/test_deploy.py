import requests

APP_URL = "http://YOUR_VM_EXTERNAL_IP:8080/"

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
