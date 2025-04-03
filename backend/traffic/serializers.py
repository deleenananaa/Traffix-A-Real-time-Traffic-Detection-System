from rest_framework import serializers
from .models import TrafficData, Alert, Route, EmergencyVehicle
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name')

class TrafficDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrafficData
        fields = [
            'id', 'location', 'current_speed', 'free_flow_speed',
            'current_travel_time', 'free_flow_travel_time',
            'confidence', 'road_closure', 'timestamp'
        ]

class RouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Route
        fields = [
            'id', 'name', 'start_point', 'end_point',
            'waypoints', 'created_at', 'updated_at'
        ]

class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = [
            'id', 'location', 'alert_type', 'severity',
            'description', 'timestamp'
        ]

class EmergencyVehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyVehicle
        fields = [
            'id', 'vehicle_id', 'vehicle_type',
            'current_location', 'status', 'last_updated'
        ] 