// src/api/requirementsApi.ts
import { http } from '@/api/http'
import { API } from '@/api/endpoints'
import type { RequirementItem } from '@/types/requirement'

interface RequirementListResponse {
  items: RequirementItem[]
  total?: number
}

interface RequirementCreateResponse {
  item: RequirementItem
}

interface RequirementParseResponse {
  item: RequirementItem
}

interface RequirementRunResponse {
  item: RequirementItem
}

//NewRequirement
export type RequirementDocType =
  | 'ACL'
  | 'CVPR'
  | 'arxiv'
  | '专利'
  | '技术报告'
  | '说明书'

export const REQUIREMENT_DOC_TYPE_ALL: RequirementDocType[] = [
  'ACL',
  'CVPR',
  'arxiv',
  '专利',
  '技术报告',
  '说明书',
]

/** 新建需求 */
export interface RequirementCreateRequest {
  /** 主题/技术方向 */
  name: string

  /** 时间范围 */
  startDate?: string
  endDate?: string

  /** 文档类型 */
  docTypes: RequirementDocType[]

  /** 关键词 */
  keywords: string[]

  /** 具体需求 */
  detail: string
}

export interface RequirementReportTextBlock {
  id: string
  type: 'text'
  title: string
  content: string
}

export interface RequirementReportTableBlock {
  id: string
  type: 'table'
  title: string
  columns: string[]
  rows: string[][]
}

export type RequirementReportBlock = RequirementReportTextBlock | RequirementReportTableBlock

export interface RequirementReport {
  title: string
  summary: string
  blocks: RequirementReportBlock[]
  references: unknown[]
}

export interface RequirementReportPayload {
  success?: boolean
  report?: RequirementReport
}

export interface RequirementReportResponse {
  waiting: boolean
  id: string
  name?: string
  status?: string
  createdAt?: string
  result?: RequirementReportPayload | null
  error?: string | null
}

export function getRequirementList() {
  return http.get<any, RequirementListResponse>(API.RequirementList.LIST)
}

/** 新建需求 */
export function createRequirement(payload: RequirementCreateRequest) {
  // 兼容两种后端返回：RequirementItem 或 { item: RequirementItem }
  return http.post<any, RequirementItem | RequirementCreateResponse>(API.RequirementList.CREATE, payload)
}

/** 解析需求 */
export function parseRequirement(payload: RequirementCreateRequest) {
  return http.post<any, RequirementItem | RequirementParseResponse>(API.RequirementList.CREATE, payload)
}

/** 删除需求 */
export function removeRequirement(id: string) {
  return http.delete<any, { status: string }>(API.RequirementList.REMOVE(id))
}

/** 运行需求 */
export function runRequirement(id: string) {
  return http.post<any, RequirementItem | RequirementRunResponse>(API.RequirementList.RUN(id))
}

// 报告展示
export function getRequirementReport(id: string) {
  return http.get<any, RequirementReportResponse>(API.RequirementList.REPORT(id))
}
