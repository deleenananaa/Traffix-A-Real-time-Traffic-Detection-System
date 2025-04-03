import unittest
from django.test import TestCase
from traffic.services.tomtom_service import TomTomService
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TestTomTomService(TestCase):
    def setUp(self):
        self.tomtom = TomTomService()
        # Test area: San Francisco downtown area
        self.test_bbox = "-122.4194,37.7749,-122.4094,37.7849"
        
    def test_get_traffic_flow(self):
        """Test traffic flow data retrieval"""
        logger.info("Testing traffic flow endpoint...")
        try:
            response = self.tomtom.get_traffic_flow(self.test_bbox)
            logger.info(f"Traffic Flow Response: {response}")
            self.assertIsInstance(response, dict)
            self.assertIn('flowSegmentData', response)
        except Exception as e:
            logger.error(f"Traffic Flow Error: {str(e)}")
            raise

    def test_get_traffic_incidents(self):
        """Test traffic incidents data retrieval"""
        logger.info("Testing traffic incidents endpoint...")
        try:
            response = self.tomtom.get_traffic_incidents(self.test_bbox)
            logger.info(f"Traffic Incidents Response: {response}")
            self.assertIsInstance(response, dict)
            self.assertIn('incidents', response)
        except Exception as e:
            logger.error(f"Traffic Incidents Error: {str(e)}")
            raise

    def test_calculate_route(self):
        """Test route calculation"""
        logger.info("Testing route endpoint...")
        try:
            # Test route from SF Downtown to Golden Gate Bridge
            start = "37.7749,-122.4194"  # SF Downtown
            end = "37.8199,-122.4783"    # Golden Gate Bridge
            response = self.tomtom.calculate_route(start, end)
            logger.info(f"Route Response: {response}")
            self.assertIsInstance(response, dict)
            self.assertIn('routes', response)
        except Exception as e:
            logger.error(f"Route Error: {str(e)}")
            raise

if __name__ == '__main__':
    unittest.main() 