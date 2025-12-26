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

/**
 * 30일이 지난 탈퇴 사용자 데이터 자동 삭제
 * 매일 자정(한국 시간 기준)에 실행
 */
exports.deleteExpiredUsers = functions.pubsub
  .schedule('0 0 * * *') // 매일 자정 (UTC 기준)
  .timeZone('Asia/Seoul') // 한국 시간대
  .onRun(async (context) => {
    console.log('[Delete Expired Users] Starting scheduled deletion...');

    try {
      const db = admin.firestore();
      const now = admin.firestore.Timestamp.now();
      const thirtyDaysAgo = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - (30 * 24 * 60 * 60 * 1000)
      );

      // 30일이 지난 탈퇴 사용자 조회
      const usersSnapshot = await db.collection('users')
        .where('isDeleted', '==', true)
        .where('deletedAt', '<=', thirtyDaysAgo)
        .get();

      if (usersSnapshot.empty) {
        console.log('[Delete Expired Users] No expired users found.');
        return null;
      }

      console.log(`[Delete Expired Users] Found ${usersSnapshot.size} expired users.`);

      // 각 사용자의 모든 데이터 삭제
      const deletePromises = usersSnapshot.docs.map(async (userDoc) => {
        const userId = userDoc.id;
        console.log(`[Delete Expired Users] Deleting user: ${userId}`);

        try {
          // 1. 청소 의뢰 삭제
          const requestsSnapshot = await db.collection('cleaning_requests')
            .where('authorId', '==', userId)
            .get();
          for (const doc of requestsSnapshot.docs) {
            await doc.ref.delete();
          }
          console.log(`  - Deleted ${requestsSnapshot.size} cleaning requests`);

          // 2. 지원자 목록에서 제거
          const applicantsSnapshot = await db.collection('cleaning_requests')
            .where('applicants', 'array-contains', userId)
            .get();
          for (const doc of applicantsSnapshot.docs) {
            await doc.ref.update({
              applicants: admin.firestore.FieldValue.arrayRemove(userId)
            });
          }
          console.log(`  - Removed from ${applicantsSnapshot.size} applicant lists`);

          // 3. 청소 대기 프로필 삭제
          const staffsSnapshot = await db.collection('cleaning_staffs')
            .where('authorId', '==', userId)
            .get();
          for (const doc of staffsSnapshot.docs) {
            await doc.ref.delete();
          }
          console.log(`  - Deleted ${staffsSnapshot.size} staff profiles`);

          // 4. 청소 노하우 삭제
          const knowhowsSnapshot = await db.collection('cleaning_knowhows')
            .where('authorId', '==', userId)
            .get();
          for (const doc of knowhowsSnapshot.docs) {
            await doc.ref.delete();
          }
          console.log(`  - Deleted ${knowhowsSnapshot.size} knowhows`);

          // 5. 청소 추천 삭제
          const recommendationsSnapshot = await db.collection('cleaning_recommendations')
            .where('authorId', '==', userId)
            .get();
          for (const doc of recommendationsSnapshot.docs) {
            await doc.ref.delete();
          }
          console.log(`  - Deleted ${recommendationsSnapshot.size} recommendations`);

          // 6. 채팅방 및 메시지 삭제
          const chatRoomsSnapshot = await db.collection('chat_rooms')
            .where('participants', 'array-contains', userId)
            .get();
          for (const chatDoc of chatRoomsSnapshot.docs) {
            // 메시지 서브컬렉션 삭제
            const messagesSnapshot = await chatDoc.ref.collection('messages').get();
            for (const msgDoc of messagesSnapshot.docs) {
              await msgDoc.ref.delete();
            }
            // 채팅방 삭제
            await chatDoc.ref.delete();
          }
          console.log(`  - Deleted ${chatRoomsSnapshot.size} chat rooms`);

          // 7. 사용자 문서 삭제 (마지막)
          await userDoc.ref.delete();
          console.log(`  - Deleted user document`);

          console.log(`[Delete Expired Users] Successfully deleted all data for user: ${userId}`);
        } catch (error) {
          console.error(`[Delete Expired Users] Error deleting user ${userId}:`, error);
          // 개별 사용자 삭제 실패해도 계속 진행
        }
      });

      await Promise.all(deletePromises);
      console.log('[Delete Expired Users] Completed scheduled deletion.');
      return null;

    } catch (error) {
      console.error('[Delete Expired Users] Fatal error:', error);
      throw error;
    }
  });
