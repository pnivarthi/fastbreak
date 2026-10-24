\set ON_ERROR_STOP on
SELECT 'teams' AS entity, count(*) FROM nba.teams
UNION ALL SELECT 'players', count(*) FROM nba.players
UNION ALL SELECT 'games', count(*) FROM nba.games
UNION ALL SELECT 'team_game_stats', count(*) FROM nba.team_game_stats
UNION ALL SELECT 'player_game_stats', count(*) FROM nba.player_game_stats;

SELECT phase, count(*) FROM nba.games WHERE season = '2021-22' GROUP BY phase;

-- The championship-clinching game: GSW 103, BOS 90 on June 16, 2022.
SELECT g.game_date, t.abbreviation, s.result, s.points
FROM nba.team_game_stats s
JOIN nba.games g ON g.id = s.game_id
JOIN nba.teams t ON t.id = s.team_id
WHERE g.id = '0042100406' ORDER BY s.points DESC;

DO $$
BEGIN
    IF (SELECT count(*) FROM nba.games WHERE season = '2021-22' AND phase = 'regular') <> 1230
       OR (SELECT count(*) FROM nba.games WHERE season = '2021-22' AND phase = 'playoffs') <> 87
       OR (SELECT count(*) FROM nba.player_game_stats s JOIN nba.games g ON g.id = s.game_id
           WHERE g.season = '2021-22') <> 33693 THEN
        RAISE EXCEPTION 'Unexpected season row counts';
    END IF;
    IF EXISTS (
        SELECT 1 FROM nba.team_game_stats t JOIN nba.games g ON g.id = t.game_id
        LEFT JOIN nba.player_game_stats p ON p.game_id = t.game_id AND p.team_id = t.team_id
        WHERE g.season = '2021-22'
        GROUP BY t.game_id, t.team_id, t.points HAVING sum(p.points) IS DISTINCT FROM t.points
    ) THEN
        RAISE EXCEPTION 'Player points do not reconcile to team points';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM nba.team_game_stats
                   WHERE game_id = '0042100406' AND team_id = 1610612744
                     AND result = 'W' AND points = 103) THEN
        RAISE EXCEPTION 'Missing championship game';
    END IF;
END $$;
