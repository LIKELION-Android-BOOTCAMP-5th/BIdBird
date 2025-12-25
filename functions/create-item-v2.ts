import { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

/**
 * Nhost Function: create-item-v2
 * 
 * 이 함수는 Nhost에서 실행되며, Supabase DB의 create_item_v2 RPC를 호출합니다.
 * 
 * @param req Express Request
 * @param res Express Response
 */
export default async (req: Request, res: Response) => {
  console.log(`[DEBUG] Received request: ${req.method} ${req.url}`);
  
  // 1. CORS 처리
  if (req.method === 'OPTIONS') {
    return res.status(200).send('ok');
  }

  try {
    // 2. 요청 바디 데이터 추출 및 로깅
    const body = req.body;
    console.log(`[ULTRA-DEBUG] [STEP 1: Request Arrival] Method: ${req.method}, URL: ${req.url}`);
    console.log(`[ULTRA-DEBUG] [STEP 2: Raw Body Received]`, JSON.stringify(body, null, 2));

    if (!body || Object.keys(body).length === 0) {
      console.error("[ERROR] Empty or missing request body");
      return res.status(400).json({ error: "Missing request body", details: "The body received by the function was empty or null." });
    }

    const {
      title,
      description,
      startPrice,
      buyNowPrice,
      keywordType,
      auctionDurationHours,
      imageUrls,
      documentUrls,
      primaryImageIndex,
      thumbnailUrl,
    } = body;

    console.log(`[ULTRA-DEBUG] [STEP 3: Parsed Fields]`, {
      title: title || 'MISSING',
      description: description ? 'PRESENT' : 'MISSING',
      startPrice,
      buyNowPrice,
      keywordType,
      auctionDurationHours,
      imagesCount: imageUrls?.length || 0,
      docsCount: documentUrls?.length || 0,
    });

    // 3. 환경 변수 확인
    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    console.log(`[ULTRA-DEBUG] [STEP 4: Environment Check]`, {
      hasUrl: !!supabaseUrl,
      hasKey: !!serviceRoleKey,
      urlPrefix: supabaseUrl ? supabaseUrl.substring(0, 15) + '...' : 'NONE'
    });

    if (!supabaseUrl || !serviceRoleKey) {
      console.error("[ERROR] Missing Supabase environment variables in Nhost Secrets");
      return res.status(500).json({ 
        error: "Server environment not configured",
        details: "Please ensure SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set in Nhost Settings -> Secrets"
      });
    }

    // 4. Supabase 클라이언트 초기화
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const durationMinutes = Math.round((Number(auctionDurationHours) || 0) * 60);

    // 5. 판매자 ID 확인
    const sellerId = req.nhost?.auth?.getUser()?.id || body.sellerId;
    console.log(`[ULTRA-DEBUG] [STEP 5: Auth Check] SellerID: ${sellerId || 'NOT FOUND'}`);

    if (!sellerId) {
      console.error("[ERROR] No seller ID found in token or body");
      return res.status(401).json({ error: "Unauthorized: No seller ID found", details: "Function could not identify the user. Check if you are logged in or passing sellerId explicitly." });
    }

    console.log(`[ULTRA-DEBUG] [STEP 6: Calling Supabase RPC] RPC Name: create_item_v2`);

    // 6. Supabase RPC 호출
    const rpcParams = {
      p_seller_id: sellerId,
      p_title: title,
      p_description: description,
      p_start_price: Number(startPrice),
      p_buy_now_price: buyNowPrice && buyNowPrice > 0 ? Number(buyNowPrice) : null,
      p_keyword_type: Number(keywordType),
      p_duration_minutes: durationMinutes,
      p_thumbnail_url: thumbnailUrl,
      p_image_urls: imageUrls || [],
      p_document_urls: documentUrls || []
    };
    
    console.log(`[ULTRA-DEBUG] [STEP 7: RPC Params]`, JSON.stringify(rpcParams, null, 2));

    const { data: itemId, error: rpcError } = await supabase.rpc("create_item_v2", rpcParams);

    if (rpcError) {
      console.error("[ERROR] Supabase RPC execution failed:", JSON.stringify(rpcError, null, 2));
      return res.status(500).json({ 
        error: `Database RPC Error: ${rpcError.message}`,
        details: rpcError,
        hint: rpcError.hint 
      });
    }

    console.log(`[ULTRA-DEBUG] [SUCCESS] Item created successfully with ID: ${itemId}`);
    return res.status(200).json({ 
      success: true,
      itemId: itemId,
      thumbnailUrl: thumbnailUrl 
    });

  } catch (err: any) {
    console.error("[CRITICAL ERROR] Internal Server Error in create-item-v2:", err);
    return res.status(500).json({ 
      error: "Internal server error",
      message: err.message,
      stack: err.stack
    });
  }
};
