import pytest
from datetime import date

def test_chat_routing_and_llm_fallback(client):
    # Register user
    reg_payload = {
        "email": "chatuser@avara.com",
        "username": "chatuser",
        "password": "Password123!",
        "preferred_language": "te"
    }
    resp = client.post("/api/v1/auth/register", json=reg_payload)
    token = resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Send General message (LLM unconfigured fallback transparently returned)
    msg1 = {"message": "Hello AVARA, how can you help me today?"}
    chat_resp = client.post("/api/v1/chat/message", json=msg1, headers=headers)
    assert chat_resp.status_code == 200
    data = chat_resp.json()
    assert data["success"] is True
    assert "conversation_id" in data
    assert "assistant_message" in data
    # Transparently mentions unconfigured AI or rule guidance without pretending mock is live AI
    assert data["route_target"] in ["general", "general_conversation"]

    # 2. Send Teammate 1 Astrology message -> Routes cleanly to teammate1_astrology
    msg_astro = {"message": "Can you check my birth chart and horoscope?"}
    astro_chat = client.post("/api/v1/chat/message", json=msg_astro, headers=headers)
    assert astro_chat.status_code == 200
    assert astro_chat.json()["route_target"] == "teammate1_astrology"
    assert "Teammate 1" in astro_chat.json()["assistant_message"]["text"]

    # 3. Direct Integration Contract Endpoints for Teammate 1
    contracts_resp = client.get("/api/v1/integrations/contracts")
    assert contracts_resp.status_code == 200
    assert contracts_resp.json()["status"] == "ready_for_teammate_1"

    # Astrology chart contract
    chart_payload = {
        "user_id": 1,
        "birth_date": "1999-01-01",
        "birth_time": "10:00",
        "birth_place": "Tirupati",
        "preferred_language": "te"
    }
    chart_resp = client.post("/api/v1/integrations/astrology/chart", json=chart_payload, headers=headers)
    assert chart_resp.status_code == 200
    assert chart_resp.json()["provider_module"] == "teammate_1_astrology"

    # Habits contract
    habits_resp = client.get("/api/v1/integrations/habits/summary", headers=headers)
    assert habits_resp.status_code == 200
    assert habits_resp.json()["provider_module"] == "teammate_1_habits"

    # Insights contract
    insights_resp = client.get("/api/v1/integrations/insights/summary", headers=headers)
    assert insights_resp.status_code == 200
    assert insights_resp.json()["provider_module"] == "teammate_1_insights"

def test_astrologer_directory_and_booking(client):
    reg = client.post("/api/v1/auth/register", json={
        "email": "bookinguser@avara.com", "username": "bookuser", "password": "Password123!"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # List astrologers (demonstration profiles)
    list_resp = client.get("/api/v1/astrologers")
    assert list_resp.status_code == 200
    astros = list_resp.json()
    assert len(astros) >= 1
    assert astros[0]["is_demo"] is True

    # Book consultation
    today_str = date.today().strftime("%Y-%m-%d")
    booking_payload = {
        "astrologer_id": astros[0]["id"],
        "booking_date": today_str,
        "time_slot": "10:00 AM",
        "consultation_topic": "Career guidance discussion",
        "notes": "Interested in tech career transitions"
    }
    book_resp = client.post("/api/v1/astrologers/bookings", json=booking_payload, headers=headers)
    assert book_resp.status_code == 201
    booking_id = book_resp.json()["id"]

    # View my bookings
    my_bookings = client.get("/api/v1/astrologers/bookings/me", headers=headers)
    assert my_bookings.status_code == 200
    assert len(my_bookings.json()) >= 1

    # Cancel booking
    cancel_resp = client.delete(f"/api/v1/astrologers/bookings/{booking_id}", headers=headers)
    assert cancel_resp.status_code == 200

def test_user_data_isolation(client):
    # Register User A
    user_a = client.post("/api/v1/auth/register", json={
        "email": "usera@avara.com", "username": "usera", "password": "Password123!"
    }).json()
    headers_a = {"Authorization": f"Bearer {user_a['access_token']}"}

    # Register User B
    user_b = client.post("/api/v1/auth/register", json={
        "email": "userb@avara.com", "username": "userb", "password": "Password123!"
    }).json()
    headers_b = {"Authorization": f"Bearer {user_b['access_token']}"}

    # User A creates private expense
    today_str = date.today().strftime("%Y-%m-%d")
    client.post("/api/v1/finance/expenses", json={
        "amount": 999.0, "category": "Shopping", "date": today_str, "description": "Private item"
    }, headers=headers_a)

    # User B lists expenses -> Must be 0
    resp_b = client.get("/api/v1/finance/expenses", headers=headers_b)
    assert resp_b.status_code == 200
    assert len(resp_b.json()) == 0
