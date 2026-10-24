\set ON_ERROR_STOP on
BEGIN;
\ir /import/schema.sql
CREATE TEMP TABLE import_teams (LIKE nba.teams INCLUDING DEFAULTS) ON COMMIT DROP;
CREATE TEMP TABLE import_players (LIKE nba.players INCLUDING DEFAULTS) ON COMMIT DROP;
CREATE TEMP TABLE import_games (LIKE nba.games INCLUDING DEFAULTS) ON COMMIT DROP;
CREATE TEMP TABLE import_team_stats (LIKE nba.team_game_stats INCLUDING DEFAULTS) ON COMMIT DROP;
CREATE TEMP TABLE import_player_stats (LIKE nba.player_game_stats INCLUDING DEFAULTS) ON COMMIT DROP;
\copy import_teams FROM '/seed/teams.csv' WITH (FORMAT csv, HEADER true)
\copy import_players FROM '/seed/players.csv' WITH (FORMAT csv, HEADER true)
\copy import_games FROM '/seed/games.csv' WITH (FORMAT csv, HEADER true)
\copy import_team_stats FROM '/seed/team_game_stats.csv' WITH (FORMAT csv, HEADER true)
\copy import_player_stats FROM '/seed/player_game_stats.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO nba.teams SELECT * FROM import_teams
ON CONFLICT (id) DO UPDATE SET abbreviation = EXCLUDED.abbreviation, name = EXCLUDED.name;
INSERT INTO nba.players SELECT * FROM import_players
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO nba.games SELECT * FROM import_games
ON CONFLICT (id) DO UPDATE SET season = EXCLUDED.season, phase = EXCLUDED.phase, game_date = EXCLUDED.game_date;
INSERT INTO nba.team_game_stats SELECT * FROM import_team_stats
ON CONFLICT (game_id, team_id) DO UPDATE SET
    matchup = EXCLUDED.matchup, result = EXCLUDED.result, points = EXCLUDED.points,
    rebounds = EXCLUDED.rebounds, assists = EXCLUDED.assists, source_record = EXCLUDED.source_record;
INSERT INTO nba.player_game_stats SELECT * FROM import_player_stats
ON CONFLICT (game_id, player_id) DO UPDATE SET
    team_id = EXCLUDED.team_id, position = EXCLUDED.position, comment = EXCLUDED.comment,
    jersey_number = EXCLUDED.jersey_number, minutes = EXCLUDED.minutes,
    points = EXCLUDED.points, rebounds = EXCLUDED.rebounds, assists = EXCLUDED.assists,
    source_record = EXCLUDED.source_record;
ANALYZE nba.teams;
ANALYZE nba.players;
ANALYZE nba.games;
ANALYZE nba.team_game_stats;
ANALYZE nba.player_game_stats;
COMMIT;
