"""Normalize and validate the 2021-22 archive into PostgreSQL COPY inputs."""
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEASON = '2021-22'

def records(name, season_key):
    with (ROOT / 'data/raw' / name).open(encoding='utf-8-sig', newline='') as stream:
        for row in csv.DictReader(stream):
            if row[season_key] == SEASON:
                yield row

def main():
    teams, players, games, team_stats, player_stats = {}, {}, {}, {}, {}
    for phase, name in [('regular', 'regular_season_totals_2010_2024.csv'),
                        ('playoffs', 'play_off_totals_2010_2024.csv')]:
        for r in records(name, 'SEASON_YEAR'):
            tid, gid = int(r['TEAM_ID']), r['GAME_ID'].zfill(10)
            teams[tid] = [tid, r['TEAM_ABBREVIATION'], r['TEAM_NAME']]
            game = [gid, SEASON, phase, r['GAME_DATE'][:10]]
            if gid in games:
                assert games[gid] == game, f'Conflicting game {gid}'
            games[gid] = game
            key = (gid, tid)
            assert key not in team_stats, f'Duplicate team game {key}'
            team_stats[key] = [gid, tid, r['MATCHUP'], r['WL'], int(r['PTS']),
                               int(r['REB']), int(r['AST']), json.dumps(r)]

    sources = [f'regular_season_box_scores_2010_2024_part_{i}.csv' for i in range(1, 4)]
    sources.append('play_off_box_scores_2010_2024.csv')
    for name in sources:
        for r in records(name, 'season_year'):
            pid, tid, gid = int(r['personId']), int(r['teamId']), r['gameId'].zfill(10)
            assert (gid, tid) in team_stats, f'Orphan box score {gid}/{tid}'
            assert r['game_date'][:10] == games[gid][3]
            if pid in players:
                assert players[pid][1] == r['personName'], f'Conflicting player {pid}'
            players[pid] = [pid, r['personName']]
            key = (gid, pid)
            assert key not in player_stats, f'Duplicate player game {key}'
            player_stats[key] = [gid, pid, tid, r['position'], r['comment'],
                                 r['jerseyNum'], r['minutes'], int(r['points']),
                                 int(r['reboundsTotal']), int(r['assists']), json.dumps(r)]

    counts = Counter(g[2] for g in games.values())
    assert counts == {'regular': 1230, 'playoffs': 87}, counts
    assert len(teams) == 30
    assert all(n == 2 for n in Counter(k[0] for k in team_stats).values())
    point_totals = Counter()
    for row in player_stats.values():
        point_totals[(row[0], row[2])] += row[7]
    assert set(point_totals) == set(team_stats), 'Missing player coverage'
    for key, row in team_stats.items():
        assert point_totals[key] == row[4], f'Player/team points mismatch: {key}'
    finals = [r for r in team_stats.values() if r[0] == '0042100406']
    assert {(r[1], r[3], r[4]) for r in finals} == {
        (1610612744, 'W', 103), (1610612738, 'L', 90)}, finals

    tables = {
        'teams': (['id', 'abbreviation', 'name'], teams),
        'players': (['id', 'name'], players),
        'games': (['id', 'season', 'phase', 'game_date'], games),
        'team_game_stats': (['game_id', 'team_id', 'matchup', 'result', 'points',
                             'rebounds', 'assists', 'source_record'], team_stats),
        'player_game_stats': (['game_id', 'player_id', 'team_id', 'position', 'comment',
                               'jersey_number', 'minutes', 'points', 'rebounds',
                               'assists', 'source_record'], player_stats),
    }
    dest = ROOT / 'data' / SEASON
    dest.mkdir(parents=True, exist_ok=True)
    report = {'season': SEASON, 'games_by_phase': dict(counts), 'tables': {},
              'checks': ['unique keys', 'foreign keys', 'two teams per game',
                         'all player points reconcile to team scores',
                         'Finals Game 6: GSW 103, BOS 90']}
    for table, (header, rows) in tables.items():
        path = dest / f'{table}.csv'
        with path.open('w', encoding='utf-8', newline='') as stream:
            writer = csv.writer(stream)
            writer.writerow(header)
            writer.writerows(rows[key] for key in sorted(rows))
        report['tables'][table] = {'rows': len(rows),
                                   'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    (dest / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    (ROOT / 'data' / 'LICENSE.source').write_bytes((ROOT / 'data/raw/LICENSE').read_bytes())
    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()
