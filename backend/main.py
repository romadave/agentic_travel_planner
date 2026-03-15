from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Travel Planner API is running"}