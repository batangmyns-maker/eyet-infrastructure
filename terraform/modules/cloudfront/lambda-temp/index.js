'use strict';

/**
 * Lambda@Edge 함수: IP 화이트리스트 체크
 * viewer-request 이벤트에서 실행되어 IP를 확인하고,
 * 화이트리스트에 없는 IP는 403 에러를 반환합니다.
 * 
 * 주의: Lambda@Edge는 환경 변수를 지원하지 않으므로
 * IP 목록이 코드에 직접 포함됩니다.
 */

// IP 주소를 숫자로 변환하는 함수
function ipToNumber(ip) {
    const parts = ip.split('.');
    return (parseInt(parts[0]) << 24) +
           (parseInt(parts[1]) << 16) +
           (parseInt(parts[2]) << 8) +
           parseInt(parts[3]);
}

// CIDR 네트워크와 마스크를 파싱하는 함수
function parseCIDR(cidr) {
    const [ip, mask] = cidr.split('/');
    const ipNum = ipToNumber(ip);
    const maskNum = ~((1 << (32 - parseInt(mask))) - 1);
    const networkNum = ipNum & maskNum;
    return { network: networkNum, mask: maskNum };
}

// IP가 CIDR 범위에 있는지 확인하는 함수
function isIPInCIDR(ip, cidr) {
    const { network, mask } = parseCIDR(cidr);
    const ipNum = ipToNumber(ip);
    return (ipNum & mask) === network;
}

// IP가 화이트리스트에 있는지 확인하는 함수
function isIPWhitelisted(clientIP, whitelist) {
    if (!whitelist || whitelist.length === 0) {
        return true; // 화이트리스트가 비어있으면 모든 IP 허용
    }
    
    return whitelist.some(cidr => {
        if (cidr.includes('/')) {
            return isIPInCIDR(clientIP, cidr);
        } else {
            // CIDR 형식이 아니면 정확히 일치하는지 확인
            return clientIP === cidr;
        }
    });
}

exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;
    
    // 클라이언트 IP 주소 가져오기
    const clientIP = request.clientIp;
    
    // IP 화이트리스트 (Terraform에서 동적으로 주입됨)
    const whitelist = ['112.222.28.115/32'];
    
    // IP 화이트리스트 체크
    if (!isIPWhitelisted(clientIP, whitelist)) {
        // 화이트리스트에 없는 IP는 요청 URI를 coming-soon.html로 변경
        // 이렇게 하면 CloudFront가 S3에서 coming-soon.html을 가져와서 반환
        request.uri = "/coming-soon.html";
        request.querystring = ''; // 쿼리 스트링 제거
        
        callback(null, request);
        return;
    }
    
    // 화이트리스트에 있으면 요청을 그대로 통과
    callback(null, request);
};

