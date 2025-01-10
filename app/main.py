from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "Welcome to the FastAPI ECS Fargate app!"}


@app.get("/hello/{name}")
def read_item(name: str):
    return {"message": f"Hello {name}!"}
