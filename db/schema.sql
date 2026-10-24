CREATE SCHEMA IF NOT EXISTS nba;
CREATE TABLE IF NOT EXISTS nba.teams (
    id BIGINT PRIMARY KEY,
    abbreviation TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS nba.players (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS nba.games (
    id TEXT PRIMARY KEY,
    season TEXT NOT NULL,
    phase TEXT NOT NULL CHECK (phase IN ('regular', 'playoffs')),
    game_date DATE NOT NULL
);
CREATE TABLE IF NOT EXISTS nba.team_game_stats (
    game_id TEXT NOT NULL REFERENCES nba.games(id),
    team_id BIGINT NOT NULL REFERENCES nba.teams(id),
    matchup TEXT NOT NULL,
    result TEXT NOT NULL CHECK (result IN ('W', 'L')),
    points INTEGER NOT NULL CHECK (points >= 0),
    rebounds INTEGER NOT NULL CHECK (rebounds >= 0),
    assists INTEGER NOT NULL CHECK (assists >= 0),
    source_record JSONB NOT NULL,
    PRIMARY KEY (game_id, team_id)
);
CREATE TABLE IF NOT EXISTS nba.player_game_stats (
    game_id TEXT NOT NULL,
    player_id BIGINT NOT NULL REFERENCES nba.players(id),
    team_id BIGINT NOT NULL,
    position TEXT,
    comment TEXT,
    jersey_number TEXT,
    minutes TEXT,
    points INTEGER NOT NULL CHECK (points >= 0),
    rebounds INTEGER NOT NULL CHECK (rebounds >= 0),
    assists INTEGER NOT NULL CHECK (assists >= 0),
    source_record JSONB NOT NULL,
    PRIMARY KEY (game_id, player_id),
    FOREIGN KEY (game_id, team_id) REFERENCES nba.team_game_stats(game_id, team_id)
);
CREATE INDEX IF NOT EXISTS games_season_phase_date_idx ON nba.games(season, phase, game_date);
CREATE INDEX IF NOT EXISTS player_game_stats_player_game_idx ON nba.player_game_stats(player_id, game_id);
CREATE INDEX IF NOT EXISTS player_game_stats_team_game_idx ON nba.player_game_stats(team_id, game_id);
CREATE INDEX IF NOT EXISTS team_game_stats_team_game_idx ON nba.team_game_stats(team_id, game_id);
