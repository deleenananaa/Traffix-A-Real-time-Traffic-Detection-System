from django.db import models
from django.conf import settings
from django.contrib.auth.models import User

class Route(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    start_latitude = models.FloatField()
    start_longitude = models.FloatField()
    end_latitude = models.FloatField()
    end_longitude = models.FloatField()
    waypoints = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class TrafficData(models.Model):
    latitude = models.FloatField()
    longitude = models.FloatField()
    speed = models.FloatField()
    vehicle_count = models.IntegerField()
    timestamp = models.DateTimeField()
    road_segment = models.ForeignKey(Route, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.latitude},{self.longitude} - {self.timestamp}"

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
