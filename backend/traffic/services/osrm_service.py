import requests
from typing import List, Dict, Any, Optional
from django.conf import settings
import json
from datetime import datetime
import firebase_admin
from firebase_admin import db
from ..models import TrafficData, Alert

class OSRMService:
    OSRM_BASE_URL = 'http://router.project-osrm.org'
    NOMINATIM_BASE_URL = 'https://nominatim.openstreetmap.org'
    
    def __init__(self):
        self.db_ref = None
        self._initialize_firebase()

    def _initialize_firebase(self):
        """Initialize Firebase connection if credentials are available"""
        try:
            if not firebase_admin._apps and hasattr(settings, 'FIREBASE_ADMIN_CERT'):
                cred = firebase_admin.credentials.Certificate(
                    settings.FIREBASE_ADMIN_CERT
                )
                if hasattr(settings, 'FIREBASE_DATABASE_URL'):
                    firebase_admin.initialize_app(cred, {
                        'databaseURL': settings.FIREBASE_DATABASE_URL
                    })
                    self.db_ref = db.reference('traffic')
        except (ValueError, FileNotFoundError) as e:
            print(f"Firebase initialization skipped: {str(e)}")

    def get_traffic_flow(self, bbox: str, zoom: int = 13) -> Dict[str, Any]:
        """
        Get traffic flow data for a bounding box using historical and real-time data
        bbox format: "minLon,minLat,maxLon,maxLat"
        """
        # Get traffic data from our database
        bounds = [float(x) for x in bbox.split(',')]
        traffic_data = TrafficData.objects.filter(
            location__contains=f"{bounds[1]},{bounds[0]}"
        ).order_by('-timestamp')[:100]

        # Calculate traffic density for each road segment
        flow_data = {}
        for data in traffic_data:
            loc = data.location
            if loc not in flow_data:
                flow_data[loc] = {
                    'current_speed': data.current_speed,
                    'free_flow_speed': data.free_flow_speed,
                    'density': self._calculate_density(
                        data.current_speed,
                        data.free_flow_speed
                    ),
                    'confidence': data.confidence
                }

        return {
            'flowSegmentData': flow_data,
            'timestamp': datetime.now().isoformat()
        }

    def _calculate_density(
        self,
        current_speed: Optional[float],
        free_flow_speed: Optional[float]
    ) -> float:
        """Calculate traffic density (0-1 scale)"""
        if not current_speed or not free_flow_speed or free_flow_speed == 0:
            return 0.0
        
        density = (free_flow_speed - current_speed) / free_flow_speed
        return min(max(density, 0.0), 1.0)

    def calculate_route(
        self,
        start: str,
        end: str,
        waypoints: List[str] = None
    ) -> Dict[str, Any]:
        """
        Calculate route between points using OSRM
        Points format: "lat,lon"
        """
        # Convert coordinates to lon,lat format for OSRM
        coords = [self._convert_coords(start)]
        if waypoints:
            coords.extend([self._convert_coords(wp) for wp in waypoints])
        coords.append(self._convert_coords(end))

        # Build coordinates string
        coords_str = ';'.join([f"{c[0]},{c[1]}" for c in coords])
        
        # Make request to OSRM
        url = f"{self.OSRM_BASE_URL}/route/v1/driving/{coords_str}"
        params = {
            'overview': 'full',
            'alternatives': 'true',
            'steps': 'true',
            'annotations': 'true'
        }
        
        response = requests.get(url, params=params)
        if response.status_code != 200:
            raise Exception(f"OSRM route calculation failed: {response.text}")

        return response.json()

    def _convert_coords(self, coord_str: str) -> List[float]:
        """Convert lat,lon to lon,lat format"""
        lat, lon = map(float, coord_str.split(','))
        return [lon, lat]

    def sync_traffic_data(self) -> None:
        """Sync traffic data with Firebase"""
        if not self.db_ref:
            print("Firebase not initialized, skipping sync")
            return

        # Get latest traffic data
        latest_data = TrafficData.objects.order_by('-timestamp')[:100]
        
        # Convert to Firebase format
        firebase_data = {}
        for data in latest_data:
            key = data.location.replace(',', '_')
            firebase_data[key] = {
                'latitude': float(data.location.split(',')[0]),
                'longitude': float(data.location.split(',')[1]),
                'density': self._calculate_density(
                    data.current_speed,
                    data.free_flow_speed
                ),
                'congestion_level': self._get_congestion_level(
                    data.current_speed,
                    data.free_flow_speed
                ),
                'timestamp': int(data.timestamp.timestamp() * 1000)
            }
        
        # Update Firebase
        self.db_ref.update(firebase_data)

    def _get_congestion_level(
        self,
        current_speed: Optional[float],
        free_flow_speed: Optional[float]
    ) -> str:
        """Get congestion level based on density"""
        density = self._calculate_density(current_speed, free_flow_speed)
        if density < 0.3:
            return 'low'
        elif density < 0.7:
            return 'medium'
        return 'high'

    def get_alternative_routes(
        self,
        start: str,
        end: str,
        max_alternatives: int = 3
    ) -> List[Dict[str, Any]]:
        """Get alternative routes avoiding congested areas"""
        # Get base route
        base_route = self.calculate_route(start, end)
        routes = [base_route['routes'][0]]

        # Get traffic data along the route
        coords = self._decode_polyline(base_route['routes'][0]['geometry'])
        congested_segments = self._find_congested_segments(coords)

        # Calculate alternative routes avoiding congested segments
        for segment in congested_segments[:max_alternatives - 1]:
            # Add waypoint to avoid congested segment
            mid_lat = (segment[0][0] + segment[1][0]) / 2
            mid_lon = (segment[0][1] + segment[1][1]) / 2
            
            # Calculate route with waypoint
            alt_route = self.calculate_route(
                start,
                end,
                [f"{mid_lat + 0.01},{mid_lon + 0.01}"]  # Offset to avoid segment
            )
            if 'routes' in alt_route and alt_route['routes']:
                routes.append(alt_route['routes'][0])

        return routes

    def _decode_polyline(self, polyline: str) -> List[List[float]]:
        """Decode Google polyline format"""
        coords = []
        index = 0
        lat = 0
        lng = 0
        
        while index < len(polyline):
            result = 1
            shift = 0
            while True:
                b = ord(polyline[index]) - 63 - 1
                index += 1
                result += b << shift
                shift += 5
                if b < 0x1f:
                    break
            lat += (~result >> 1) if (result & 1) != 0 else (result >> 1)
            
            result = 1
            shift = 0
            while True:
                b = ord(polyline[index]) - 63 - 1
                index += 1
                result += b << shift
                shift += 5
                if b < 0x1f:
                    break
            lng += (~result >> 1) if (result & 1) != 0 else (result >> 1)
            
            coords.append([lat * 1e-5, lng * 1e-5])
        
        return coords

    def _find_congested_segments(
        self,
        coords: List[List[float]]
    ) -> List[List[List[float]]]:
        """Find congested segments along a route"""
        congested_segments = []
        
        for i in range(len(coords) - 1):
            # Get traffic data for segment
            lat1, lon1 = coords[i]
            lat2, lon2 = coords[i + 1]
            
            traffic_data = TrafficData.objects.filter(
                location__in=[
                    f"{lat1},{lon1}",
                    f"{lat2},{lon2}"
                ]
            ).order_by('-timestamp').first()
            
            if traffic_data and self._calculate_density(
                traffic_data.current_speed,
                traffic_data.free_flow_speed
            ) > 0.7:  # High congestion threshold
                congested_segments.append([coords[i], coords[i + 1]])
        
        return congested_segments 