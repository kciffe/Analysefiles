<template>
  <div class="page">
    <!-- 顶部：标题 + 搜索 -->
    <div class="header">
      <div class="header-left">
        <div class="title">需求列表</div>
      </div>

      <div class="header-right">
        <el-input
          v-model="searchText"
          class="search"
          placeholder="按需求名搜索（支持模糊匹配）"
          clearable
          @keyup.enter="onSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
          <template #append>
            <el-button :icon="Search" @click="onSearch">搜索</el-button>
          </template>
        </el-input>
      </div>
    </div>

    <!-- 卡片区 -->
    <div class="grid">
      <!-- 新建需求卡片 -->
      <el-card class="card card-new" shadow="hover" @click="createRequirement">
        <div class="new-inner">
          <div class="new-icon">
            <el-icon size="22"><Plus /></el-icon>
          </div>
          <div class="new-text">
            <div class="new-title">新建需求</div>
          </div>
        </div>
      </el-card>

      <!-- 需求卡片 -->
      <el-card
        v-for="item in visibleList"
        :key="item.id"
        class="card"
        shadow="hover"
        :class="cardClass(item)"
      >
        <!-- 状态色条 -->
        <div class="status-bar" :class="barClass(item.status)" />

        <!-- 顶部行：时间 + 状态 + 删除 -->
        <div class="top">
          <div class="time">
            <el-icon class="time-icon"><Clock /></el-icon>
            <span>{{ item.createdAt }}</span>
          </div>

          <div class="top-actions">
            <el-tag
              :type="statusTagType(item.status)"
              size="small"
              effect="plain"
              class="tag"
            >
              {{ item.status }}
            </el-tag>

            <el-tooltip content="删除需求" placement="top">
              <el-button
                class="btn-close"
                text
                :icon="Close"
                @click="confirmRemove(item)"
              />
            </el-tooltip>
          </div>
        </div>

        <!-- 标题 -->
        <div class="name" v-html="highlightName(item.name)"></div>

        <!-- 操作区 -->
        <div class="actions">
          <el-button
            size="small"
            plain
            round
            @click="onOperationStatus(item)"
          >
            运作状态
          </el-button>

          <el-button
            size="small"
            type="primary"
            round
            :disabled="item.status === '已完成'"
            :loading="isRunning(item.id)"
            @click="runRequirement(item)"
          >
            运行
          </el-button>
        </div>
      </el-card>
    </div>

    <!-- 空结果提示（不影响“新建卡片”，只在列表过滤无结果时显示） -->
    <div v-if="visibleList.length === 0" class="empty-wrap">
      <el-empty description="没有匹配的需求">
        <el-button type="primary" @click="resetSearch">清空搜索并查看全部</el-button>
      </el-empty>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Close, Search, Clock } from '@element-plus/icons-vue'

type RequirementStatus = '待运行' | '已完成'| '已发布'

interface RequirementItem {
  id: string
  name: string
  status: RequirementStatus
  createdAt: string
}

const STORAGE_KEY = 'req_list_v1'

const requirements = ref<RequirementItem[]>([])
const searchText = ref('')
const activeQuery = ref('') // 点击“搜索”才生效
const nextNum = ref(1) //test用于生成“需求n+1”的 n

// 运行 loading 集合（更轻量）
const runningIds = ref<Set<string>>(new Set())

//页面初始化
onMounted(() => {
  // 本地恢复（可删除这段持久化逻辑）
  const raw = localStorage.getItem(STORAGE_KEY)
  if (raw) {
    try {
      const parsed = JSON.parse(raw) as RequirementItem[]
      if (Array.isArray(parsed)) requirements.value = parsed
    } catch {
      // ignore
    }
  }

  // 默认给几条示例（如果你不想要示例，删掉这一段）
  if (requirements.value.length === 0) {
    requirements.value = [
      { id: cryptoRandomId(), name: '需求4', status: '已完成', createdAt: formatNow() },
      { id: cryptoRandomId(), name: '需求3', status: '待运行', createdAt: formatNow() },
      { id: cryptoRandomId(), name: '需求2', status: '已发布', createdAt: formatNow() },
      { id: cryptoRandomId(), name: '需求1', status: '已完成', createdAt: formatNow() },
    ]
  }

  nextNum.value = getNextNum(requirements.value)
})

