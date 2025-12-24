const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

/**
 * Toss Payments 결제 승인 (Confirm)
 * 클라이언트에서 결제 요청 후 성공 시 호출하여 최종 승인 처리
 */
exports.confirmPayment = functions.https.onCall(async (data, context) => {
  // 인증된 사용자만 호출 가능 (선택 사항, 보안 강화)
  // if (!context.auth) {
  //   throw new functions.https.HttpsError('unauthenticated', '인증된 사용자만 호출할 수 있습니다.');
  // }

  const { paymentKey, orderId, amount } = data;

  if (!paymentKey || !orderId || !amount) {
    throw new functions.https.HttpsError('invalid-argument', '필수 파라미터가 누락되었습니다.');
  }

  // Firebase Config에서 시크릿 키 가져오기
  // 설정 명령: firebase functions:config:set toss.secret_key="your_test_sk_..."
  const secretKey = functions.config().toss ? functions.config().toss.secret_key : 'test_gsk_docs_OaPz8L5KdmQXkzRz3y47BMw6'; // Default to docs test key if not set

  // Basic Auth 헤더 생성 (시크릿 키 + ':')
  const credentials = Buffer.from(`${secretKey}:`).toString('base64');

  try {
    console.log(`[Payment Confirm] Order ID: ${orderId}, Amount: ${amount}`);

    // 토스 페이먼츠 승인 API 호출
    const response = await axios.post(
      'https://api.tosspayments.com/v1/payments/confirm',
      {
        paymentKey: paymentKey,
        orderId: orderId,
        amount: Number(amount),
      },
      {
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const paymentData = response.data;
    console.log('[Payment Confirm] Success:', paymentData);

    // 결제 성공 시 Firestore에 결제 정보 저장 (cleaning_requests 컬렉션 업데이트는 클라이언트나 트리거로 처리 가능하지만, 여기서 로그를 남기는 것이 안전)
    /* 
    // 예: payments 컬렉션에 로그 저장
    await admin.firestore().collection('payments').doc(orderId).set({
      ...paymentData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: context.auth ? context.auth.uid : 'anonymous',
    });
    */

    return {
      success: true,
      data: paymentData,
    };

  } catch (error) {
    console.error('[Payment Confirm] Error:', error.response ? error.response.data : error.message);

    // 토스 API 에러 응답 전달
    if (error.response) {
      const errorData = error.response.data;
      throw new functions.https.HttpsError('aborted', errorData.message || '결제 승인 실패', errorData);
    }

    throw new functions.https.HttpsError('internal', '결제 승인 중 내부 오류가 발생했습니다.');
  }
});

/**
 * Apple Sign In Callback (Android)
 * Apple 서버로부터 받은 인증 정보를 앱으로 리다이렉트합니다.
 */
exports.appleSignInCallback = functions.https.onRequest(async (request, response) => {
  const redirect = (url) => {
    response.redirect(307, url);
  };

  if (request.method !== 'POST') {
    return response.status(405).send('Method Not Allowed');
  }

  const { code, state, id_token, user } = request.body;

  // 앱의 패키지 이름과 URL 스킴
  const packageName = 'com.gongsunginternational.cleanhai';
  const scheme = 'signinwithapple';

  // 쿼리 파라미터 구성
  const params = new URLSearchParams();
  if (code) params.append('code', code);
  if (state) params.append('state', state);
  if (id_token) params.append('id_token', id_token);
  if (user) params.append('user', user);

  // Android Intent URL 생성
  const intentUrl = `intent://callback?${params.toString()}#Intent;package=${packageName};scheme=${scheme};end`;

  redirect(intentUrl);
});
