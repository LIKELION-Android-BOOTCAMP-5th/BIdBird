BidBird (비드버드)
실시간 경매 및 안전한 중고 거래를 지원하는 모바일 애플리케이션 플랫폼입니다.
사용자는 물품을 등록하여 경매를 진행하거나 실시간으로 입찰에 참여할 수 있습니다.

1. 프로젝트 개요
   •실시간 입찰 시스템과 결제를 보유 한 경매 플랫폼


2. 주요 기능
   •실시간 경매 시스템
   서버 시간 동기화를 통한 정확한 입찰 마감 관리 및 실시간 최고가 갱신
   •물품 등록 및 관리
   사진 및 동영상을 포함한 상세 물품 설명 등록, 자동 압축을 통한 데이터 최적화
   •실시간 채팅
   구매자와 판매자 간 실시간 소통 및 거래 상태 공유
   • 안전 결제 (Portone)
   포트원 API 연동을 통한 결제 및 본인 인증
   •푸시 알림
   입찰 상태 변화, 낙찰 결과, 채팅 메시지 실시간 수신 (FCM)
   •회원가입 및 인증
   소셜 로그인(Google, Apple, Kakao) 및 프로필 관리

3. 대상 사용자
   • 경매 입찰자
   희귀하거나 가치 있는 물품을 합리적인 가격에 구매하려는 사용자
   • 경매 판매자
   보유 물품을 경매 방식으로 효율적으로 판매하려는 사용자
   •일반 거래자
   채팅과 안전 결제를 결합한 중고 거래를 원하는 사용자

4. 기술 스택
   • Frontend: Flutter 3.9.2 이상, Provider, GoRouter
   • Backend/BaaS: Supabase(Database, Auth), Firebase(FCM, Remote)
   • API/External: Nhost, GraphQL, Portone v1, v2
   • Media: Cloudinary(Image, Video), Video Player
   • Utils: Event Bus, Shared Preferences, Secure Storage, Intl

5. 아키텍처 개요
   Clean Architecture 원칙을 준수하며 Feature 중심 구조로 설계되었습니다.
   • Presentation Layer
   UI 위젯 및 ViewModel(Provider) 기반 상태 관리
   •Domain Layer
   Entity, UseCase 정의 및 비즈니스 로직 관리
   •Data Layer
   Repository 구현체 및 외부 API, Local Storage 연동
   •Core Layer
   공통 Manager, Service, Utility, Routing 관리