// 持久化（可删除）
watch(
  requirements,
  (val) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(val))
  },
  { deep: true }
)

const visibleList = computed(() => {
  const q = activeQuery.value.trim().toLowerCase()
  if (!q) return requirements.value
  return requirements.value.filter((x) => x.name.toLowerCase().includes(q))
})

function onSearch() {
  activeQuery.value = searchText.value
}

function resetSearch() {
  searchText.value = ''
  activeQuery.value = ''
}

//test  创建需求接口
function createRequirement() {
  const name = `需求${nextNum.value}`
  nextNum.value += 1

  const item: RequirementItem = {
    id: cryptoRandomId(),
    name,
    status: '待运行',
    createdAt: formatNow(),
  }

  requirements.value.unshift(item)
  ElMessage.success(`已新建：${name}`)
}

function isRunning(id: string) {
  return runningIds.value.has(id)
}
//test 运行需求接口
async function runRequirement(item: RequirementItem) {
  if (item.status === '已完成') return
  if (runningIds.value.has(item.id)) return //防止并发执行 避免重复点击

  runningIds.value.add(item.id)
  try {
    // 这里模拟运行过程（你后面接接口时，换成 await api.run(item.id)）
    await sleep(650)
    item.status = '已完成'
    item.createdAt = formatNow()
    ElMessage.success(`${item.name} 已完成`)
  } finally {
    runningIds.value.delete(item.id)//无论成功失败都把 loading 去掉，避免卡死
  }
}

//test 运行状态接口
function onOperationStatus(item: RequirementItem) {
  // 预留接口：后续路由跳转或渲染其他界面
  ElMessage.info(`运作状态接口预留：${item.name}`)
}

//test 删除需求接口
async function confirmRemove(item: RequirementItem) {
  try {
    await ElMessageBox.confirm(
      `是否删除本需求？\n${item.name}`,
      '删除确认',
      {
        confirmButtonText: '删除',
        cancelButtonText: '取消',
        type: 'warning',
        closeOnClickModal: false,
      }
    )
    requirements.value = requirements.value.filter((x) => x.id !== item.id)
    ElMessage.success('已删除')
  } catch {
    // cancel
  }
}

/** UI 映射 */
function statusTagType(status: RequirementStatus) {
  if (status === '已完成') return 'success'
  if (status === '已发布') return 'primary'
  return 'warning' // 待运行'
}

function barClass(status: RequirementStatus) {
  if (status === '已完成') return 'bar-success'
  if (status === '已发布') return 'bar-primary'
  return 'bar-warning' // 待运行
}

function cardClass(item: RequirementItem) {
  return {
    'card-done': item.status === '已完成',
    'card-published': item.status === '已发布',
  }
}

/** 搜索高亮（安全：先转义再插 mark） */
function highlightName(name: string) {
  const q = activeQuery.value.trim()
  if (!q) return escapeHtml(name)

  const safeName = escapeHtml(name)
  const safeQ = escapeRegExp(q)
  const reg = new RegExp(safeQ, 'ig')
  return safeName.replace(reg, (m) => `<mark class="hl">${m}</mark>`)
}

function escapeHtml(s: string) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function escapeRegExp(s: string) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

/** 时间格式：YYYY,MM,DD HH:mm */
function formatNow() {
  const d = new Date()
  const yyyy = d.getFullYear()
  const mm = pad2(d.getMonth() + 1)
  const dd = pad2(d.getDate())
  const hh = pad2(d.getHours())
  const mi = pad2(d.getMinutes())
  return `${yyyy},${mm},${dd} ${hh}:${mi}`
}

function pad2(n: number) {
  return String(n).padStart(2, '0')
}

function getNextNum(list: RequirementItem[]) {
  let max = 0
  for (const x of list) {
    const m = x.name.match(/^需求(\d+)$/)
    if (m) max = Math.max(max, Number(m[1]))
  }
  return max + 1
}

