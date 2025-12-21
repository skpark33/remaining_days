# Remaining Days V2.0: 은퇴 플래너 개발 계획서 (Development Plan)

본 문서는 'Remaining Days'를 '은퇴 플래너'로 진화시키기 위한 단계별 상세 개발 계획입니다.
각 단계(Phase)는 독립적으로 실행 가능하며, **각 단계 완료 시 반드시 사용자의 확인(Confirm)과 Git 저장(Commit & Push)** 절차를 거쳐야 합니다.

---

## **Phase 2.1: 데이터베이스 구축 및 기초 공사 (Foundation)**
이 단계에서는 앱의 데이터들이 안정적으로 저장될 수 있도록 로컬 데이터베이스를 도입하고 구조를 잡습니다.

- [ ] **데이터베이스 선정 및 설정**
    - [ ] `drift` 또는 `hive` 라이브러리 검토 및 선정 (관계형 데이터 적합성 고려).
    - [ ] DB 연결 및 초기화 코드 작성 (`DatabaseHelper` 등).
- [ ] **데이터 모델링 (Schema Design)**
    - [ ] **UserAsset (자산)**: 타입(현금/부동산/주식), 금액, 메모.
    - [ ] **RetirementGoal (은퇴 목표)**: 목표 금액, 예상 연금액.
    - [ ] **BucketItem (버킷리스트)**: 제목, 설명, 달성여부, 이미지경로.
- [ ] **마이그레이션 전략**
    - [ ] 기존 `SharedPreference` 데이터(Target Dates)의 마이그레이션 또는 공존 전략 수립.
- [ ] **Phase 2.1 완료 점검 (Completion Check)**
    - [ ] **사용자 확인 (User Confirm)**: DB 파일 생성 및 CRUD 테스트 결과 확인.
    - [ ] **Git 저장**: `git commit -m "feat: setup database foundation"` & `git push`.

---

## **Phase 2.2: 은퇴 자금 계산기 (Retirement Fund Calculator)**
사용자가 자신의 은퇴 준비 상태를 숫자로 파악할 수 있는 핵심 기능을 구현합니다.

- [ ] **기초 데이터 입력 UI**
    - [ ] 은퇴 목표 시기 및 목표 월 생활비 입력 폼.
    - [ ] 예상 연금(국민/퇴직/개인) 수령액 입력 폼.
- [ ] **자산 입력 관리 기능**
    - [ ] 현재 보유 자산(순자산) 입력 및 수정 기능.
    - [ ] 자산 리스트 CRUD (추가/수정/삭제) 구현.
- [ ] **계산 로직 구현**
    - [ ] 은퇴 시점까지의 필요 자금 총액 계산.
    - [ ] 현재 자산 + 예상 연금 대비 **부족 자금(Gap) 계산**.
    - [ ] 매월 저축해야 할 권장 금액 산출 알고리즘.
- [ ] **Phase 2.2 완료 점검 (Completion Check)**
    - [ ] **사용자 확인 (User Confirm)**: 입력값에 따른 계산 결과 정확성 검증.
    - [ ] **Git 저장**: `git commit -m "feat: implement retirement fund calculator"` & `git push`.

---

## **Phase 2.3: 예상 지역의료보험료 계산기 (Health Insurance)**
은퇴 후 지역가입자로 전환 시 가장 큰 부담이 되는 건강보험료를 미리 예측합니다.

- [ ] **입력 UI 구현**
    - [ ] **재산 정보**: 주택/건물/토지 과세표준액, 자동차 가액 입력.
    - [ ] **소득 정보**: 연금 소득, 이자/배당 소득, 기타 사업 소득 입력.
    - [ ] **자동차 등급**: 배기량, 차량 가액 등 필요한 세부 정보 입력.
- [ ] **보험료 산출 로직 (한국 건강보험공단 기준)**
    - [ ] 재산 점수 환산 로직 구현 (과표 기준 구간별 점수표 적용).
    - [ ] 소득 점수 또는 소득 정률제 계산 로직.
    - [ ] 지역가입자 보험료 부과 점수당 금액($) 적용 및 자동 계산.
    - [ ] 장기요양보험료 추가 계산.
- [ ] **Phase 2.3 완료 점검 (Completion Check)**
    - [ ] **사용자 확인 (User Confirm)**: 실제 모의 계산기와 결과 비교/검증.
    - [ ] **Git 저장**: `git commit -m "feat: add health insurance calculator"` & `git push`.

---

## **Phase 2.4: 버킷리스트 및 습관 (Life Goals)**
은퇴 준비는 돈뿐만 아니라 '무엇을 할 것인가'도 중요합니다.

- [ ] **버킷리스트 기능**
    - [ ] 버킷리스트 아이템 추가/수정/삭제 UI.
    - [ ] 이미지 첨부 기능 (Gallery Picker).
    - [ ] '달성 완료' 체크 및 축하 효과.
- [ ] **습관 트래커 (Optional)**
    - [ ] 매일/매주 반복 수행할 은퇴 준비 습관 등록.
    - [ ] 간단한 수행 체크(O/X) 기능.
- [ ] **Phase 2.4 완료 점검 (Completion Check)**
    - [ ] **사용자 확인 (User Confirm)**: 리스트 저장 및 이미지 연동 확인.
    - [ ] **Git 저장**: `git commit -m "feat: add bucket list feature"` & `git push`.

---

## **Phase 2.5: 대시보드 및 시각화 (Dashboard & Visualization)**
앱을 켰을 때 한눈에 인생의 진행 상황을 볼 수 있는 메인 화면을 만듭니다.

- [ ] **Life Clock (인생 시계) 위젯**
    - [ ] 현재 나이/기대 수명을 24시간으로 환산하여 시각화 (Gauge Chart).
- [ ] **종합 차트 구현**
    - [ ] 자산 증가 추이 그래프 (Line Chart).
    - [ ] 은퇴 자금 달성률 그래프 (Pie/Radial Chart).
- [ ] **메인 대시보드 통합**
    - [ ] 기존 'Target Dates'와 새로운 차트들을 조화롭게 배치.
    - [ ] UI/UX 폴리싱 (테마 적용, 애니메이션).
- [ ] **Phase 2.5 완료 점검 (Completion Check)**
    - [ ] **사용자 확인 (User Confirm)**: 전체적인 앱 사용성 및 심미성 검증.
    - [ ] **Git 저장**: `git commit -m "feat: finalize dashboard and visualization"` & `git push`.

---

## **Phase 2.6: 배포 준비 및 마무리 (Release)**

- [ ] **품질 보증 (QA)**
    - [ ] 전체 기능 통합 테스트.
    - [ ] 다국어(영/한/일) 누락 확인.
- [ ] **문서화**
    - [ ] 앱 사용 가이드 작성 (Help/FAQ).
- [ ] **최종 완료 (Grand Deployment)**
    - [ ] **사용자 최종 승인**.
    - [ ] **Git Tagging**: `git tag v2.0.0` & `git push --tags`.
