from datetime import datetime
import logging
from django.conf import settings
from traffic.models import TrafficData, Alert
from traffic.services.tomtom_service import TomTomService
from django.db import transaction
from typing import Dict, List

logger = logging.getLogger(__name__)

class DataCollectionService:
    def __init__(self):
        self.tomtom_service = TomTomService()
        
    def _process_traffic_flow(self, flow_data: Dict, location: str) -> None:
        """Process and store traffic flow data"""
        try:
            with transaction.atomic():
                flow_segment = flow_data.get('flowSegmentData', {})
                traffic_data = TrafficData(
                    location=location,
                    current_speed=flow_segment.get('currentSpeed'),
                    free_flow_speed=flow_segment.get('freeFlowSpeed'),
                    current_travel_time=flow_segment.get('currentTravelTime'),
                    free_flow_travel_time=flow_segment.get('freeFlowTravelTime'),
                    confidence=flow_segment.get('confidence'),
                    road_closure=flow_segment.get('roadClosure', False),
                    timestamp=datetime.now()
                )
                traffic_data.save()
                
                # Check for significant slowdowns and create alerts
                if (traffic_data.current_speed and traffic_data.free_flow_speed and 
                    traffic_data.current_speed < traffic_data.free_flow_speed * 0.6):  # 40% slower than normal
                    Alert.objects.create(
                        location=location,
                        alert_type='CONGESTION',
                        severity='HIGH',
                        description=f'Traffic speed reduced to {traffic_data.current_speed} km/h (normal: {traffic_data.free_flow_speed} km/h)',
                        timestamp=datetime.now()
                    )
        except Exception as e:
            logger.error(f"Error processing traffic flow data: {str(e)}")
            raise

    def _process_incidents(self, incident_data: Dict, location: str) -> None:
        """Process and store traffic incidents"""
        try:
            incidents = incident_data.get('incidents', [])
            for incident in incidents:
                Alert.objects.create(
                    location=location,
                    alert_type='INCIDENT',
                    severity=incident.get('severity', 'MEDIUM'),
                    description=incident.get('description', 'No description available'),
                    timestamp=datetime.now()
                )
        except Exception as e:
            logger.error(f"Error processing traffic incidents: {str(e)}")
            raise

    def collect_traffic_data(self, locations: List[Dict[str, str]]) -> None:
        """
        Collect traffic data for specified locations
        
        Args:
            locations: List of dictionaries containing location info
                      [{'name': 'Downtown SF', 'bbox': 'minLon,minLat,maxLon,maxLat'}]
        """
        for location in locations:
            try:
                # Get traffic flow data
                flow_data = self.tomtom_service.get_traffic_flow(location['bbox'])
                self._process_traffic_flow(flow_data, location['name'])
                
                # Get traffic incidents
                incident_data = self.tomtom_service.get_traffic_incidents(location['bbox'])
                self._process_incidents(incident_data, location['name'])
                
                logger.info(f"Successfully collected traffic data for {location['name']}")
            except Exception as e:
                logger.error(f"Error collecting traffic data for {location['name']}: {str(e)}")
                continue  # Continue with next location even if one fails