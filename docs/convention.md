# 프로젝트 컨벤션

## 1. 브랜치 전략

Git Flow 기반 + PR 중심 협업 방식을 사용합니다.

- `main`: 운영 배포 브랜치
- `dev`: 통합 개발 브랜치
- `feat/#이슈번호/설명`: 기능 개발
- `fix/#이슈번호/설명`: 버그 수정
- `refactor/#이슈번호/설명`: 구조 개선
- `chore/#이슈번호/설명`: 설정, 문서, 인프라 작업
- `hotfix/*`: 운영 긴급 수정

작업 흐름:

```text
이슈 생성 -> 브랜치 생성 -> 작업 -> PR -> 리뷰 -> merge(dev) -> 배포(main)
```

## 2. 커밋 컨벤션

Conventional Commits를 사용합니다. `commit-msg` 훅이 타입을 검증하고 이모지를 자동으로 붙입니다.

```text
feat: 명문장 추출 워크플로우 추가
```

허용 타입:

| 타입 | 설명 |
|------|------|
| feat | 새로운 기능 |
| fix | 버그 수정 |
| perf | 성능 개선 |
| refactor | 동작 변경 없는 구조 개선 |
| test | 테스트 추가/수정 |
| docs | 문서 수정 |
| style | 포맷팅 |
| chore | 설정/관리 작업 |
| ci | CI 변경 |
| build | 빌드 변경 |
| revert | 되돌리기 |

## 3. 프로젝트 구성

이 레포는 n8n 중심의 데이터 파이프라인입니다.

- `n8n/`: import 가능한 n8n workflow JSON
- `db/`: PostgreSQL, pgvector 스키마 초기화 SQL
- `model/embedding`: quote embedding FastAPI API
- `model/emotion`: legacy/local emotion FastAPI API
- `docs/`: 협업 문서

주요 데이터 흐름:

```text
Aladin 책 수집 -> 책 본문 기반 명문장 추출 -> 문장 검수 -> 감정 분류 -> 임베딩 저장
```

## 4. 기술 스택

- n8n
- PostgreSQL + pgvector
- Groq Chat Completions API
- FastAPI
- sentence-transformers
- transformers / PyTorch
- Husky

## 5. 코드/워크플로우 규칙

- n8n workflow JSON은 import 가능한 상태를 유지합니다.
- 외부 API key는 workflow에 직접 커밋하지 않고 n8n runtime environment 또는 credentials로 주입합니다.
- SQL은 기존 DB에 재실행해도 깨지지 않도록 `IF NOT EXISTS`와 명시적 migration을 함께 사용합니다.
- LLM 결과는 후속 단계에서 검증 가능한 형태로 저장합니다.
- 명문장 추출은 책 본문 소스에 실제 포함된 문장만 통과시킵니다.
- Python API 의존성은 `requirements.txt`에 추가합니다.
- 생성 산출물(`__pycache__`, `.pyc`)은 커밋하지 않습니다.

## 6. 검증

로컬 검증:

```bash
npm test
```

검증 내용:

- `jq`로 n8n workflow JSON 문법 검사
- `python3 -m py_compile`로 Python FastAPI 진입점 문법 검사

## 7. PR 리뷰 룰

- 최소 1명 이상 approve 후 merge합니다.
- workflow 변경 PR은 import 가능 여부와 연결 노드 흐름을 함께 확인합니다.
- DB 변경 PR은 기존 DB에 재실행했을 때의 영향을 함께 설명합니다.
