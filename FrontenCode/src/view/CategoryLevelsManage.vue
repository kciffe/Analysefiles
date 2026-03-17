<template>
  <div class="page">
    <div class="header">
      <div>
        <div class="title">文档标签分类树管理</div>
      </div>

      <div class="header-actions">
        <el-button :icon="Refresh" :loading="loading" @click="fetchRemote">刷新</el-button>
        <el-button type="primary" :icon="Check" :loading="saving" @click="saveRemote">
          保存
        </el-button>
      </div>
    </div>

    <div class="content">
      <!-- 左侧：树 + 搜索 + 新增一级 -->
      <el-card class="panel left" shadow="never">
        <div class="panel-head">
          <el-input v-model="filterText" placeholder="搜索类别（按名称模糊匹配）" clearable class="search">
            <template #prefix>
              <el-icon>
                <Search />
              </el-icon>
            </template>
          </el-input>

          <el-button type="primary" plain :icon="Plus" @click="addRoot">
            新建一级标签
          </el-button>
        </div>

        <el-tree ref="treeRef" class="tree" :data="treeData" :props="treeProps" node-key="id" highlight-current
          default-expand-all :expand-on-click-node="true" :filter-node-method="filterNode" @node-click="onNodeClick"
          v-loading="loading">
          <template #default="{ data }">
            <div class="tree-node">
              <span class="tree-name">{{ data.name }}</span>
              <el-tag class="tree-level" effect="plain" size="small">L{{ data.level }}</el-tag>
            </div>
          </template>
        </el-tree>

        <div v-if="!loading && treeData.length === 0" class="tree-empty">
          <el-empty description="暂无分类数据" />
        </div>
      </el-card>

      <!-- 右侧：详情 + 操作 + JSON 预览 -->
      <el-card class="panel right" shadow="never">
        <div class="right-top">
          <div class="panel-title">节点信息</div>
          <el-tag v-if="dirty" type="warning" effect="plain">未保存</el-tag>
        </div>

        <el-empty v-if="!selected" description="请选择左侧一个节点" />

        <div v-else class="detail">
          <el-descriptions  class="node-desc" :column="1" border label-width="220px">
            <el-descriptions-item label="名称">{{ selected.name }}</el-descriptions-item>
            <el-descriptions-item label="层级">L{{ selected.level }}</el-descriptions-item>
            <el-descriptions-item label="路径">
              <span class="path">{{ selected.path.join(' / ') }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="下级标签数">{{ (selected.children || []).length }}</el-descriptions-item>
            <el-descriptions-item label="包含的下级标签">{{(selected.children && selected.children.length > 0 ?
              selected.children.map(child => child.name).join(', ') : '最小标签') }}</el-descriptions-item>
          </el-descriptions>

          <div class="btns">
            <el-button type="primary" plain :icon="Plus" @click="addChild">新增子类</el-button>
            <el-button color="#626aef" plain :icon="Plus" @click="addSibling">新增同级</el-button>
            <el-button type="warning" plain :icon="Edit" @click="renameNode">重命名</el-button>
            <el-button type="danger" plain :icon="Delete" @click="removeNode">删除</el-button>
          </div>

          <div class="hint">
            说明：由于后端结构以“名称”为 key（Dict 的 key），为避免冲突，本页面默认要求“同一层级名称全局唯一”。
          </div>
        </div>

        <el-divider />

        <div class="panel-title">提交给后端的字段 JSON 预览</div>
        <el-input class="json" type="textarea" resize="none" :model-value="jsonPreview" readonly />

        <div class="json-actions">
          <el-button size="small" @click="copyJson">复制 JSON</el-button>
          <el-button size="small" @click="downloadJson">下载 JSON</el-button>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import type { ElTree } from 'element-plus'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, Refresh, Check, Search } from '@element-plus/icons-vue'
import { useAllDataStore } from '@/store'
import  { type UiNode, type CategoryLevelDict } from '@/types/category-levels'
const treeRef = ref<InstanceType<typeof ElTree>>()
const treeProps = { label: 'name', children: 'children' }

