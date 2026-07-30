from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/version")
def version():
    return {"version": "1.2.0"}

@app.get("/calculate")
def calculate(a: int, b: int):
    return {"operation": "addition", "result": a + b}
