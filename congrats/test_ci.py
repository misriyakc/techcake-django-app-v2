from django.test import TestCase


class DeliberatelyFailingTest(TestCase):
    def test_ci_pipeline_failure_demo(self):
        self.assertEqual(1, 2)
