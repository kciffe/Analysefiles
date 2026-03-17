<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useAllDataStore } from '@/store/index' // 你实际 store 路径
import type { CascaderProps } from 'element-plus'

type Model = string | string[] | null | undefined

const props = withDefaults(defineProps<{
  modelValue: Model
  separator?: string              // 默认 '-'
  emitAs?: 'auto' | 'string' | 'array' // auto: 跟随传入类型
  checkStrictly?: boolean
  clearable?: boolean
  filterable?: boolean
}>(), {
  separator: '-',
  emitAs: 'auto',
  checkStrictly: false,
  clearable: true,
  filterable: true,
})

const emit = defineEmits<{
  (e: 'update:modelValue', v: string | string[]): void
}>()

const store = useAllDataStore()
onMounted(() => {
  store.fetchCategoryLevels(true).catch(() => {})
})

// el-cascader 需要数组路径
const innerPath = computed<string[]>({
  get() {
    const v = props.modelValue
    if (!v) return []
    if (Array.isArray(v)) return v
    return String(v).split(props.separator).filter(Boolean)
  },
  set(next) {
    const as = props.emitAs
    const wantString =
      as === 'string' || (as === 'auto' && typeof props.modelValue === 'string')

    emit('update:modelValue', wantString ? next.join(props.separator) : next)
  },
})

const cascaderProps = computed<CascaderProps>(() => ({
  emitPath: true,
  checkStrictly: props.checkStrictly,
  value: 'value',
  label: 'label',
  children: 'children',
}))

//如果 store 还没加载完，或字段名一时没初始化，会出现空白且不好排查。
const options = computed(() => store.categoryCascaderOptions ?? [])
</script>

<template>
  <el-cascader
    v-model="innerPath"
    :options="options"
    :props="cascaderProps"
    :clearable="clearable"
    :filterable="filterable"
    placeholder="请选择分类路径"
  />
</template>

<style scoped lang="less">
    .tags-cascader { width: 100%; }

</style>
