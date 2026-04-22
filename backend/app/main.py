from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, income, expense, goal, category, insights, investment, debt, health, alert
# from app.core.scheduler import start_scheduler
from app.db.base import create_tables


app = FastAPI(title="Personalized Finance Management System")
create_tables()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(income.router)
app.include_router(expense.router)
app.include_router(category.router)
app.include_router(goal.router)
app.include_router(insights.router)
app.include_router(investment.router)
app.include_router(debt.router)
app.include_router(health.router)
app.include_router(alert.router)

@app.get("/")
def root():
    return {"message": "Finance Management API running"}

# @app.on_event("startup")
# def startup_event():
#     start_scheduler()



