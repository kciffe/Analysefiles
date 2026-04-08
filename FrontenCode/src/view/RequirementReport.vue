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
            <el-tag v-if="waiting" type="warning" effect="plain">报告生成中</el-tag>
            <el-button plain @click="goBack">返回列表</el-button>
          </div>
        </div>
      </template>

      <section v-if="waiting" class="section">
        <el-steps :active="activeStep" finish-status="success" simple>
          <el-step v-for="s in STEPS" :key="s.key" :title="s.title" />
        </el-steps>
        <p class="progress-text">当前节点：{{ currentNodeLabel }}</p>
      </section>

      <template v-if="reportReady">
        <section class="section markdown-wrapper">
          <article class="markdown-body" v-html="renderedMarkdown" />
        </section>
      </template>
      <template v-else-if="!waiting">
        <el-empty :description="errorText || '暂未生成可展示的报告内容'" :image-size="72" />
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
import { API } from '@/api/endpoints'
import { getRequirementReport, type RequirementReportResponse } from '@/api/modules/requirementsApi'

const route = useRoute()
const router = useRouter()
const md = new MarkdownIt({ html: false, linkify: true, breaks: true })

const STEPS = [
  { key: 'prepare_query', title: '准备查询' },
  { key: 'retrieval_documents', title: '检索文档' },
  { key: 'collect_retrieval_results', title: '收集文档' },
  { key: 'generate_evidence', title: '生成证据计划' },
  { key: 'read_sections', title: '读取段落' },
  { key: 'collect_read_sections_results', title: '收集段落' },
  { key: 'generate_report', title: '生成报告' },
]

const loading = ref(false)
const waiting = ref(true)
const reportReady = ref(false)
const reportMarkdown = ref('')
const errorText = ref('')
const currentNode = ref('')
const reachedStep = ref(0)
let sse: EventSource | null = null

const requirementId = computed(() => String(route.params.id || ''))
const renderedMarkdown = computed(() => md.render(reportMarkdown.value || ''))

const reportTitle = computed(() => {
  const line = (reportMarkdown.value || '').split(/\r?\n/).find((x) => /^#\s+/.test(x.trim()))
  return line ? line.replace(/^#\s+/, '').trim() : '需求报告'
})

const currentNodeLabel = computed(() => {
  const hit = STEPS.find((x) => x.key === currentNode.value)
  return hit?.title || (currentNode.value || '等待开始')
})

const activeStep = computed(() => {
  if (!waiting.value) return STEPS.length
  return reachedStep.value
})

function goBack() {
  router.push('/RequirementList')
}

function closeSSE() {
  sse?.close()
  sse = null
}

function updateFromResult(data: RequirementReportResponse) {
  waiting.value = Boolean(data.waiting)
  reportMarkdown.value = (data.result?.reportMarkdown || '').trim()
  reportReady.value = reportMarkdown.value.length > 0
  errorText.value = data.error || ''
}

async function fetchReport() {
  if (!requirementId.value) return
  const data = (await getRequirementReport(requirementId.value)) as RequirementReportResponse
  updateFromResult(data)
}

function connectSSE() {
  if (!requirementId.value) return
  closeSSE()

  sse = new EventSource(API.RequirementList.STREAM(requirementId.value))

  sse.addEventListener('progress', (ev) => {
    const payload = JSON.parse((ev as MessageEvent).data)
    const node = payload?.data?.node
    if (!node) return

    currentNode.value = String(node)
    const idx = STEPS.findIndex((x) => x.key === currentNode.value)
    if (idx >= 0) {
      reachedStep.value = Math.max(reachedStep.value, idx + 1)
    }
  })

  sse.addEventListener('failed', (ev) => {
    const payload = JSON.parse((ev as MessageEvent).data)
    errorText.value = payload?.data?.error || '报告生成失败'
    waiting.value = false
    ElMessage.error(errorText.value)
  })

  sse.addEventListener('result', async () => {
    await fetchReport()
  })

  sse.addEventListener('done', async () => {
    await fetchReport()
    closeSSE()
    if (reportReady.value) ElMessage.success('报告生成完成')
  })

  sse.onerror = () => {
    closeSSE()
  }
}

onMounted(async () => {
  if (!requirementId.value) {
    ElMessage.error('缺少需求 ID')
    return
  }

  loading.value = true
  try {
    await fetchReport()
    if (waiting.value) connectSSE()
  } finally {
    loading.value = false
  }
})

onBeforeUnmount(() => {
  closeSSE()
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

.progress-text {
  margin: 10px 0 0;
  font-size: 13px;
  color: #6b7280;
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
