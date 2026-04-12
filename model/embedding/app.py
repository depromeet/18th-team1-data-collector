from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

app = FastAPI()

model = SentenceTransformer("jhgan/ko-sroberta-multitask")


class TextInput(BaseModel):
    inputs: str


@app.post("/embedding")
async def get_embedding(data: TextInput):
    embedding = model.encode(data.inputs).tolist()
    return {"embedding": embedding}


@app.get("/health")
async def health():
    return {"status": "ok"}
