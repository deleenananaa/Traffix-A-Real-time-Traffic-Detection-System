import requests
from datetime import datetime
from django.conf import settings
from ..models import TrafficData, Route, Alert
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)

class TrafficCollector:
    def __init__(self):
        self.api_key = settings.TOMTOM_API_KEY
        self.base_url = settings.TOMTOM_BASE_URL
        self.api_version = settings.TOMTOM_API_VERSION

    def collect_traffic_data(self, route: Route) -> None:
        """
        Collect real-time traffic data for a specific route
        """
        try:
            # Create bounding box around route
            min_lat = min(route.start_latitude, route.end_latitude)
            max_lat = max(route.start_latitude, route.end_latitude)
            min_lon = min(route.start_longitude, route.end_longitude)
            max_lon = max(route.start_longitude, route.end_longitude)

            # Add some padding to the bounding box
            padding = 0.01  # Approximately 1km
            bbox = f"{min_lon-padding},{min_lat-padding},{max_lon+padding},{max_lat+padding}"

            # Call TomTom Traffic API
            url = f"{self.base_url}/traffic/services/{self.api_version}/flowSegmentData/relative/10/json"
            params = {
                'key': self.api_key,
                'bbox': bbox,
                'unit': 'MPH'
            }
            
            response = requests.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            # Process and save traffic data
            if 'flowSegmentData' in data:
                for segment in data['flowSegmentData']:
                    TrafficData.objects.create(
                        road_segment=route,
                        latitude=segment['coordinates']['latitude'],
                        longitude=segment['coordinates']['longitude'],
                        speed=segment.get('currentSpeed', 0),
                        vehicle_count=segment.get('vehicleCount', 0),
                        timestamp=timezone.now()
                    )

                    # Check for congestion and create alerts if needed
                    self._check_congestion(segment, route)

        except Exception as e:
            logger.error(f"Error collecting traffic data for route {route.name}: {str(e)}")
            raise

    def _check_congestion(self, segment: dict, route: Route) -> None:
        """
        Check for congestion and create alerts if needed
        """
        try:
            current_speed = segment.get('currentSpeed', 0)
            free_flow_speed = segment.get('freeFlowSpeed', 0)

            if free_flow_speed > 0:
                congestion_ratio = current_speed / free_flow_speed
                
                # Define congestion thresholds
                if congestion_ratio < 0.5:  # Severe congestion
                    severity = 'HIGH'
                elif congestion_ratio < 0.7:  # Moderate congestion
                    severity = 'MEDIUM'
                else:
                    return  # No significant congestion

                # Create or update alert
                Alert.objects.create(
                    location=f"{segment['coordinates']['latitude']},{segment['coordinates']['longitude']}",
                    alert_type='CONGESTION',
                    severity=severity,
                    description=f"Traffic congestion detected on {route.name}. "
                              f"Current speed: {current_speed:.1f} MPH "
                              f"(Normal speed: {free_flow_speed:.1f} MPH)"
                )

        except Exception as e:
            logger.error(f"Error checking congestion: {str(e)}") 