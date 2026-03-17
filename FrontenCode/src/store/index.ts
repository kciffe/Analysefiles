import { defineStore } from "pinia";
import { computed, ref } from "vue";
// import type { CategoryLevelsField } from "@/types/type/types";
import { type CategoryLevelDict } from "@/types/category-levels";
type CategoryLevelsField = CategoryLevelDict[];
import {
  getCategoryLevels,
  updateCategoryLevels,
} from "@/api/modules/categoryLevelsApi";

/**
 * UploadParseByMD级联选择组件
 * Element Plus Cascader 选项类型
 * - 层级不固定：children 递归即可
 */
export interface CategoryCascaderOption {
  label: string;
  value: string;
  children?: CategoryCascaderOption[];
}
function initState() {
  return {
    iscollapsed: false,
  };
}

/**
 * 师兄结构（levels） -> Element Plus Cascader options
 * - 根节点来自 levels[0] 的 key
 * - 子节点来自每层 dict 的 value（childrenNameList）
 */
function levelsToCascaderOptions(
  levels: CategoryLevelsField,
): CategoryCascaderOption[] {
  if (!levels || levels.length === 0) return [];

  const rootMap = levels[0] || {};
  const rootNames = Object.keys(rootMap);

  const build = (name: string, level: number): CategoryCascaderOption => {
    const idx = level - 1;
    const map = levels[idx] || {};
    const childrenNames = map[name] || [];
    const children = childrenNames.map((c) => build(c, level + 1));

    return {
      label: name,
      value: name,
      children: children.length ? children : undefined,
    };
  };

  return rootNames.map((r) => build(r, 1));
}

export const useAllDataStore = defineStore("allData", () => {
  // ref 被换为 state属性
  // computed 被换为 getter属性
  // function 被换为    action属性
  const state = ref(initState());

  // ====== Category Levels（师兄字段） ======
  const categoryLevels = ref<CategoryLevelsField>([]);
  const categoryLoaded = ref(false);
  const categoryLoading = ref(false);

  const categoryCascaderOptions = computed<CategoryCascaderOption[]>(() => {
    return levelsToCascaderOptions(categoryLevels.value);
  });

  //写入store
  function setCategoryLevels(next: CategoryLevelsField) {
    categoryLevels.value = next ? next : [];
    categoryLoaded.value = true;
  }

  /**
   * 拉取分类 levels（默认带缓存）
   * - force=true：无条件重新请求
   */
  async function fetchCategoryLevels(
    force = false,
  ): Promise<CategoryLevelsField> {
    //force 是一个强制刷新开关，用于控制“走缓存还是重新请求”。
    if (!force && categoryLoaded.value) return categoryLevels.value;

    categoryLoading.value = true;
    try {
      const levels = await getCategoryLevels();
      // 你们项目的 http 拦截器通常会“剥壳返回 data”，所以这里直接当作 CategoryLevelsField
      // console.log(levels);
      const schemas = levels.schemas;
      const categoryLevelsField = schemas.map((schema) => {
        return {
          [schema.label_name]: schema.sub_labels,
        };
      });

      setCategoryLevels(categoryLevelsField);
      return categoryLevels.value;
    } finally {
      categoryLoading.value = false;
    }
  }

  /** 保存分类 levels，并同步更新 store（供其他页面级联选择器立即生效） */
  async function saveCategoryLevels(next: CategoryLevelsField) {
    const payload = next ? next : [];
    await updateCategoryLevels(payload);
    setCategoryLevels(payload);
  }

  return {
    state,

    // category
    categoryLevels,
    categoryLoaded,
    categoryLoading,
    categoryCascaderOptions,
    setCategoryLevels,
    fetchCategoryLevels,
    saveCategoryLevels,
  };
});
