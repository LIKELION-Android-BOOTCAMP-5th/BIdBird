import { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

/**
 * Nhost Function: update-item-v2
 * 
 * 이 함수는 Nhost에서 실행되며, Supabase DB의 매물 정보를 업데이트합니다.
 * GraphQL 권한 문제를 피하기 위해 서버 사이드에서 Supabase Client를 직접 사용합니다.
 */
export default async (req: Request, res: Response) => {
  console.log(`[DEBUG] Received update request: ${req.method} ${req.url}`);
  
  // 1. CORS 처리
  if (req.method === 'OPTIONS') {
    return res.status(200).send('ok');
  }

  try {
    // 2. 요청 바디 데이터 추출 및 로깅
    const body = req.body;
    console.log(`[ULTRA-DEBUG] [STEP 1: Update Request Arrival] Method: ${req.method}, URL: ${req.url}`);
    console.log(`[ULTRA-DEBUG] [STEP 2: Raw Update Body Received]`, JSON.stringify(body, null, 2));

    if (!body || !body.itemId) {
      console.error("[ERROR] Missing itemId in request body");
      return res.status(400).json({ error: "Missing itemId", details: "Item update requires a valid itemId." });
    }

    const {
      itemId,
      title,
      description,
      startPrice,
      buyNowPrice,
      keywordType,
      auctionDurationHours,
      imageUrls,
      documentUrls,
      thumbnailUrl,
    } = body;

    console.log(`[ULTRA-DEBUG] [STEP 3: Parsed Update Fields]`, {
      itemId,
      title: title || 'KEEP_EXISTING?',
      startPrice,
      buyNowPrice,
      imagesCount: imageUrls?.length || 0,
      docsCount: documentUrls?.length || 0,
    });

    // 3. 환경 변수 확인
    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    console.log(`[ULTRA-DEBUG] [STEP 4: Environment Check]`, {
      hasUrl: !!supabaseUrl,
      hasKey: !!serviceRoleKey
    });

    if (!supabaseUrl || !serviceRoleKey) {
      console.error("[ERROR] Missing Supabase environment variables in Nhost Secrets");
      return res.status(500).json({ error: "Server environment not configured" });
    }

    // 4. Supabase 클라이언트 초기화
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    
    // 5. 판매자 ID 확인 (보안 체크)
    const sellerId = req.nhost?.auth?.getUser()?.id || body.sellerId;
    console.log(`[ULTRA-DEBUG] [STEP 5: Auth Check] SellerID: ${sellerId || 'NOT FOUND'}`);

    if (!sellerId) {
      console.error("[ERROR] No seller ID found");
      return res.status(401).json({ error: "Unauthorized: No seller ID found" });
    }

    console.log(`[ULTRA-DEBUG] [STEP 6: Updating items_detail] ItemID: ${itemId}`);

    // 6. items_detail 업데이트
    const updatePayload = {
      title: title,
      description: description,
      start_price: Number(startPrice),
      buy_now_price: buyNowPrice && buyNowPrice > 0 ? Number(buyNowPrice) : null,
      keyword_type: Number(keywordType),
      auction_duration_hours: Number(auctionDurationHours),
      thumbnail_image: thumbnailUrl,
      updated_at: new Date().toISOString()
    };
    
    console.log(`[ULTRA-DEBUG] [STEP 7: Update Payload]`, JSON.stringify(updatePayload, null, 2));

    const { error: updateError } = await supabase
      .from('items_detail')
      .update(updatePayload)
      .eq('item_id', itemId)
      .eq('seller_id', sellerId); // 보안: 본인 매물만 수정 가능

    if (updateError) {
      console.error("[ERROR] Update Detail failed:", JSON.stringify(updateError, null, 2));
      throw updateError;
    }

    console.log(`[ULTRA-DEBUG] [STEP 8: Refreshing Images/Docs] Deleting old assets first...`);

    // 7. 기존 이미지 및 문서 삭제
    await supabase.from('item_images').delete().eq('item_id', itemId);
    await supabase.from('item_documents').delete().eq('item_id', itemId);

    // 8. 이미지 다시 삽입
    if (imageUrls && imageUrls.length > 0) {
      console.log(`[ULTRA-DEBUG] [STEP 9: Re-inserting Images] Count: ${imageUrls.length}`);
      const imageObjects = imageUrls.map((url: string, index: number) => ({
        item_id: itemId,
        image_url: url,
        sort_order: index + 1
      }));
      const { error: imgError } = await supabase.from('item_images').insert(imageObjects);
      if (imgError) console.error("[ERROR] Image Insert failed:", imgError);
    }

    // 9. 문서 다시 삽입
    if (documentUrls && documentUrls.length > 0) {
      console.log(`[ULTRA-DEBUG] [STEP 10: Re-inserting Documents] Count: ${documentUrls.length}`);
      const documentObjects = documentUrls.map((url: string) => ({
        item_id: itemId,
        document_url: url,
        document_name: url.split('/').pop()?.split('_').pop() || 'certificate.pdf',
        file_type: 'pdf',
        file_size: 0,
        uploaded_at: new Date().toISOString()
      }));
      const { error: docError } = await supabase.from('item_documents').insert(documentObjects);
      if (docError) console.error("[ERROR] Document Insert failed:", docError);
    }

    console.log(`[ULTRA-DEBUG] [SUCCESS] Item updated successfully: ${itemId}`);
    return res.status(200).json({ 
      success: true,
      itemId: itemId 
    });

  } catch (err: any) {
    console.error("[CRITICAL ERROR] Internal Server Error in update-item-v2:", err);
    return res.status(500).json({ 
      error: "Internal server error",
      message: err.message
    });
  }
};
