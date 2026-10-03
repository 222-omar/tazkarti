from datetime import datetime
from watcher.matcher import normalize_text, TeamMatcher
from watcher.tazkarti_client import Match


def test_arabic_normalization():
    # Alef variations
    assert normalize_text("الأهلي") == "الاهلي"
    assert normalize_text("إفريقيا") == "افريقيا"
    assert normalize_text("آسيا") == "اسيا"

    # Taa Marbouta to Haa, Alef Maqsura to Yaa
    assert normalize_text("المقاصة") == "المقاصه"
    assert normalize_text("الأهلى") == "الاهلي"

    # Tashkeel (diacritics) and Tatweel
    assert normalize_text("مِصْرُ") == "مصر"
    assert normalize_text("الأهْـلِـي") == "الاهلي"

    # Punctuation and spaces
    assert normalize_text("Al-Ahly   FC") == "al ahly fc"
    assert normalize_text("  Egypt ! ") == "egypt"


def test_exact_matching_vs_substrings():
    matcher = TeamMatcher()

    def make_match(team1_ar, team1_en, team2_ar="جنوب افريقيا", team2_en="South Africa"):
        return Match(
            match_id=999,
            team1_id=1,
            team2_id=2,
            team1_ar=team1_ar,
            team1_en=team1_en,
            team2_ar=team2_ar,
            team2_en=team2_en,
            kickoff=datetime(2026, 10, 4, 21, 0),
            tournament_ar="بطولة",
            tournament_en="Tournament",
            stadium_ar="استاد",
            match_status_raw=1,
            show_in_portal=True,
            is_deleted=False,
        )

    # 1. Egypt exact match
    egypt_match = make_match("مصر", "Egypt")
    identified = matcher.identify_teams_for_match(egypt_match)
    assert len(identified) == 1
    assert identified[0]["key"] == "egypt"

    # 2. "المصري" should NEVER match "مصر"
    masry_match = make_match("المصري", "Al Masry")
    assert len(matcher.identify_teams_for_match(masry_match)) == 0

    # 3. "مصر المقاصة" should NEVER match "مصر"
    makassa_match = make_match("مصر المقاصة", "Misr Lel Makkasa")
    assert len(matcher.identify_teams_for_match(makassa_match)) == 0

    # 4. Al Ahly exact match
    ahly_match = make_match("الأهلي", "Al Ahly")
    identified_ahly = matcher.identify_teams_for_match(ahly_match)
    assert len(identified_ahly) == 1
    assert identified_ahly[0]["key"] == "ahly"

    # 5. Non-Ahly club (e.g. Ahli Tripoli) should NOT match
    tripoli_match = make_match("أهلي طرابلس", "Ahli Tripoli")
    assert len(matcher.identify_teams_for_match(tripoli_match)) == 0


def test_home_and_away_matching():
    matcher = TeamMatcher()
    away_match = Match(
        match_id=1001,
        team1_id=50,
        team2_id=122,
        team1_ar="جنوب افريقيا",
        team1_en="South Africa",
        team2_ar="مصر",
        team2_en="Egypt",
        kickoff=datetime(2026, 10, 4, 21, 0),
        tournament_ar="المباريات الودية الدولية.",
        tournament_en="International Friendlies.",
        stadium_ar="استاد القاهرة الدولي",
        match_status_raw=1,
        show_in_portal=True,
        is_deleted=False,
    )
    teams = matcher.identify_teams_for_match(away_match)
    assert len(teams) == 1
    assert teams[0]["key"] == "egypt"


def test_deleted_and_hidden_matches_skipped():
    matcher = TeamMatcher()
    deleted_match = Match(
        match_id=1002,
        team1_id=1,
        team2_id=2,
        team1_ar="مصر",
        team1_en="Egypt",
        team2_ar="جنوب افريقيا",
        team2_en="South Africa",
        kickoff=datetime(2026, 10, 4, 21, 0),
        tournament_ar="بطولة",
        tournament_en="Tournament",
        stadium_ar="استاد",
        match_status_raw=1,
        show_in_portal=True,
        is_deleted=True,  # DELETED
    )
    assert len(matcher.identify_teams_for_match(deleted_match)) == 0

    hidden_match = Match(
        match_id=1003,
        team1_id=1,
        team2_id=2,
        team1_ar="الأهلي",
        team1_en="Al Ahly",
        team2_ar="الزمالك",
        team2_en="Zamalek",
        kickoff=datetime(2026, 10, 4, 21, 0),
        tournament_ar="بطولة",
        tournament_en="Tournament",
        stadium_ar="استاد",
        match_status_raw=1,
        show_in_portal=False,  # HIDDEN
        is_deleted=False,
    )
    assert len(matcher.identify_teams_for_match(hidden_match)) == 0
