export type RequirementStatus = '已完成' | '已发布' | '运行中'| '已失败'

export interface RequirementItem {
  id: string
  name: string
  status: RequirementStatus
  createdAt: string
}
