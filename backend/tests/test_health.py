import pytest
from datetime import date

@pytest.fixture
def auth_headers(client):
    reg_payload = {
        "email": "healthuser@avara.com",
        "username": "healthuser",
        "password": "Password123!",
        "preferred_language": "te"
    }
    resp = client.post("/api/v1/auth/register", json=reg_payload)
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_health_wellness_entries_and_summary(client, auth_headers):
    today_str = date.today().strftime("%Y-%m-%d")

    # 1. Add daily wellness entry
    entry_payload = {
        "date": today_str,
        "mood": "Good",
        "mood_score": 4,
        "energy_level": 4,
        "sleep_hours": 7.5,
        "activity_minutes": 45,
        "wellness_goals": "Drink 2L water, 30 min evening walk",
        "notes": "Felt productive and refreshed today."
    }
    create_resp = client.post("/api/v1/health/entries", json=entry_payload, headers=auth_headers)
    assert create_resp.status_code == 201
    entry_data = create_resp.json()
    assert entry_data["mood"] == "Good"
    entry_id = entry_data["id"]

    # 2. View wellness history
    list_resp = client.get("/api/v1/health/entries", headers=auth_headers)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) >= 1

    # 3. View health summary
    summary_resp = client.get("/api/v1/health/summary", headers=auth_headers)
    assert summary_resp.status_code == 200
    summary = summary_resp.json()
    assert summary["total_entries"] >= 1
    assert summary["average_mood_score"] == 4.0
    assert summary["average_sleep_hours"] == 7.5
    assert summary["total_activity_minutes"] == 45

    # 4. Update entry
    update_resp = client.put(f"/api/v1/health/entries/{entry_id}", json={"mood_score": 5}, headers=auth_headers)
    assert update_resp.status_code == 200
    assert update_resp.json()["mood_score"] == 5

    # 5. Delete entry
    del_resp = client.delete(f"/api/v1/health/entries/{entry_id}", headers=auth_headers)
    assert del_resp.status_code == 200
