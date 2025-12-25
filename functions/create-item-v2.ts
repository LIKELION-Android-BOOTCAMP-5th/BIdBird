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
    console.log(`[DEBUG] Request Body: ${JSON.stringify(body)}`);

    if (!body) {
      console.error("Missing request body");
      return res.status(400).json({ error: "Missing request body" });
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

    // 3. 환경 변수 확인
    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !serviceRoleKey) {
      console.error("Missing Supabase environment variables");
      return res.status(500).json({ 
        error: "Server environment not configured",
        details: "Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Nhost Secrets"
      });
    }

    // 4. Supabase 클라이언트 초기화
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const durationMinutes = Math.round((Number(auctionDurationHours) || 0) * 60);

    // 5. 판매자 ID 확인
    const sellerId = req.nhost?.auth?.getUser()?.id || body.sellerId;

    if (!sellerId) {
      console.error("No seller ID found");
      return res.status(401).json({ error: "Unauthorized: No seller ID found" });
    }

    console.log(`[DEBUG] Calling RPC create_item_v2 for seller: ${sellerId}`);

    // 6. Supabase RPC 호출
    const { data: itemId, error: rpcError } = await supabase.rpc("create_item_v2", {
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
    });

    if (rpcError) {
      console.error("RPC Error:", rpcError);
      return res.status(500).json({ 
        error: `Database error: ${rpcError.message}`,
        hint: rpcError.hint 
      });
    }

    console.log(`[SUCCESS] Item created: ${itemId}`);
    return res.status(200).json({ 
      itemId: itemId,
      thumbnailUrl: thumbnailUrl 
    });

  } catch (err: any) {
    console.error("Internal Server Error:", err);
    return res.status(500).json({ 
      error: "Internal server error",
      message: err.message,
      stack: err.stack
    });
  }
};
