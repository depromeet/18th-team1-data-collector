from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

app = FastAPI()

MODEL_NAME = "M1NJ1/kobert-emotion"
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
model = AutoModelForSequenceClassification.from_pretrained(MODEL_NAME, trust_remote_code=True)
model.eval()

LABELS = [
    "불평/불만", "환영/호의", "감동/감탄", "지긋지긋", "고마움",
    "슬픔", "화남/분노", "존경", "기대감", "우쭐댐/무시함",
    "안타까움/동정", "비장함", "의심/불신", "뿌듯함", "편안/쾌적",
    "신기함/관심", "아끼는/사랑하는", "부끄러움/수줍음", "공포/무서움", "절망",
    "한심함", "역겨움/징그러움", "짜증", "어이없음", "패배/자기혐오",
    "귀찮음", "힘듦/지침", "즐거움/신남", "깨달음", "죄책감",
    "증오/혐오", "흐뭇함/뿌듯함", "당황/난처", "걱정/불안", "기쁨",
    "안심/안도", "놀람", "행복", "불쌍함/연민", "부러움",
    "분함", "짜증남", "후회", "없음"
]


class TextInput(BaseModel):
    inputs: str


@app.post("/emotion")
async def predict_emotion(data: TextInput):
    inputs = tokenizer(data.inputs, return_tensors="pt", truncation=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)

    probs = torch.sigmoid(outputs.logits)[0].numpy()

    results = []
    for i, score in enumerate(probs):
        if i < len(LABELS):
            results.append({"label": LABELS[i], "score": float(score)})

    results.sort(key=lambda x: x["score"], reverse=True)
    return results


@app.get("/health")
async def health():
    return {"status": "ok"}
