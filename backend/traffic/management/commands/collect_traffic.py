from django.core.management.base import BaseCommand
from traffic.models import Route
from traffic.services.traffic_collector import TrafficCollector
import time
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Continuously collect traffic data for all routes'

    def add_arguments(self, parser):
        parser.add_argument(
            '--interval',
            type=int,
            default=300,
            help='Interval between data collection in seconds (default: 300)'
        )

    def handle(self, *args, **options):
        collector = TrafficCollector()
        interval = options['interval']

        self.stdout.write(
            self.style.SUCCESS(f'Starting traffic data collection (interval: {interval}s)')
        )

        while True:
            try:
                # Get all active routes
                routes = Route.objects.all()
                
                for route in routes:
                    try:
                        collector.collect_traffic_data(route)
                        self.stdout.write(
                            self.style.SUCCESS(
                                f'Successfully collected traffic data for route: {route.name}'
                            )
                        )
                    except Exception as e:
                        self.stdout.write(
                            self.style.ERROR(
                                f'Error collecting traffic data for route {route.name}: {str(e)}'
                            )
                        )

                time.sleep(interval)

            except KeyboardInterrupt:
                self.stdout.write(self.style.SUCCESS('Stopping traffic data collection'))
                break
            except Exception as e:
                logger.error(f"Error in traffic collection loop: {str(e)}")
                time.sleep(interval)  # Wait before retrying 