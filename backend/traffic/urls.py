from django.urls import path, include
from rest_framework.routers import DefaultRouter
from traffic import views

router = DefaultRouter()
router.register(r'traffic-data', views.TrafficDataViewSet)
router.register(r'routes', views.RouteViewSet)
router.register(r'alerts', views.AlertViewSet)
router.register(r'emergency-vehicles', views.EmergencyVehicleViewSet)

urlpatterns = [
    path('', include(router.urls)),
] 