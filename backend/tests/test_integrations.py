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

def test_birth_details_on_demand_and_chat_saving(client):
    # 1. Register minimal user (name, email, password only)
    reg = client.post("/api/v1/auth/register", json={
        "email": "ondemanduser@avara.com",
        "username": "ondemanduser",
        "password": "Password123!",
        "preferred_language": "en"
    })
    assert reg.status_code == 201
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Ask personal chart question when DOB/TOB/POB are missing
    msg1 = {"message": "Can you check my birth chart and horoscope?"}
    chat1 = client.post("/api/v1/chat/message", json=msg1, headers=headers)
    assert chat1.status_code == 200
    res1 = chat1.json()
    assert res1["route_target"] == "teammate1_astrology"
    asst_text1 = res1["assistant_message"]["text"]
    assert "Teammate 1" in asst_text1
    assert "Date of Birth" in asst_text1 or "DOB" in asst_text1
    assert "Place of Birth" in asst_text1 or "POB" in asst_text1
    # Verify no fake dummy chart dump occurred
    assert "2000-01-01" not in asst_text1

    # 3. User supplies DOB, TOB, POB in chat
    msg2 = {"message": "My DOB is 1996-07-22, TOB is 11:15 AM, POB is Visakhapatnam"}
    chat2 = client.post("/api/v1/chat/message", json=msg2, headers=headers)
    assert chat2.status_code == 200
    res2 = chat2.json()
    asst_text2 = res2["assistant_message"]["text"]
    assert "1996-07-22" in asst_text2
    assert "Visakhapatnam" in asst_text2

    # 4. Check user profile to ensure details were persisted to the database
    me_resp = client.get("/api/v1/profile/me", headers=headers)
    assert me_resp.status_code == 200
    user_data = me_resp.json()
    assert user_data["birth_date"] == "1996-07-22"
    assert user_data["birth_place"] == "Visakhapatnam"

