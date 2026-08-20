# Species Gap

동물실험과 인간 임상 결과의 불일치 원인을 분석하고, 종간 차이 예측 플랫폼을 개발하기 위한 연구 저장소입니다.

## 연구 목표

- 임상·약물 데이터에서 종간 불일치 사례 구축
- 단백질 구조 차이 분석
- 유전체 문맥 및 유전자 조절 네트워크 차이 분석
- 실험 및 과거 임상 사례를 이용한 결과 검증
- R Shiny 기반 결과 조회 웹페이지 개발

## 폴더 구조

```text
species-gap/
├─ data/
│  ├─ raw/             # 다운로드한 원본 데이터
│  └─ processed/       # 분석용 가공 데이터
├─ analysis/
│  ├─ target_mining/
│  ├─ structural_gap/
│  ├─ genomic_context/
│  ├─ network_gap/
│  └─ validation/
├─ web/                # R Shiny 웹페이지
└─ outputs/            # 그림, 보고서, 논문, 배포본
```

## 작업 원칙

- `data/raw`의 원본 데이터는 수정하지 않습니다.
- 재현 가능한 분석 코드는 `analysis`에 저장합니다.
- 생성된 결과는 `outputs`에 저장합니다.
- 개인정보와 BrainPool 행정 문서는 이 저장소에 올리지 않습니다.

## 현재 할 일

- [ ] 데이터 출처 및 다운로드 방법 정리
- [ ] 분석 환경 구성
- [ ] Target mining 파이프라인 설계
- [ ] R Shiny 기본 화면 구성
