<template>
  <div class="page" v-loading="loading">
    <el-card class="card" shadow="never">
      <template #header>
        <div class="header">
          <div>
            <h2>{{ report?.title || '需求报告' }}</h2>
            <p>需求 ID：{{ requirementId }}</p>
          </div>
          <div class="header-actions">
            <el-tag v-if="waiting && polling" type="warning" effect="plain">报告生成中，自动刷新中...</el-tag>
            <el-button plain @click="goBack">返回列表</el-button>
          </div>
        </div>
      </template>

      <template v-if="reportReady && report">
        <section class="section">
          <h3>摘要</h3>
          <p class="summary">{{ report.summary }}</p>
        </section>

        <section v-for="block in report.blocks" :key="block.id" class="section">
          <h3>{{ block.title }}</h3>

          <p v-if="block.type === 'text'" class="text-content">{{ block.content }}</p>

          <el-table v-else-if="block.type === 'table'" :data="toTableData(block)" border>
            <el-table-column
              v-for="column in block.columns"
              :key="column"
              :prop="column"
              :label="column"
              min-width="140"
            />
          </el-table>
        </section>

        <section class="section">
          <h3>参考资料</h3>
          <el-empty v-if="!report.references?.length" description="暂无引用" :image-size="70" />
          <ul v-else class="refs">
            <li v-for="(item, index) in report.references" :key="index">{{ toRefText(item) }}</li>
          </ul>
        </section>
      </template>
      <template v-else>
        <el-empty :description="waiting ? '报告生成中，请稍候...' : '暂未生成可展示的报告内容'" :image-size="72" />
      </template>
    </el-card>

    <el-button class="publish-btn" type="primary">发布（功能暂留）</el-button>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  getRequirementReport,
  type RequirementReport,
  type RequirementReportResponse,
  type RequirementReportTableBlock,
} from '@/api/modules/requirementsApi'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const report = ref<RequirementReport | null>(null)
const reportReady = ref(false)
const polling = ref(false)
const waiting = ref(true)

const requirementId = computed(() => String(route.params.id || ''))

const POLL_INTERVAL_MS = 3000
const MAX_POLL_TIMES = 120

let pollTimer: ReturnType<typeof setTimeout> | null = null
let pollTimes = 0
let pollingRequesting = false

function goBack() {
  router.push('/RequirementList')
}

function toTableData(block: RequirementReportTableBlock) {
  return (block.rows || []).map((row) => {
    const record: Record<string, string> = {}
    block.columns.forEach((col, index) => {
      record[col] = row[index] ?? ''
    })
    return record
  })
}

function toRefText(item: unknown) {
  return typeof item === 'string' ? item : JSON.stringify(item)
}

function normalizeReport(raw: Partial<RequirementReport> | null | undefined): RequirementReport | null {
  if (!raw || typeof raw !== 'object') return null

  return {
    title: raw.title ?? '',
    summary: raw.summary ?? '',
    blocks: Array.isArray(raw.blocks) ? raw.blocks : [],
    references: Array.isArray(raw.references) ? raw.references : [],
  }
}

function isReportReadyState(data: RequirementReport | null) {
  if (!data) return false
  return Boolean(data.title || data.summary || data.blocks.length || data.references.length)
}

function stopPolling() {
  if (pollTimer) {
    clearTimeout(pollTimer)
    pollTimer = null
  }
  polling.value = false
}

async function fetchReport(options?: { showLoading?: boolean; showError?: boolean }) {
  if (!requirementId.value) {
    if (options?.showError) ElMessage.error('缺少需求 ID')
    return true
  }

  if (options?.showLoading) loading.value = true
  try {
    const resp = await getRequirementReport(requirementId.value)
    const data = resp as RequirementReportResponse
    waiting.value = Boolean(data.waiting)
    report.value = normalizeReport(data.result?.report ?? null)
    reportReady.value = isReportReadyState(report.value)

    if (!waiting.value) {
      const wasPolling = polling.value
      stopPolling()
      if (wasPolling && reportReady.value) {
        ElMessage.success('报告生成完成')
      }
      if (!reportReady.value && data.error) {
        ElMessage.warning(String(data.error))
      }
      return true
    }
    return false
  } catch (e: any) {
    if (options?.showError) ElMessage.error(e?.message || '获取报告失败')
    return false
  } finally {
    if (options?.showLoading) loading.value = false
  }
}

function startPolling() {
  if (pollTimer) return

  polling.value = true
  pollTimes = 0

  const pollOnce = async () => {
    if (!polling.value) return
    if (pollingRequesting) {
      pollTimer = setTimeout(pollOnce, POLL_INTERVAL_MS)
      return
    }

    pollingRequesting = true
    pollTimes += 1

    const done = await fetchReport()
    pollingRequesting = false

    if (done) {
      return
    }

    if (pollTimes >= MAX_POLL_TIMES) {
      stopPolling()
      ElMessage.warning('报告仍在生成中，请稍后刷新')
      return
    }

    pollTimer = setTimeout(pollOnce, POLL_INTERVAL_MS)
  }

  pollTimer = setTimeout(pollOnce, POLL_INTERVAL_MS)
}

async function init() {
  const done = await fetchReport({ showLoading: true, showError: true })
  if (!done) startPolling()
}

onMounted(() => {
  init()
})

onBeforeUnmount(() => {
  stopPolling()
})
</script>

<style scoped>
.page {
  width: 100%;
  min-height: 100%;
  padding: 22px 26px 90px;
  box-sizing: border-box;
  background: #f6f7fb;
}

.card {
  border-radius: 14px;
  border: 1px solid #e6edf7;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.header h2 {
  margin: 0;
  font-size: 20px;
}

.header p {
  margin: 8px 0 0;
  font-size: 12px;
  color: #6b7280;
}

.section {
  margin-bottom: 22px;
}

.section h3 {
  margin: 0 0 10px;
  font-size: 16px;
}

.summary,
.text-content {
  margin: 0;
  line-height: 1.8;
  color: #374151;
  white-space: pre-wrap;
}

.refs {
  margin: 0;
  padding-left: 18px;
}

.refs li {
  line-height: 1.8;
  color: #374151;
}

.publish-btn {
  position: fixed;
  right: 28px;
  bottom: 28px;
}
</style>
