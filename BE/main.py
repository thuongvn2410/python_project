from typing import Optional
from fastapi import FastAPI

# Khởi tạo ứng dụng FastAPI
app = FastAPI()

# Định nghĩa một endpoint (GET)
@app.get("/")
def read_root():
    return {"Hello": "World"}

# Định nghĩa một endpoint khác có tham số (path parameter)
@app.get("/items/{item_id}")
def read_item(item_id: int, q: Optional[str] = None):
    return {"item_id": item_id, "q": q}