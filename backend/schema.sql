-- Create custom types
CREATE TYPE alert_type AS ENUM ('ACCIDENT', 'CONSTRUCTION', 'ROAD_CLOSURE', 'WEATHER', 'OTHER');

-- Users and Authentication
CREATE TABLE auth_user (
    id SERIAL PRIMARY KEY,
    password VARCHAR(128) NOT NULL,
    last_login TIMESTAMP WITH TIME ZONE,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE,
    username VARCHAR(150) NOT NULL UNIQUE,
    first_name VARCHAR(150) NOT NULL DEFAULT '',
    last_name VARCHAR(150) NOT NULL DEFAULT '',
    email VARCHAR(254) NOT NULL DEFAULT '',
    is_staff BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    date_joined TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE firebase_user (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(128) NOT NULL UNIQUE,
    email VARCHAR(254) NOT NULL UNIQUE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Traffic Data Tables
CREATE TABLE route (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    start_latitude DOUBLE PRECISION NOT NULL,
    start_longitude DOUBLE PRECISION NOT NULL,
    end_latitude DOUBLE PRECISION NOT NULL,
    end_longitude DOUBLE PRECISION NOT NULL,
    waypoints JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE traffic_data (
    id SERIAL PRIMARY KEY,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    speed DOUBLE PRECISION NOT NULL,
    vehicle_count INTEGER NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    road_segment_id INTEGER NOT NULL REFERENCES route(id) ON DELETE CASCADE
);

CREATE TABLE alert (
    id SERIAL PRIMARY KEY,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    type VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    reported_by_id INTEGER REFERENCES auth_user(id) ON DELETE SET NULL
);

CREATE TABLE emergency_vehicle (
    id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(50) NOT NULL UNIQUE,
    vehicle_type VARCHAR(50) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Indexes
CREATE INDEX idx_traffic_data_timestamp ON traffic_data(timestamp DESC);
CREATE INDEX idx_traffic_data_location ON traffic_data(latitude, longitude);
CREATE INDEX idx_route_name ON route(name);
CREATE INDEX idx_alert_type ON alert(type);
CREATE INDEX idx_alert_created_at ON alert(created_at DESC);
CREATE INDEX idx_alert_location ON alert(latitude, longitude);
CREATE INDEX idx_emergency_vehicle_location ON emergency_vehicle(latitude, longitude);
CREATE INDEX idx_firebase_user_email ON firebase_user(email);
CREATE INDEX idx_firebase_user_firebase_uid ON firebase_user(firebase_uid);

-- Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_route_updated_at
    BEFORE UPDATE ON route
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_firebase_user_updated_at
    BEFORE UPDATE ON firebase_user
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column(); 