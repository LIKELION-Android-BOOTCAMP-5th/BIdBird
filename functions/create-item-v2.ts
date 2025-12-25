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
  // CORS 처리는 Nhost에서 기본적으로 처리되지만 명시적 처리도 가능합니다.
  if (req.method === 'OPTIONS') {
    return res.status(200).send('ok');
  }

  try {
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
    } = req.body;

    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !serviceRoleKey) {
      console.error("Missing Supabase environment variables");
      return res.status(500).json({ 
        error: "Server environment not configured",
        details: "Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Nhost Secrets"
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const durationMinutes = Math.round((Number(auctionDurationHours) || 0) * 60);

    // Nhost Auth Context에서 사용자 ID를 가져오거나 body에서 가져옵니다.
    const sellerId = req.nhost?.auth?.getUser()?.id || req.body.sellerId;

    if (!sellerId) {
      return res.status(401).json({ error: "Unauthorized: No seller ID found" });
    }

    console.log(`[DEBUG] Creating item for seller ID: ${sellerId}`);

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

    return res.status(200).json({ 
      itemId: itemId,
      thumbnailUrl: thumbnailUrl 
    });

  } catch (err: any) {
    console.error("Internal Server Error:", err);
    return res.status(500).json({ 
      error: "Internal server error",
      message: err.message 
    });
  }
};