def test_consistent_timing_and_equal_structure_across_languages(client):
    # 1. Register user with birth details
    reg = client.post("/api/v1/auth/register", json={
        "email": "timinglanguser@avara.com",
        "username": "timinglanguser",
        "password": "Password123!",
        "preferred_language": "en"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Store birth details in chat
    save_msg = {"message": "My DOB is 1998-05-15, TOB is 09:30 AM, POB is Hyderabad"}
    client.post("/api/v1/chat/message", json=save_msg, headers=headers)

    # 2. Ask timing question in English
    en_msg = {"message": "When will I land a good internship?"}
    en_resp = client.post("/api/v1/chat/message", json=en_msg, headers=headers)
    assert en_resp.status_code == 200
    en_text = en_resp.json()["assistant_message"]["text"]

    # Verify 3 sections in English
    assert "**1. Direct Timing & Outcome**" in en_text
    assert "**2. Key Astrological Factors**" in en_text
    assert "**3. Actionable Next Step**" in en_text

    # Extract the predicted Month and Year from English response
    import re
    m_en = re.search(r'\*\*([A-Za-z]+ \d{4})\*\*', en_text)
    assert m_en is not None
    en_timing = m_en.group(1)

    # 3. Ask timing question in Tanglish
    te_msg = {"message": "naaku oka manchi internship eppudu vastundi?"}
    te_resp = client.post("/api/v1/chat/message", json=te_msg, headers=headers)
    assert te_resp.status_code == 200
    te_text = te_resp.json()["assistant_message"]["text"]

    # Verify 3 sections in Tanglish
    assert "**1. Direct Timing & Outcome**" in te_text
    assert "**2. Key Astrological Factors**" in te_text
    assert "**3. Actionable Next Step**" in te_text
    assert "Mee chart prakaram" in te_text

    # Extract the predicted Month and Year from Tanglish response
    m_te = re.search(r'\*\*([A-Za-z]+ \d{4})\*\*', te_text)
    assert m_te is not None
    te_timing = m_te.group(1)

    # 4. Enforce STRICT consistency across language switch
    assert en_timing == te_timing, f"Timing drifted across languages: {en_timing} vs {te_timing}"

    # 5. Enforce length parity between English and Tanglish (word count roughly equal)
    en_words = len(en_text.split())
    te_words = len(te_text.split())
    diff = abs(en_words - te_words)
    assert diff <= 25, f"Length disparity too large between English ({en_words}) and Tanglish ({te_words})"

def test_tanglish_chat_never_empty_and_fallback(client):
    reg = client.post("/api/v1/auth/register", json={
        "email": "tanglishneverempty@avara.com",
        "username": "tanglishemptyuser",
        "password": "Password123!",
        "preferred_language": "tanglish"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Ask general question in Tanglish
    gen_resp = client.post("/api/v1/chat/message", json={"message": "astrology ante emiti vivarinchandi"}, headers=headers)
    assert gen_resp.status_code == 200
    gen_text = gen_resp.json()["assistant_message"]["text"]
    assert gen_text is not None
    assert len(gen_text.strip()) > 10

    # 2. Timing query without birth details -> Asks for DOB/TOB/POB in Tanglish, non-empty
    tim_resp1 = client.post("/api/v1/chat/message", json={"message": "naaku promotion eppudu vastundi?"}, headers=headers)
    assert tim_resp1.status_code == 200
    tim_text1 = tim_resp1.json()["assistant_message"]["text"]
    assert tim_text1 is not None
    assert len(tim_text1.strip()) > 20
    assert "DOB" in tim_text1 or "birth details" in tim_text1 or "TOB" in tim_text1

    # 3. Supply birth details in chat
    save_resp = client.post("/api/v1/chat/message", json={"message": "DOB 1997-03-12 TOB 10:15 AM POB Guntur"}, headers=headers)
    assert save_resp.status_code == 200

    # 4. Ask timing query with birth details on file -> Returns non-empty 3-section Tanglish response
    tim_resp2 = client.post("/api/v1/chat/message", json={"message": "naaku oka manchi internship eppudu vastundi?"}, headers=headers)
    assert tim_resp2.status_code == 200
    tim_text2 = tim_resp2.json()["assistant_message"]["text"]
    assert tim_text2 is not None
    assert len(tim_text2.strip()) > 30
    assert "**1. Direct Timing & Outcome**" in tim_text2
    assert "**2. Key Astrological Factors**" in tim_text2
    assert "**3. Actionable Next Step**" in tim_text2
    assert "Mee chart prakaram" in tim_text2

def test_llm_response_sanitization_and_no_meta():
    from app.services.llm_service import LLMService

    leaked = (
        "<think>Word count: 95 words. Let's draft response.</think>\n"
        "Word count: Let's draft:\n"
        "**1. Direct Timing & Outcome**\n"
        "Your strongest favorable window is **August 2027**.\n\n"
        "**2. Key Astrological Factors**\n"
        "- Transit in 10th house.\n"
        "- Dasha alignment.\n\n"
        "**3. Actionable Next Step**\n"
        "Focus on preparation."
    )
    cleaned = LLMService.sanitize_llm_response(leaked)
    assert "<think>" not in cleaned
    assert "</think>" not in cleaned
    assert "Word count:" not in cleaned
    assert "Let's draft:" not in cleaned
    assert cleaned.startswith("**1. Direct Timing & Outcome**")

    # Verify STRICT NO-META RULE in SYSTEM_PROMPT
    assert "STRICT NO-META RULE" in LLMService.SYSTEM_PROMPT

def test_system_prompt_birth_details_status_and_timing_omission_when_missing():
    import asyncio
    from app.services.llm_service import LLMService

    # When birth details are missing
    anchor = {
        "topic": "internship",
        "peak_month_year": "August 2027",
        "range_window": "July 2027 – September 2027",
        "basis": "10th house activation"
    }

    # Deterministic fallback when birth details not provided -> asks for DOB
    fallback = LLMService._build_unconfigured_fallback(
        "when will I get an internship?",
        "english",
        timing_anchor=anchor,
        birth_details_provided=False
    )
    assert "birth details are not on file" in fallback["text"] or "DOB" in fallback["text"]
    assert "10th house" not in fallback["text"]

    # Deterministic fallback when birth details are provided -> returns timing
    fallback_with_birth = LLMService._build_unconfigured_fallback(
        "when will I get an internship?",
        "english",
        timing_anchor=anchor,
        birth_details_provided=True
    )
    assert "**1. Direct Timing & Outcome**" in fallback_with_birth["text"]
    assert "August 2027" in fallback_with_birth["text"]



