CREATE DATABASE IF NOT EXISTS recommendations;
USE recommendations;

CREATE TABLE recommendations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    seed_tracks TEXT NOT NULL,
    market VARCHAR(255),
    min_energy FLOAT,
    max_energy FLOAT,
    target_popularity INT,
    target_acousticness FLOAT,
    target_instrumentalness FLOAT,
    target_tempo INT,
    song_title VARCHAR(255),
    album_title VARCHAR(255),
    year INT,
    artist_name VARCHAR(255)
);
