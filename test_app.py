import unittest
from app import app


class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_home(self):
        response = self.client.get("/")
        print(response.data.decode("utf-8"))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode("utf-8"), "Hello from Flask - Release v3")

    def test_health(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode("utf-8"), "OK")

    def test_exam(self):
        response = self.client.get("/exam")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode("utf-8"), "This is an exam endpoint")


if __name__ == "__main__":
    unittest.main()
