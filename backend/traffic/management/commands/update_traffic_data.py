from django.core.management.base import BaseCommand
from django.utils import timezone
from traffic.models import TrafficData
from traffic.services.osrm_service import OSRMService
import time
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Update traffic data and sync with Firebase'

    def __init__(self):
        super().__init__()
        self.osrm_service = OSRMService()

    def add_arguments(self, parser):
        parser.add_argument(
            '--interval',
            type=int,
            default=300,  # 5 minutes
            help='Update interval in seconds'
        )
        parser.add_argument(
            '--bbox',
            type=str,
            default='85.2443,27.6258,85.5419,27.8075',  # Kathmandu Valley
            help='Bounding box for data collection (minLon,minLat,maxLon,maxLat)'
        )

    def handle(self, *args, **options):
        interval = options['interval']
        bbox = options['bbox']

        self.stdout.write(
            self.style.SUCCESS('Starting traffic data update service...')
        )

        while True:
            try:
                self._update_traffic_data(bbox)
                self.osrm_service.sync_traffic_data()
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully updated traffic data at {timezone.now()}'
                    )
                )
            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f'Error updating traffic data: {str(e)}')
                )
                logger.error(f'Traffic data update error: {str(e)}')

            time.sleep(interval)

    def _update_traffic_data(self, bbox):
        """Update traffic data for the specified bounding box"""
        # Split bbox into coordinates
        min_lon, min_lat, max_lon, max_lat = map(float, bbox.split(','))
        
        # Create a grid of points to collect data from
        lat_step = 0.005  # ~500m
        lon_step = 0.005
        
        current_time = timezone.now()
        
        for lat in self._frange(min_lat, max_lat, lat_step):
            for lon in self._frange(min_lon, max_lon, lon_step):
                location = f"{lat},{lon}"
                
                # Calculate simulated traffic data based on time of day
                hour = current_time.hour
                base_speed = 40.0  # Base speed in km/h
                
                # Simulate rush hours (7-10 AM and 4-7 PM)
                if (7 <= hour < 10) or (16 <= hour < 19):
                    current_speed = base_speed * (0.4 + 0.3 * self._random_factor())
                else:
                    current_speed = base_speed * (0.8 + 0.2 * self._random_factor())
                
                # Create or update traffic data
                TrafficData.objects.create(
                    location=location,
                    current_speed=current_speed,
                    free_flow_speed=base_speed,
                    current_travel_time=int(3600 * (base_speed / current_speed)),
                    free_flow_travel_time=3600,
                    confidence=0.85 + 0.15 * self._random_factor(),
                    road_closure=False,
                    timestamp=current_time
                )

    def _frange(self, start, stop, step):
        """Generate a range of floats"""
        i = start
        while i < stop:
            yield i
            i += step

    def _random_factor(self):
        """Generate a random factor between 0 and 1"""
        import random
        return random.random() 