const loading = ref(false)
const saving = ref(false)
const dirty = ref(false)

const filterText = ref('')
const treeData = ref<UiNode[]>([])
const selected = ref<UiNode | null>(null)

const store = useAllDataStore()

onMounted(() => {
  fetchRemote()
})

watch(filterText, (val) => {
  treeRef.value?.filter(val)
})

function filterNode(query: string, data: UiNode) {
  if (!query) return true
  return data.name.toLowerCase().includes(query.trim().toLowerCase())
}

function onNodeClick(data: UiNode) {
  selected.value = data
}

async function fetchRemote() {
  loading.value = true
  try {
    const levels: CategoryLevelDict[] = await store.fetchCategoryLevels(true)
    // console.log('Fetched category levels:', levels)

    treeData.value = levelsToTree(levels)
    rebuildMeta()

    selected.value = null
    dirty.value = false
    ElMessage.success('已加载分类数据')
  } catch (e: any) {
    console.error(e)
    ElMessage.error('加载失败：请检查接口与网络')
  } finally {
    loading.value = false
  }
}

async function saveRemote() {
  const { ok, message } = validateTree()
  if (!ok) {
    ElMessage.error(message)
    return
  }

  saving.value = true
  try {
    const payload = treeToLevels(treeData.value)
    await store.saveCategoryLevels(payload)
    dirty.value = false
    ElMessage.success('保存成功')
  } catch (e: any) {
    console.error(e)
    ElMessage.error('保存失败：请检查接口与后端日志')
  } finally {
    saving.value = false
  }
}


/** 师兄结构（levels） -> 树（便于 UI 操作） */
function levelsToTree(levels: CategoryLevelDict[]): UiNode[] {
  if (!levels || levels.length === 0) return []

  const rootMap = levels[0] || {}
  const rootNames = Object.keys(rootMap)

  const build = (name: string, level: number): UiNode => {
    const idx = level - 1
    const map = levels[idx] || {}
    const childrenNames = map[name] || []
    const children = childrenNames.map((c) => build(c, level + 1))

    return {
      id: '',
      name,
      level,
      path: [],
      children: children.length ? children : undefined,
    }
  }

  return rootNames.map((r) => build(r, 1))
}

/** 树 -> 师兄结构（levels），用于提交后端 */
function treeToLevels(roots: UiNode[]): CategoryLevelDict[] {
  const maps: CategoryLevelDict[] = []

  const walk = (node: UiNode) => {
    const idx = node.level - 1
    if (!maps[idx]) maps[idx] = {}

    const children = (node.children || []).map((x) => x.name)

    // root 必须出现，否则 root 会“消失”
    // 非 root：仅当有 children 时才需要作为 key 出现
    if (node.level === 1 || children.length > 0) {
      maps[idx][node.name] = children
    };
    (node.children || []).forEach(walk)
  }

  roots.forEach(walk)

  while (maps.length > 0 && Object.keys(maps[maps.length - 1] || {}).length === 0) {
    maps.pop()
  }

  return maps
}

/** 重建每个节点的 level/path/id（保证 rename / add 后一致） */
function rebuildMeta() {
  const walk = (nodes: UiNode[], level: number, parentPath: string[]) => {
    nodes.forEach((n) => {
      n.level = level
      n.path = [...parentPath, n.name]
      n.id = n.path.join(' / ')
      if (n.children?.length) walk(n.children, level + 1, n.path)
    })
  }
  walk(treeData.value, 1, [])
}

/** 同层级全局唯一校验（符合“name 作为 key” 的字段约束） */
function validateTree(): { ok: boolean; message: string } {
  const used = new Map<number, Set<string>>()
  const dups: Array<{ level: number; name: string }> = []

  const walk = (nodes: UiNode[]) => {
    nodes.forEach((n) => {
      const set = used.get(n.level) || new Set<string>()
      if (set.has(n.name)) dups.push({ level: n.level, name: n.name })
      set.add(n.name)
      used.set(n.level, set)
      if (n.children?.length) walk(n.children)
    })
  }
  walk(treeData.value)

  if (dups.length > 0) {
    const top = dups.slice(0, 5).map((x) => `L${x.level}:${x.name}`).join('，')
    const more = dups.length > 5 ? ` 等 ${dups.length} 处重复` : ''
    return { ok: false, message: `同层级名称需全局唯一：发现重复 ${top}${more}` }
  }

  if (treeData.value.length === 0) return { ok: false, message: '至少需要一个一级类别' }
  return { ok: true, message: 'ok' }
}

