import { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

/**
 * Nhost Function: create-item-v2 (REFACTORED as Asset Handler)
 * 
 * 이 함수는 이제 상품 메타데이터를 받지 않고, 
 * 생성된 itemId와 documentUrls만 받아 Nhost 전용 처리를 수행합니다.
 */
export default async (req: Request, res: Response) => {
  if (req.method === 'OPTIONS') return res.status(200).send('ok');

  try {
    const { itemId, documentUrls, documentNames } = req.body;
    console.log(`[ASSET-HANDLER] Received assets for Item: ${itemId}, Docs: ${documentUrls?.length || 0}, Names: ${documentNames?.length || 0}`);

    if (!itemId) {
      return res.status(400).json({ error: "Missing itemId" });
    }

    // PDF가 없을 경우 바로 성공 반환
    if (!documentUrls || documentUrls.length === 0) {
      return res.status(200).json({ success: true, message: "No documents to process" });
    }

    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !serviceRoleKey) {
      return res.status(500).json({ error: "Server environment not configured" });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // 1. 기존 문서 삭제 (RPC 호출 등으로 이미 생성되었을 경우 대비)
    await supabase.from('item_documents').delete().eq('item_id', itemId);
 
    // 2. 문서 정보 저장
    const documentObjects = documentUrls.map((url: string, index: number) => ({
      item_id: itemId,
      document_url: url,
      document_name: (documentNames && documentNames[index]) || url.split('/').pop()?.split('_').pop() || 'certificate.pdf',
      file_type: 'pdf',
      file_size: 0,
      uploaded_at: new Date().toISOString()
    }));

    const { error: docError } = await supabase.from('item_documents').insert(documentObjects);
    
    if (docError) {
      console.error("[ERROR] Document Sync failed:", docError);
      return res.status(500).json({ error: "Document sync failed", details: docError });
    }

    return res.status(200).json({ success: true, itemId, version: "v4_lightweight" });

  } catch (err: any) {
    console.error("[CRITICAL ERROR]", err);
    return res.status(500).json({ error: "Internal server error", message: err.message });
  }
};
