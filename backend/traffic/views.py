from django.shortcuts import render
from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import TrafficData, Route, Alert, EmergencyVehicle
from .serializers import (
    TrafficDataSerializer,
    RouteSerializer,
    AlertSerializer,
    EmergencyVehicleSerializer,
)
from .services.osrm_service import OSRMService
from django.conf import settings
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from datetime import timedelta
from django.db.models import Avg
import firebase_admin
from firebase_admin import db

# Create your views here.

class TrafficViewSet(viewsets.ModelViewSet):
    queryset = TrafficData.objects.all()
    serializer_class = TrafficDataSerializer
    permission_classes = [permissions.AllowAny]
    osrm_service = OSRMService()

    @action(detail=False, methods=['get'])
    def flow(self, request):
        """Get traffic flow data for a bounding box"""
        bbox = request.query_params.get('bbox')
        zoom = request.query_params.get('zoom', 13)
        
        if not bbox:
            return Response(
                {'error': 'bbox parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            zoom = int(zoom)
            if not 0 <= zoom <= 22:
                return Response(
                    {'error': 'zoom must be between 0 and 22'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            data = self.osrm_service.get_traffic_flow(bbox, zoom=zoom)
            return Response(data)
        except ValueError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def sync_with_firebase(self, request):
        """Manually trigger Firebase synchronization"""
        try:
            self.osrm_service.sync_traffic_data()
            return Response({'status': 'success'})
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class RouteViewSet(viewsets.ModelViewSet):
    queryset = Route.objects.all()
    serializer_class = RouteSerializer
    permission_classes = [permissions.AllowAny]
    osrm_service = OSRMService()

    @action(detail=False, methods=['post'])
    def calculate(self, request):
        """Calculate route between points"""
        start = request.data.get('start')
        end = request.data.get('end')
        waypoints = request.data.get('waypoints', [])
        
        if not start or not end:
            return Response(
                {'error': 'start and end points are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            data = self.osrm_service.calculate_route(start, end, waypoints)
            return Response(data)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def alternatives(self, request):
        """Get alternative routes avoiding congested areas"""
        start = request.data.get('start')
        end = request.data.get('end')
        max_alternatives = request.data.get('max_alternatives', 3)
        
        if not start or not end:
            return Response(
                {'error': 'start and end points are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            routes = self.osrm_service.get_alternative_routes(
                start,
                end,
                max_alternatives
            )
            return Response({'routes': routes})
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class LocationViewSet(viewsets.ViewSet):
    permission_classes = [permissions.AllowAny]
    osrm_service = OSRMService()

    @action(detail=False, methods=['get'])
    def search(self, request):
        """Search for locations"""
        query = request.query_params.get('query')
        lat = request.query_params.get('lat')
        lon = request.query_params.get('lon')
        
        if not query:
            return Response(
                {'error': 'query parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            data = self.osrm_service.search_location(
                query,
                float(lat) if lat else None,
                float(lon) if lon else None
            )
            return Response(data)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def reverse_geocode(self, request):
        """Convert coordinates to address"""
        lat = request.query_params.get('lat')
        lon = request.query_params.get('lon')
        
        if not lat or not lon:
            return Response(
                {'error': 'lat and lon parameters are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            data = self.osrm_service.reverse_geocode(float(lat), float(lon))
            return Response(data)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class TrafficDataViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for traffic data
    """
    queryset = TrafficData.objects.all().order_by('-timestamp')
    serializer_class = TrafficDataSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['location', 'road_closure']
    ordering_fields = ['timestamp', 'current_speed', 'free_flow_speed']
    osrm_service = OSRMService()

    @action(detail=False, methods=['get'])
    def current_conditions(self, request):
        """Get current traffic conditions for all monitored locations"""
        locations = TrafficData.objects.values('location').distinct()
        conditions = {}
        
        for loc in locations:
            latest = TrafficData.objects.filter(
                location=loc['location']
            ).order_by('-timestamp').first()
            
            if latest:
                conditions[loc['location']] = {
                    'current_speed': latest.current_speed,
                    'free_flow_speed': latest.free_flow_speed,
                    'density': self.osrm_service._calculate_density(
                        latest.current_speed,
                        latest.free_flow_speed
                    ),
                    'congestion_level': self.osrm_service._get_congestion_level(
                        latest.current_speed,
                        latest.free_flow_speed
                    ),
                    'road_closure': latest.road_closure,
                    'timestamp': latest.timestamp
                }
        
        return Response(conditions)

    @action(detail=False, methods=['get'])
    def historical_analysis(self, request):
        """Get historical traffic analysis for the past 24 hours"""
        time_threshold = timezone.now() - timedelta(hours=24)
        locations = TrafficData.objects.values('location').distinct()
        analysis = {}
        
        for loc in locations:
            data = TrafficData.objects.filter(
                location=loc['location'],
                timestamp__gte=time_threshold
            ).aggregate(
                avg_speed=Avg('current_speed'),
                avg_travel_time=Avg('current_travel_time')
            )
            
            if data['avg_speed']:
                analysis[loc['location']] = {
                    'average_speed': round(data['avg_speed'], 2),
                    'average_travel_time': round(data['avg_travel_time'], 2) if data['avg_travel_time'] else 0,
                    'average_density': self.osrm_service._calculate_density(
                        data['avg_speed'],
                        TrafficData.objects.filter(
                            location=loc['location']
                        ).first().free_flow_speed
                    )
                }
        
        return Response(analysis)

class AlertViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for traffic alerts
    """
    queryset = Alert.objects.all().order_by('-timestamp')
    serializer_class = AlertSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['location', 'alert_type', 'severity']
    ordering_fields = ['timestamp']

    @action(detail=False, methods=['get'])
    def active_alerts(self, request):
        """Get active alerts from the last hour"""
        time_threshold = timezone.now() - timedelta(hours=1)
        alerts = Alert.objects.filter(
            timestamp__gte=time_threshold
        ).order_by('-timestamp')
        
        serializer = self.get_serializer(alerts, many=True)
        return Response(serializer.data)

class EmergencyVehicleViewSet(viewsets.ModelViewSet):
    """
    API endpoint for emergency vehicles
    """
    queryset = EmergencyVehicle.objects.all().order_by('-last_updated')
    serializer_class = EmergencyVehicleSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['vehicle_type', 'status']
    ordering_fields = ['last_updated']

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active emergency vehicles"""
        active_vehicles = self.get_queryset().filter(status='active')
        serializer = self.get_serializer(active_vehicles, many=True)
        return Response(serializer.data)
