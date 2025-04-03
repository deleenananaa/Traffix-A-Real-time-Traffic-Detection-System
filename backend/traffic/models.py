from django.db import models
from django.conf import settings
from django.contrib.auth.models import User

class TrafficData(models.Model):
    location = models.CharField(max_length=255, default='unknown')
    current_speed = models.FloatField(null=True)
    free_flow_speed = models.FloatField(null=True)
    current_travel_time = models.IntegerField(null=True)
    free_flow_travel_time = models.IntegerField(null=True)
    confidence = models.FloatField(null=True)
    road_closure = models.BooleanField(default=False)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.location} - {self.timestamp}"

class Route(models.Model):
    name = models.CharField(max_length=255)
    start_point = models.CharField(max_length=255, default='0,0')
    end_point = models.CharField(max_length=255, default='0,0')
    waypoints = models.JSONField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Alert(models.Model):
    SEVERITY_CHOICES = [
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
    ]
    
    ALERT_TYPES = [
        ('CONGESTION', 'Traffic Congestion'),
        ('INCIDENT', 'Traffic Incident'),
        ('CLOSURE', 'Road Closure'),
    ]

    location = models.CharField(max_length=255, default='Unknown')
    alert_type = models.CharField(max_length=20, choices=ALERT_TYPES, default='CONGESTION')
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='MEDIUM')
    description = models.TextField(default='No description provided')
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.alert_type} - {self.location} ({self.severity})"

class EmergencyVehicle(models.Model):
    vehicle_id = models.CharField(max_length=50, unique=True)
    vehicle_type = models.CharField(max_length=50, default='unknown')
    current_location = models.CharField(max_length=255, default='unknown')
    status = models.CharField(max_length=50, default='inactive')
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.vehicle_type} - {self.vehicle_id}"

class FirebaseUser(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    firebase_uid = models.CharField(max_length=128, unique=True)
    email = models.EmailField(unique=True)
    email_verified = models.BooleanField(default=False)
    last_login = models.DateTimeField(null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.email} - {self.firebase_uid}"
