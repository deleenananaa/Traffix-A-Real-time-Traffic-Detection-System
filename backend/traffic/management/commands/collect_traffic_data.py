import time
from django.core.management.base import BaseCommand
from traffic.services.data_collection_service import DataCollectionService
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Collects traffic data from TomTom API periodically'

    def add_arguments(self, parser):
        parser.add_argument(
            '--interval',
            type=int,
            default=300,  # 5 minutes
            help='Interval between data collection in seconds'
        )

    def handle(self, *args, **options):
        service = DataCollectionService()
        interval = options['interval']
        
        # Define monitored locations
        locations = [
            {
                'name': 'Downtown SF',
                'bbox': '-122.4194,37.7749,-122.4094,37.7849'
            },
            {
                'name': 'Golden Gate Bridge',
                'bbox': '-122.4883,37.8099,-122.4783,37.8199'
            },
            {
                'name': 'SF Airport',
                'bbox': '-122.4000,37.6100,-122.3500,37.6500'
            }
        ]
        
        self.stdout.write(self.style.SUCCESS('Starting traffic data collection...'))
        
        try:
            while True:
                service.collect_traffic_data(locations)
                self.stdout.write(self.style.SUCCESS(f'Data collection completed. Waiting {interval} seconds...'))
                time.sleep(interval)
        except KeyboardInterrupt:
            self.stdout.write(self.style.WARNING('Data collection stopped by user'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error in data collection: {str(e)}'))
            raise 