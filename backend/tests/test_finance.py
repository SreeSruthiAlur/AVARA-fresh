import pytest
from datetime import date

@pytest.fixture
def auth_headers(client):
    reg_payload = {
        "email": "financeuser@avara.com",
        "username": "finuser",
        "password": "Password123!",
        "preferred_language": "te"
    }
    resp = client.post("/api/v1/auth/register", json=reg_payload)
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_finance_expenses_and_budgets(client, auth_headers):
    today_str = date.today().strftime("%Y-%m-%d")
    current_month_str = date.today().strftime("%Y-%m")

    # 1. Set budget
    budget_payload = {
        "month": current_month_str,
        "total_budget": 10000.0,
        "category_limits": {
            "Food": 4000.0,
            "Transportation": 2000.0
        }
    }
    b_resp = client.post("/api/v1/finance/budgets", json=budget_payload, headers=auth_headers)
    assert b_resp.status_code == 200
    assert b_resp.json()["total_budget"] == 10000.0

    # 2. Add an expense
    exp1 = {
        "amount": 500.0,
        "category": "Food",
        "date": today_str,
        "description": "Lunch with team",
        "payment_method": "UPI"
    }
    exp1_resp = client.post("/api/v1/finance/expenses", json=exp1, headers=auth_headers)
    assert exp1_resp.status_code == 201
    exp1_id = exp1_resp.json()["id"]

    # 3. Add second expense
    exp2 = {
        "amount": 250.0,
        "category": "Transportation",
        "date": today_str,
        "description": "Metro card recharge",
        "payment_method": "Card"
    }
    client.post("/api/v1/finance/expenses", json=exp2, headers=auth_headers)

    # 4. View and filter expenses
    list_resp = client.get("/api/v1/finance/expenses?category=Food", headers=auth_headers)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1
    assert list_resp.json()[0]["category"] == "Food"

    # 5. Check Finance Dashboard
    dash_resp = client.get(f"/api/v1/finance/dashboard?month={current_month_str}", headers=auth_headers)
    assert dash_resp.status_code == 200
    dash_data = dash_resp.json()
    assert dash_data["total_spending_month"] == 750.0
    assert dash_data["total_budget_month"] == 10000.0
    assert dash_data["remaining_budget_month"] == 9250.0
    assert dash_data["budget_utilization_pct"] == 7.5

    # 6. Test AI Finance Assistant (deterministic on real DB values)
    assistant_query = {
        "query": "How much total money did I spend this month?"
    }
    ai_resp = client.post("/api/v1/finance/ai-assistant", json=assistant_query, headers=auth_headers)
    assert ai_resp.status_code == 200
    ai_data = ai_resp.json()
    assert "750.00" in ai_data["deterministic_answer"]

    # 7. Edit and Delete expense
    edit_resp = client.put(f"/api/v1/finance/expenses/{exp1_id}", json={"amount": 600.0}, headers=auth_headers)
    assert edit_resp.status_code == 200
    assert edit_resp.json()["amount"] == 600.0

    del_resp = client.delete(f"/api/v1/finance/expenses/{exp1_id}", headers=auth_headers)
    assert del_resp.status_code == 200

    # Verify deleted
    get_del = client.get(f"/api/v1/finance/expenses/{exp1_id}", headers=auth_headers)
    assert get_del.status_code == 404
