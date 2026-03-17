import { http } from '@/api/http'
import { API } from '@/api/endpoints'
import {type CategoryLevelDict} from '@/types/category-levels'

type LabelSchema = {
  label_name: string;
  sub_labels: string[];
}

type CategoryLevels = {
  schemas: LabelSchema[];
}


/**
 * 类别层级字段（师兄方案）API
 *
 * 约定：后端存的是 CategoryLevelsField（List[Dict]）整体。
 */
export function getCategoryLevels() {
  return http.get<any,CategoryLevels>(API.CategoryLevels.GET);
}

export function updateCategoryLevels(payload: CategoryLevelDict[]) {
  return http.put<any, { status: string }>(API.CategoryLevels.UPDATE, payload)
}
