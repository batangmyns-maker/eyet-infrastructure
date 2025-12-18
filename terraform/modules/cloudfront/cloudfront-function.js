function handler(event) {
  var request = event.request;
  if (!request) return { statusCode: 500, statusDescription: 'Internal Server Error' };
  var host = request.headers && request.headers.host ? request.headers.host.value : '';
  // CloudFront Function에서는 event.viewer.ip를 사용해야 함
  var clientIP = event.viewer && event.viewer.ip ? event.viewer.ip : '';
  // X-Forwarded-For 헤더가 있으면 우선 사용 (실제 클라이언트 IP)
  if (request.headers && request.headers['x-forwarded-for'] && request.headers['x-forwarded-for'].value) {
    var forwardedIPs = request.headers['x-forwarded-for'].value.split(',');
    if (forwardedIPs.length > 0) {
      clientIP = forwardedIPs[0].trim();
    }
  }
  
  // IP 화이트리스트 체크 (활성화된 경우) - 외부 접근 차단 기능 주석 처리
  // var whitelist = [${whitelist_array}];
  // if (whitelist.length > 0 && clientIP) {
  //   var ipAllowed = false;
  //   for (var i = 0; i < whitelist.length; i++) {
  //     var cidr = whitelist[i];
  //     if (!cidr) continue;
  //     if (cidr.indexOf('/') === -1) {
  //       // 단일 IP 주소 비교
  //       if (clientIP === cidr) {
  //         ipAllowed = true;
  //         break;
  //       }
  //     } else {
  //       // CIDR 범위 체크
  //       var cidrParts = cidr.split('/');
  //       if (cidrParts.length === 2) {
  //         var cidrIP = cidrParts[0];
  //         var mask = parseInt(cidrParts[1]);
  //         if (cidrIP && !isNaN(mask) && isIPInCIDR(clientIP, cidrIP, mask)) {
  //           ipAllowed = true;
  //           break;
  //         }
  //       }
  //     }
  //   }
  //   if (!ipAllowed) {
  //     // 화이트리스트에 없는 IP는 에러 페이지로 리다이렉트
  //     request.uri = '/* IP_WHITELIST_ERROR_PAGE */';
  //     request.querystring = '';
  //     return request;
  //   }
  // }
  
  // 루트 도메인을 www로 리다이렉트
  if (host === '${root_domain}') {
    var uri = request.uri || '/';
    var qs = request.querystring;
    var querystring = '';
    
    // 쿼리 스트링 재구성
    if (qs) {
      var qsParts = [];
      for (var key in qs) {
        if (qs.hasOwnProperty(key)) {
          var value = qs[key].value || '';
          qsParts.push(key + '=' + encodeURIComponent(value));
        }
      }
      querystring = qsParts.join('&');
    }
    
    var redirectUrl = 'https://${frontend_domain}' + uri;
    if (querystring) {
      redirectUrl += '?' + querystring;
    }
    
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: {
        'location': { value: redirectUrl }
      }
    };
  }
  
  return request;
}

// IP를 숫자로 변환하는 함수
function ipToNumber(ip) {
  if (!ip || typeof ip !== 'string') return 0;
  var ipParts = ip.split('.');
  if (ipParts.length !== 4) return 0;
  return (parseInt(ipParts[0]) << 24) +
         (parseInt(ipParts[1]) << 16) +
         (parseInt(ipParts[2]) << 8) +
         parseInt(ipParts[3]);
}

// IP가 CIDR 범위에 있는지 확인하는 함수
function isIPInCIDR(ip, cidrIP, mask) {
  if (!ip || !cidrIP || !mask || mask < 0 || mask > 32) return false;
  var ipNum = ipToNumber(ip);
  var cidrNum = ipToNumber(cidrIP);
  if (ipNum === 0 || cidrNum === 0) return false;
  var maskNum = ~((1 << (32 - mask)) - 1);
  return (ipNum & maskNum) === (cidrNum & maskNum);
}
