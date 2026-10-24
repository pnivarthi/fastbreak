-- Stephen Curry's 2022 Finals games.
SELECT g.game_date, p.name, s.points, s.rebounds, s.assists
FROM nba.player_game_stats s
JOIN nba.players p ON p.id = s.player_id
JOIN nba.games g ON g.id = s.game_id
WHERE s.player_id = 201939 AND g.id LIKE '00421004%'
ORDER BY g.game_date;

-- Regular-season scoring leaders; omit DNP rows from the games-played count.
SELECT p.id, p.name, count(*) AS games_played, sum(s.points) AS total_points,
       round(avg(s.points), 2) AS points_per_game
FROM nba.player_game_stats s
JOIN nba.players p ON p.id = s.player_id
JOIN nba.games g ON g.id = s.game_id
WHERE g.season = '2021-22' AND g.phase = 'regular'
  AND coalesce(s.minutes, '') NOT IN ('', '0:00', '0:0', '0:00:00')
GROUP BY p.id, p.name
ORDER BY total_points DESC LIMIT 10;