function isNameUsedAtLevel(name: string, level: number, excludeId?: string) {
  const target = name.trim()
  if (!target) return false

  let used = false
  const walk = (nodes: UiNode[]) => {
    for (const n of nodes) {
      if (n.level === level && n.name === target && n.id !== excludeId) {
        used = true
        return
      }
      if (n.children?.length) walk(n.children)
      if (used) return
    }
  }
  walk(treeData.value)
  return used
}

async function addRoot() {
  const { value } = await ElMessageBox.prompt('请输入一级类别名称', '新增一级', {
    confirmButtonText: '新增',
    cancelButtonText: '取消',
    inputPlaceholder: '例如：计算机',
    inputPattern: /\S+/,
    inputErrorMessage: '名称不能为空',
  }).catch(() => ({ value: '' }))

  const name = (value || '').trim()
  if (!name) return
  if (isNameUsedAtLevel(name, 1)) {
    ElMessage.error('该名称在一级中已存在（同层级需全局唯一）')
    return
  }

  treeData.value.push({ id: '', name, level: 1, path: [] })
  rebuildMeta()
  dirty.value = true

  await nextTick()
  treeRef.value?.setCurrentKey(name) // root 的 id 等于 name
}

async function addChild() {
  if (!selected.value) return ElMessage.info('请先选择一个节点')

  const parent = selected.value
  const { value } = await ElMessageBox.prompt(`请输入子类别名称（父：${parent.name}）`, '新增子类', {
    confirmButtonText: '新增',
    cancelButtonText: '取消',
    inputPlaceholder: '例如：AI / NLP',
    inputPattern: /\S+/,
    inputErrorMessage: '名称不能为空',
  }).catch(() => ({ value: '' }))

  const name = (value || '').trim()
  if (!name) return

  const level = parent.level + 1
  if (isNameUsedAtLevel(name, level)) {
    ElMessage.error(`该名称在 L${level} 已存在（同层级需全局唯一）`)
    return
  }

  if (!parent.children) parent.children = []
  parent.children.push({ id: '', name, level, path: [] })

  rebuildMeta()
  dirty.value = true

  await nextTick()
  treeRef.value?.setCurrentKey(selected.value.id)
}

async function addSibling() {
  if (!selected.value) return ElMessage.info('请先选择一个节点')
  const cur = selected.value

  if (cur.level === 1) return addRoot()

  const parent = findParent(treeData.value, cur.id)
  if (!parent) return ElMessage.error('未找到父节点，数据结构可能异常')

  const { value } = await ElMessageBox.prompt(`请输入同级类别名称（层级：L${cur.level}）`, '新增同级', {
    confirmButtonText: '新增',
    cancelButtonText: '取消',
    inputPattern: /\S+/,
    inputErrorMessage: '名称不能为空',
  }).catch(() => ({ value: '' }))

  const name = (value || '').trim()
  if (!name) return

  if (isNameUsedAtLevel(name, cur.level)) {
    ElMessage.error(`该名称在 L${cur.level} 已存在（同层级需全局唯一）`)
    return
  }

  parent.siblings.splice(parent.index + 1, 0, { id: '', name, level: cur.level, path: [] })
  rebuildMeta()
  dirty.value = true

  await nextTick()
  treeRef.value?.setCurrentKey(cur.id)
}

