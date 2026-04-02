<template>
  <div class="page" v-loading="loading">
    <el-card class="card" shadow="never">
      <template #header>
        <div class="header">
          <div>
            <h2>{{ reportTitle }}</h2>
            <p>需求 ID：{{ requirementId }}</p>
          </div>
          <div class="header-actions">
            <el-tag v-if="waiting && polling" type="warning" effect="plain">报告生成中，自动刷新中...</el-tag>
            <el-button plain @click="goBack">返回列表</el-button>
          </div>
        </div>
      </template>

      <template v-if="reportReady">
        <section class="section markdown-wrapper">
          <article class="markdown-body" v-html="renderedMarkdown" />
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
import MarkdownIt from 'markdown-it'
import {
  getRequirementReport,
  type RequirementReportResponse,
} from '@/api/modules/requirementsApi'

const route = useRoute()
const router = useRouter()
const md = new MarkdownIt({
  html: false,
  linkify: true,
  breaks: true,
})

const loading = ref(false)
const reportMarkdown = ref('')
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

const reportTitle = computed(() => {
  const text = reportMarkdown.value || ''
  const firstHeading = text.split(/\r?\n/).find((line) => /^#\s*(.+)$/.test(line.trim()))
  if (!firstHeading) return '需求报告'
  const matched = firstHeading.trim().match(/^#\s*(.+)$/)
  return matched?.[1]?.trim() || '需求报告'
})

const renderedMarkdown = computed(() => md.render(reportMarkdown.value || ''))

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
    reportMarkdown.value = (data.result?.reportMarkdown || '').trim()
    reportReady.value = reportMarkdown.value.length > 0

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

.markdown-wrapper {
  margin-bottom: 0;
}

.markdown-body {
  color: #1f2937;
  line-height: 1.8;
  word-break: break-word;
}

.markdown-body :deep(h1),
.markdown-body :deep(h2),
.markdown-body :deep(h3) {
  margin-top: 20px;
  margin-bottom: 12px;
  line-height: 1.35;
}

.markdown-body :deep(p),
.markdown-body :deep(ul),
.markdown-body :deep(ol),
.markdown-body :deep(table) {
  margin: 10px 0;
}

.markdown-body :deep(table) {
  width: 100%;
  border-collapse: collapse;
}

.markdown-body :deep(th),
.markdown-body :deep(td) {
  border: 1px solid #e5e7eb;
  padding: 8px 10px;
  text-align: left;
}

.markdown-body :deep(code) {
  padding: 2px 6px;
  border-radius: 4px;
  background: #f3f4f6;
}

.markdown-body :deep(pre) {
  overflow-x: auto;
  padding: 12px;
  border-radius: 8px;
  background: #111827;
  color: #f9fafb;
}

.publish-btn {
  position: fixed;
  right: 28px;
  bottom: 28px;
}
</style>
