import { http } from '@/api/http'
import { API } from '@/api/endpoints'
import type { TableItem } from '@/types/type/types'
interface ParseResponse {
  parse_id: string;
  filename: string;
  doc_type: string;
  md: string;
  labels: string;
}

// 入库给后端类型还没设计：先把“前端需要提交的最小字段”定下来
interface IngestRequest {
  parse_id?: string | null;
  filename: string;
  doc_type: string;
  md: string;
  labels: string;
}

// 入库返回也先占位，后端定了再补充
interface IngestResponse {
  doc_id?: string;
  status?: "ok" | "failed" | string;
}
export function parseFile(form: FormData) {
  return http.post<any, ParseResponse>(API.UploadParse.PARSE, form)
}

export function ingestFile({
  parse_id,
  filename,
  doc_type,
  md,
  labels,
}: IngestRequest) {
  const payload = {
    parse_id,
    filename,
    doc_type,
    md,
    labels,
  }
  return http.post<any, IngestResponse>(API.UploadParse.INGEST, payload)
}
export function getFileList() {
  return http.get<any, TableItem[]>(API.Home.TableList)
}