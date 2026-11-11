import pytest

def test_user_registration_and_login(client):
    # 1. Register new user
    reg_payload = {
        "email": "testuser@avara.com",
        "username": "testuser",
        "password": "Password123!",
        "full_name": "Test User",
        "preferred_language": "te",
        "birth_date": "1998-05-15",
        "birth_time": "14:30",
        "birth_place": "Hyderabad"
    }
    resp = client.post("/api/v1/auth/register", json=reg_payload)
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert data["email"] == "testuser@avara.com"

    # 2. Duplicate registration should fail
    resp_dup = client.post("/api/v1/auth/register", json=reg_payload)
    assert resp_dup.status_code == 409

    # 3. Login with correct credentials
    login_payload = {
        "email": "testuser@avara.com",
        "password": "Password123!"
    }
    resp_login = client.post("/api/v1/auth/login", json=login_payload)
    assert resp_login.status_code == 200
    token = resp_login.json()["access_token"]
    assert token

    # 4. Login with invalid password
    resp_bad = client.post("/api/v1/auth/login", json={"email": "testuser@avara.com", "password": "WrongPassword"})
    assert resp_bad.status_code == 401

    # 5. Access protected profile route
    headers = {"Authorization": f"Bearer {token}"}
    resp_profile = client.get("/api/v1/profile/me", headers=headers)
    assert resp_profile.status_code == 200
    p_data = resp_profile.json()
    assert p_data["username"] == "testuser"
    assert p_data["preferred_language"] == "te"

def test_unauthorized_access(client):
    # Missing authorization header
    resp = client.get("/api/v1/profile/me")
    assert resp.status_code == 401

    # Invalid token format
    resp_bad_token = client.get("/api/v1/profile/me", headers={"Authorization": "Bearer invalid.token.payload"})
    assert resp_bad_token.status_code == 401
