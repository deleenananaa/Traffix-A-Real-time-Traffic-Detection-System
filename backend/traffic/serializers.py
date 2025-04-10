from rest_framework import serializers
from .models import TrafficData, Alert, Route, EmergencyVehicle
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name')

class TrafficDataSerializer(serializers.ModelSerializer):
    route_name = serializers.CharField(source='road_segment.name', read_only=True)
    
    class Meta:
        model = TrafficData
        fields = [
            'id', 'latitude', 'longitude', 
            'speed', 'vehicle_count', 'timestamp',
            'road_segment', 'route_name'
        ]

class RouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Route
        fields = [
            'id', 'name', 'description', 
            'start_latitude', 'start_longitude',
            'end_latitude', 'end_longitude',
            'waypoints', 'created_at', 'updated_at'
        ]

class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = [
            'id', 'location', 'alert_type',
            'severity', 'description', 'timestamp'
        ]

class EmergencyVehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyVehicle
        fields = [
            'id', 'vehicle_id', 'vehicle_type',
            'current_location', 'status', 'last_updated'
        ]

class TrafficConditionSerializer(serializers.Serializer):
    route_id = serializers.IntegerField()
    route_name = serializers.CharField()
    average_speed = serializers.FloatField()
    total_vehicles = serializers.IntegerField()
    congestion_level = serializers.CharField()
    last_updated = serializers.DateTimeField()
    alerts = AlertSerializer(many=True)
    traffic_segments = serializers.ListField(child=serializers.DictField()) 