async function renameNode() {
  if (!selected.value) return ElMessage.info('请先选择一个节点')
  const cur = selected.value

  const { value } = await ElMessageBox.prompt('请输入新名称', '重命名', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    inputValue: cur.name,
    inputPattern: /\S+/,
    inputErrorMessage: '名称不能为空',
  }).catch(() => ({ value: '' }))

  const name = (value || '').trim()
  if (!name || name === cur.name) return

  if (isNameUsedAtLevel(name, cur.level, cur.id)) {
    ElMessage.error(`该名称在 L${cur.level} 已存在（同层级需全局唯一）`)
    return
  }

  cur.name = name
  rebuildMeta()
  dirty.value = true

  await nextTick()
  treeRef.value?.setCurrentKey(cur.id)
}

async function removeNode() {
  if (!selected.value) return ElMessage.info('请先选择一个节点')
  const cur = selected.value

  const ok = await ElMessageBox.confirm(
    `确认删除该节点及其所有子节点？\n${cur.path.join(' / ')}`,
    '删除确认',
    { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' }
  ).then(() => true).catch(() => false)

  if (!ok) return

  if (cur.level === 1) {
    const idx = treeData.value.findIndex((x) => x.id === cur.id)
    if (idx >= 0) treeData.value.splice(idx, 1)
  } else {
    const parent = findParent(treeData.value, cur.id)
    if (!parent) return ElMessage.error('未找到父节点，无法删除')
    parent.siblings.splice(parent.index, 1)
  }

  rebuildMeta()
  selected.value = null
  dirty.value = true
}

function findParent(roots: UiNode[], childId: string): { siblings: UiNode[]; index: number } | null {
  const walk = (siblings: UiNode[]): { siblings: UiNode[]; index: number } | null => {
    for (let i = 0; i < siblings.length; i++) {
      const n = siblings[i]
      // 添加n的undefined检查!!!!
      if (!n) continue
      const kids = n.children || []
      const idx = kids.findIndex((x) => x.id === childId)
      if (idx >= 0) return { siblings: kids, index: idx }
      if (kids.length) {
        const found = walk(kids)
        if (found) return found
      }
    }
    return null
  }
  return walk(roots)
}

const jsonPreview = computed(() => {
  const payload = treeToLevels(treeData.value)
  return JSON.stringify(payload, null, 2)
})

async function copyJson() {
  try {
    await navigator.clipboard.writeText(jsonPreview.value)
    ElMessage.success('已复制')
  } catch {
    ElMessage.warning('复制失败：请检查浏览器权限')
  }
}

function downloadJson() {
  const blob = new Blob([jsonPreview.value], { type: 'application/json;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'category-levels.json'
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped lang="less">
.page {
  display: flex;
  flex-direction: column;
  gap: 12px;
  height: 100%;
  min-height: 0;
}

.header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 12px;
}

.title {
  font-size: 18px;
  font-weight: 700;
}

.sub {
  margin-top: 6px;
  color: #666;
  font-size: 12px;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.content {
  display: grid;
  grid-template-columns: 1.15fr 1fr;
  gap: 12px;
  align-items: stretch;
  flex: 1;
  height: 100%;
  min-height: 0;
}

.panel {
  border-radius: 12px;
  height: 100%;
  min-height: 0;
}

.panel-head {
  display: flex;
  gap: 10px;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.panel :deep(.el-card__body) {
  height: 100%;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden; /* 避免内部撑破 */
}
.search {
  flex: 1;
}

.tree {
  flex:1;
  min-height: 0;
  overflow: auto;
}

.tree-node {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.tree-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 260px;
}

.tree-level {
  margin-left: 10px;
}

.tree-empty {
  padding: 40px 0;
}

.right-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.panel-title {
  font-weight: 700;
}

.detail {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.path {
  color: #333;
}

.btns {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.hint {
  color: #888;
  font-size: 12px;
  line-height: 1.6;
}

.json {
  margin-top: 12px;
  flex: 1;
  min-height: 20px;
}
.json :deep(.el-textarea) {
  height: 100%;
}
.json :deep(.el-textarea__inner) {
  height: 100% !important;
  resize: none !important; /* 禁止右下角拖拽 */
}

.json-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 10px;
}

@media (max-width: 1100px) {
  .content {
    grid-template-columns: 1fr;
  }

  .tree-name {
    max-width: 420px;
  }
}
</style>
