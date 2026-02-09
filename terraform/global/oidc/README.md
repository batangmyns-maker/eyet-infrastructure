oidc 디렉토리 내에서 스테이트를 따로 관리하기 때문에
global/oidc 폴더에서 terraform init, plan, apply 실행해야 함
enviroment/global로 분리하지 않은 이유는 예외적으로 oidc 하나만 이 방식으로 관리하기 때문,
만약 global 요소가 많아진다면 modules에 공통요소를 모듈화하여 사용할 수 있도록 변경하면서 enviroment/global로 분리할 예정
