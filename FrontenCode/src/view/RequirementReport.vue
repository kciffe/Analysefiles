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
            <el-tag v-if="waiting" type="warning" effect="plain">{{ statusTagText }}</el-tag>
            <el-button plain :icon="EditPen" @click="openModifyDrawer">修改需求</el-button>
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

    <RequirementClearDrawer
      v-model="modifyDrawerVisible"
      v-model:model-text="modifyText"
      :mode="reportReady ? 'report' : 'create'"
      :question="clarificationQuestion"
      :messages="clarificationMessages"
      :research-brief="currentResearchBrief"
      :loading="modifying"
      @submit="submitRequirementModify"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { EditPen } from '@element-plus/icons-vue'
import MarkdownIt from 'markdown-it'
import { API } from '@/api/endpoints'
import {
  getRequirementReport,
  sendRequirementMessage,
  type RequirementChatMessage,
  type RequirementReportResponse,
} from '@/api/modules/requirementsApi'
import RequirementClearDrawer from '@/components/RequirementClearDrawer.vue'

const route = useRoute()
const router = useRouter()
const md = new MarkdownIt({ html: false, linkify: true, breaks: true })

const STEPS = [
  { key: 'prepare_scope_input_node', title: '整理需求' },
  { key: 'requirement_scope_graph', title: '需求澄清' },
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
const currentResearchBrief = ref('')
const errorText = ref('')
const currentNode = ref('')
const reachedStep = ref(0)
const modifyDrawerVisible = ref(false)
const modifyText = ref('')
const modifying = ref(false)
const clarificationQuestion = ref('')
const clarificationMessages = ref<RequirementChatMessage[]>([])
let sse: EventSource | null = null

const requirementId = computed(() => String(route.params.id || ''))
const renderedMarkdown = computed(() => md.render(reportMarkdown.value || ''))

const reportTitle = computed(() => {
  const line = (reportMarkdown.value || '').split(/\r?\n/).find((x) => /^#\s+/.test(x.trim()))
  return line ? line.replace(/^#\s+/, '').trim() : '需求报告'
})

const currentNodeLabel = computed(() => {
  if (clarificationQuestion.value && modifyDrawerVisible.value) return '等待用户澄清需求'
  const hit = STEPS.find((x) => x.key === currentNode.value)
  return hit?.title || (currentNode.value || '等待开始')
})

const statusTagText = computed(() => {
  if (clarificationQuestion.value && modifyDrawerVisible.value) return '等待需求澄清'
  return '报告生成中'
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
  reportMarkdown.value = (data.result?.reportMarkdown || '').trim()
  currentResearchBrief.value = (data.result?.researchBrief || data.result?.research_brief || reportMarkdown.value || '').trim()
  reportReady.value = reportMarkdown.value.length > 0
  errorText.value = data.error || ''
  clarificationQuestion.value = data.clarificationQuestion || ''
  clarificationMessages.value = data.messages || clarificationMessages.value
  const isClarifying = Boolean(clarificationQuestion.value && !reportReady.value)
  waiting.value = isClarifying ? true : Boolean(data.waiting)
  if (clarificationQuestion.value && !reportReady.value) {
    modifyDrawerVisible.value = true
  }
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

  sse.addEventListener('requirement_clarification', (ev) => {
    const payload = JSON.parse((ev as MessageEvent).data)
    const data = payload?.data || {}
    const question = String(data.question || '')
    clarificationQuestion.value = question
    clarificationMessages.value = Array.isArray(data.messages) ? data.messages : clarificationMessages.value
    if (question && !clarificationMessages.value.some((item) => item.role === 'assistant' && item.content === question)) {
      clarificationMessages.value.push({ role: 'assistant', content: question })
    }
    waiting.value = true
    modifyDrawerVisible.value = true
    closeSSE()
  })

  sse.addEventListener('state', (ev) => {
    const payload = JSON.parse((ev as MessageEvent).data)
    const data = payload?.data
    if (data) updateFromResult(data as RequirementReportResponse)
  })

  sse.addEventListener('result', (ev) => {
    if (clarificationQuestion.value && modifyDrawerVisible.value) return
    const payload = JSON.parse((ev as MessageEvent).data)
    const data = payload?.data
    if (data) updateFromResult(data as RequirementReportResponse)
  })

  sse.addEventListener('done', () => {
    if (clarificationQuestion.value && modifyDrawerVisible.value) {
      closeSSE()
      return
    }
    closeSSE()
    if (reportReady.value) ElMessage.success('报告生成完成')
  })

  sse.onerror = () => {
    closeSSE()
  }
}

function openModifyDrawer() {
  modifyText.value = ''
  modifyDrawerVisible.value = true
}

async function submitRequirementModify(text: string) {
  modifying.value = true
  try {
    clarificationMessages.value.push({ role: 'user', content: text })
    modifyText.value = ''

    const resp = await sendRequirementMessage(requirementId.value, text)
    if (resp.need_clarification) {
      const question = resp.question || '请继续补充需求信息。'
      clarificationQuestion.value = question
      clarificationMessages.value.push({ role: 'assistant', content: question })
      return
    }

    modifyDrawerVisible.value = false
    waiting.value = true
    ElMessage.success('需求已明确，继续生成报告')
    connectSSE()
  } finally {
    modifying.value = false
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