function cryptoRandomId() {
  // @ts-ignore
  if (typeof crypto !== 'undefined' && crypto.randomUUID) return crypto.randomUUID()
  return `${Date.now()}_${Math.random().toString(16).slice(2)}`
}

function sleep(ms: number) {
  return new Promise<void>((r) => setTimeout(r, ms))
}
</script>

<style scoped>
/* 页面整体 */
.page {
  width: 100%;
  min-height: 100%;
  padding: 22px 26px;
  box-sizing: border-box;
  background: #f6f7fb;
}

/* 顶部 */
.header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 18px;
  margin-bottom: 16px;
}

.header-left .title {
  font-size: 20px;
  font-weight: 800;
  color: #111827;
}



.search {
  width: 420px;
}

:deep(.el-input__wrapper) {
  border-radius: 12px;
}
:deep(.el-input-group__append) {
  border-top-right-radius: 12px;
  border-bottom-right-radius: 12px;
}

/* 网格布局 */
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 18px;
  align-items: start;
}

/* 卡片通用 */
.card {
  border-radius: 16px;
  border: 1px solid #e6edf7;
  overflow: hidden;
  background: #fff;
  transition: transform 0.16s ease, box-shadow 0.16s ease, border-color 0.16s ease;
  position: relative;
}

.card:hover {
  transform: translateY(-2px);
  border-color: #d5e1f3;
  box-shadow: 0 14px 30px rgba(16, 24, 40, 0.10);
}

:deep(.card .el-card__body) {
  padding: 14px 16px 16px;
  min-height: 168px;
  display: flex;
  flex-direction: column;
}

/* 状态色条 */
.status-bar {
  position: absolute;
  left: 0;
  top: 0;
  width: 100%;
  height: 4px;
}

.bar-success {
  background: linear-gradient(90deg, #22c55e, #86efac);
}
.bar-warning {
  background: linear-gradient(90deg, #f59e0b, #fde68a);
}
.bar-primary {
  background: linear-gradient(90deg, #3b82f6, #93c5fd);
}
/* 顶部行 */
.top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.time {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #6b7280;
}

.time-icon {
  opacity: 0.85;
}

.top-actions {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.tag {
  border-radius: 999px;
  padding: 0 10px;
}

/* 删除按钮：默认克制，hover 才明显 */
.btn-close {
  padding: 0;
  min-height: auto;
  color: #9ca3af;
  opacity: 0.55;
  transition: opacity 0.16s ease, color 0.16s ease;
}
.card:hover .btn-close {
  opacity: 1;
  color: #6b7280;
}

/* 需求名 */
.name {
  margin-top: 18px;
  text-align: center;
  font-size: 22px;
  font-weight: 900;
  color: #111827;
  letter-spacing: 0.2px;
}

/* 高亮 */
:deep(.hl) {
  background: #fff1b8;
  padding: 0 2px;
  border-radius: 4px;
}

/* 操作区固定底部 */
.actions {
  margin-top: auto;
  padding-top: 16px;
  display: flex;
  justify-content: center;
  gap: 10px;
}

:deep(.actions .el-button) {
  border-radius: 12px;
}

/* 新建卡片 */
.card-new {
  cursor: pointer;
  border: 1px dashed #cbd5e1;
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

.new-inner {
  height: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
}

.new-icon {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  background: #eef2ff;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #4f46e5;
}

.new-title {
  font-size: 25px;
  font-weight: 800;
  color: #111827;
}

.new-desc {
  margin-top: 4px;
  font-size: 12px;
  color: #6b7280;
}

/* 已完成：整体弱化 */
.card-done {
  background: linear-gradient(180deg, #ffffff 0%, #fbfcff 100%);
}
.card-done .name {
  color: #374151;
}
.card-done :deep(.el-button) {
  opacity: 0.92;
}

/* 已发布：蓝化 */
.card-published {
  background: linear-gradient(180deg, #ffffff 0%, #f7fbff 100%);
}
.card-published .name {
  color: #1f2937;
}


/* 空状态 */
.empty-wrap {
  margin-top: 22px;
}
</style>
