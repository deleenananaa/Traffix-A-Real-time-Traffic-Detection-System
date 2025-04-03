import requests
from django.conf import settings
from typing import Dict, List, Optional, Union
import logging

logger = logging.getLogger(__name__)

class TomTomService:
    def __init__(self):
        self.api_key = settings.TOMTOM_API_KEY
        self.base_url = settings.TOMTOM_BASE_URL

    def _make_request(self, endpoint: str, params: Dict = None) -> Dict:
        """Make a request to TomTom API"""
        if params is None:
            params = {}
        params['key'] = self.api_key

        url = f"{self.base_url}{endpoint}"
        try:
            response = requests.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"TomTom API request failed: {str(e)}")
            raise

    def get_traffic_flow(self, bbox: str, zoom: int = 10, style: str = 'relative0') -> Dict:
        """Get traffic flow data for a bounding box
        
        Args:
            bbox: Bounding box in format 'minLon,minLat,maxLon,maxLat'
            zoom: Zoom level (0-22), defaults to 10
            style: Flow style (relative0, absolute, etc.), defaults to relative0
        """
        endpoint = f"/traffic/services/4/flowSegmentData/{style}/{zoom}/json"
        try:
            coords = [float(x) for x in bbox.split(',')]
            if len(coords) != 4:
                raise ValueError("bbox must contain exactly 4 coordinates")
            
            # Create a point in the center of the bounding box
            center_lon = (coords[0] + coords[2]) / 2
            center_lat = (coords[1] + coords[3]) / 2
            
            return self._make_request(endpoint, {
                'point': f"{center_lat},{center_lon}",  # Use point instead of points
                'unit': 'KMPH',  # Use kilometers per hour for speed
                'openLr': 'false'  # Don't include OpenLR code
            })
        except (ValueError, IndexError) as e:
            logger.error(f"Invalid bbox format: {str(e)}")
            raise ValueError("bbox must be in format: lon1,lat1,lon2,lat2")

    def get_traffic_incidents(self, bbox: str) -> Dict:
        """Get traffic incidents in a bounding box"""
        endpoint = f"/traffic/services/5/incidentDetails"
        return self._make_request(endpoint, {'bbox': bbox})

    def calculate_route(
        self,
        start_point: str,
        end_point: str,
        waypoints: Optional[List[str]] = None,
        traffic: bool = True
    ) -> Dict:
        """Calculate route between points"""
        locations = [start_point]
        if waypoints:
            locations.extend(waypoints)
        locations.append(end_point)

        locations_str = ':'.join(locations)
        endpoint = f"/routing/1/calculateRoute/{locations_str}/json"
        
        params = {
            'traffic': 'true' if traffic else 'false',
            'routeType': 'fastest',
            'travelMode': 'car',
            'computeTravelTimeFor': 'all'
        }
        
        return self._make_request(endpoint, params)

    def search_location(self, query: str, lat: float = None, lon: float = None) -> Dict:
        """Search for locations"""
        endpoint = f"/search/2/search/{query}.json"
        params = {}
        
        if lat is not None and lon is not None:
            params.update({
                'lat': lat,
                'lon': lon,
                'radius': 10000
            })

        return self._make_request(endpoint, params)

    def reverse_geocode(self, lat: float, lon: float) -> Dict:
        """Convert coordinates to address"""
        endpoint = f"/search/2/reverseGeocode/{lat},{lon}.json"
        return self._make_request(endpoint)

    def get_matrix_routes(
        self,
        origins: List[str],
        destinations: List[str],
        traffic: bool = True
    ) -> Dict:
        """Calculate matrix routing between multiple origins and destinations"""
        endpoint = f"/routing/1/matrix/json"
        
        params = {
            'origins': ';'.join(origins),
            'destinations': ';'.join(destinations),
            'traffic': 'true' if traffic else 'false',
            'travelMode': 'car'
        }
        
        return self._make_request(endpoint, params)

    def get_map_tiles(self, style: str = 'main') -> str:
        """Get map tile URL"""
        return f"{self.base_url}/map/1/tile/{{z}}/{{x}}/{{y}}.png?key={self.api_key}&style={style}"

    def snap_to_roads(self, points: List[str]) -> Dict:
        """Snap points to nearest roads"""
        endpoint = f"/routing/1/snapping"
        points_str = ';'.join(points)
        return self._make_request(endpoint, {'points': points_str})

    def create_geofence(self, name: str, coordinates: List[Dict[str, float]]) -> Dict:
        """Create a geofence"""
        endpoint = f"/geofencing/1/projects/{name}/fence"
        return self._make_request(endpoint, {
            'coordinates': coordinates
        })

    def get_historical_traffic(
        self,
        bbox: str,
        start_time: str,
        end_time: str,
        time_bucket: str = "1hour"
    ) -> Dict:
        """Get historical traffic data for analysis
        
        Args:
            bbox: Bounding box coordinates
            start_time: Start time in ISO format
            end_time: End time in ISO format
            time_bucket: Time aggregation bucket (15min, 1hour, 1day)
        """
        endpoint = "/traffic/stats/1/analysis"
        params = {
            'bbox': bbox,
            'startTime': start_time,
            'endTime': end_time,
            'timeBucket': time_bucket
        }
        return self._make_request(endpoint, params)

    def create_traffic_alert(
        self,
        name: str,
        bbox: str,
        conditions: Dict[str, Union[str, float]],
        notification_url: str
    ) -> Dict:
        """Create a traffic alert for specific conditions
        
        Args:
            name: Alert name
            bbox: Bounding box to monitor
            conditions: Dictionary of conditions (e.g., {'speed_threshold': 20, 'incident_severity': 'major'})
            notification_url: Webhook URL for notifications
        """
        endpoint = "/traffic/alerts/1/create"
        params = {
            'name': name,
            'bbox': bbox,
            'conditions': conditions,
            'notificationUrl': notification_url
        }
        return self._make_request(endpoint, params)

    def delete_traffic_alert(self, alert_id: str) -> Dict:
        """Delete a traffic alert"""
        endpoint = f"/traffic/alerts/1/{alert_id}"
        return self._make_request(endpoint)

    def get_traffic_alerts(self) -> Dict:
        """Get list of active traffic alerts"""
        endpoint = "/traffic/alerts/1/list"
        return self._make_request(endpoint) 