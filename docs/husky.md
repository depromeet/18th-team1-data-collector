# Husky 사용 가이드

> 18th-team1-data-collector 프로젝트의 Git Hook 관리 문서입니다.

## 목적

이 레포는 n8n workflow JSON, PostgreSQL SQL, Python FastAPI 모델 API를 함께 관리합니다. Husky는 커밋/푸시 전에 최소한의 정적 검증을 실행해서 깨진 workflow JSON이나 Python 문법 오류가 원격에 올라가는 일을 줄입니다.

## 초기 설정

```bash
npm install
```

`package.json`의 `prepare` 스크립트가 `.husky/` 훅을 활성화합니다.

## 커밋 메시지

Conventional Commits 형식을 사용합니다.

```bash
git commit -m "feat: 명문장 추출 워크플로우 추가"
```

`commit-msg` 훅이 타입을 검증하고 이모지를 자동으로 붙입니다.

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

## pre-commit

현재 실행 내용:

1. `gitleaks`가 설치되어 있으면 staged 변경의 비밀키를 검사합니다.
2. `jq`가 설치되어 있으면 `n8n/*.json` 문법을 검사합니다.
3. `python3`가 설치되어 있으면 `model/emotion/app.py`, `model/embedding/app.py`를 컴파일합니다.

직접 실행하려면:

```bash
npm test
```

## pre-push

현재 실행 내용:

1. `jq`로 n8n workflow JSON 문법 검사
2. `python3 -m py_compile`로 Python 진입점 문법 검사

## 의존 도구

- Node.js 20 이상 권장
- `jq`
- `python3`
- 선택: `gitleaks`

`jq` 또는 `python3`가 없으면 해당 검증은 건너뜁니다. CI에서는 같은 검증을 명시적으로 실행하는 편이 좋습니다.
