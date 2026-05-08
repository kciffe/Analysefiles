<template>
  <el-drawer
    :model-value="modelValue"
    size="680px"
    :with-header="false"
    destroy-on-close
    class="requirement-chat-drawer"
    @update:model-value="emit('update:modelValue', $event)"
    @close="emit('close')"
  >
    <div class="chat-shell">
      <header class="chat-header">
        <div class="agent-mark">
          <el-icon><ChatRound /></el-icon>
        </div>
        <div class="header-main">
          <div class="title-row">
            <h2>{{ titleText }}</h2>
            <el-tag size="small" effect="plain">{{ modeTag }}</el-tag>
          </div>
          <p>{{ subtitleText }}</p>
        </div>
        <el-tooltip content="关闭" placement="bottom">
          <el-button :icon="Close" circle text @click="emit('update:modelValue', false)" />
        </el-tooltip>
      </header>

      <main ref="chatBodyRef" class="chat-body">
        <section v-if="researchBrief" class="context-block">
          <div class="context-title">
            <el-icon><Document /></el-icon>
            <span>当前 Research Brief</span>
          </div>
          <div class="context-content markdown-content" v-html="renderMarkdown(researchBrief)" />
        </section>

        <div v-if="originalRequirement" class="message-row user">
          <div class="bubble user-bubble">
            <div class="bubble-label">原始需求</div>
            <div class="bubble-content">{{ originalRequirement }}</div>
          </div>
        </div>

        <template v-if="normalizedMessages.length">
          <div
            v-for="(message, index) in normalizedMessages"
            :key="`${message.role}-${index}`"
            class="message-row"
            :class="message.role === 'user' ? 'user' : 'assistant'"
          >
            <div v-if="message.role !== 'user'" class="avatar">
              <el-icon><ChatRound /></el-icon>
            </div>
            <div class="bubble" :class="message.role === 'user' ? 'user-bubble' : 'assistant-bubble'">
              <div class="bubble-label">{{ message.role === 'user' ? '你' : assistantLabel }}</div>
              <div v-if="message.role === 'user'" class="bubble-content">{{ message.content }}</div>
              <div v-else class="bubble-content markdown-content" v-html="renderMarkdown(message.content)" />
            </div>
          </div>
        </template>

        <div v-else class="message-row assistant">
          <div class="avatar">
            <el-icon><ChatRound /></el-icon>
          </div>
          <div class="bubble assistant-bubble">
            <div class="bubble-label">{{ assistantLabel }}</div>
            <div class="bubble-content markdown-content" v-html="renderMarkdown(assistantMessageText)" />
          </div>
        </div>
      </main>

      <footer class="composer-wrap">
        <div class="composer">
          <el-input
            v-model="draft"
            type="textarea"
            :autosize="{ minRows: 2, maxRows: 7 }"
            :maxlength="maxLength"
            resize="none"
            show-word-limit
            :placeholder="placeholderText"
            @keydown.ctrl.enter.prevent="handleSubmit"
            @keydown.meta.enter.prevent="handleSubmit"
          />
          <el-tooltip content="发送" placement="top">
            <el-button
              class="send-btn"
              type="primary"
              :icon="Position"
              circle
              :loading="loading"
              @click="handleSubmit"
            />
          </el-tooltip>
        </div>
        <div class="composer-hint">按 Ctrl + Enter 提交</div>
      </footer>
    </div>
  </el-drawer>
</template>

<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { ChatRound, Close, Document, Position } from '@element-plus/icons-vue'
import MarkdownIt from 'markdown-it'

type DrawerMode = 'create' | 'report'
type ChatMessage = {
  role: string
  content: string
}

const props = withDefaults(
  defineProps<{
    modelValue: boolean
    mode?: DrawerMode
    question?: string
    originalRequirement?: string
    researchBrief?: string
    messages?: ChatMessage[]
    modelText?: string
    loading?: boolean
    maxLength?: number
  }>(),
  {
    mode: 'create',
    question: '',
    originalRequirement: '',
    researchBrief: '',
    messages: () => [],
    modelText: '',
    loading: false,
    maxLength: 2000,
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'update:modelText': [value: string]
  submit: [value: string]
  close: []
}>()

const md = new MarkdownIt({ html: false, linkify: true, breaks: true })
const draft = ref(props.modelText)
const chatBodyRef = ref<HTMLElement | null>(null)

const isReportMode = computed(() => props.mode === 'report')
const titleText = computed(() => (isReportMode.value ? '修改需求' : '需求澄清'))
const modeTag = computed(() => (isReportMode.value ? '报告调整' : '继续解析'))
const subtitleText = computed(() =>
  isReportMode.value
    ? '像对话一样描述你想调整的方向，系统会基于你的回复继续处理。'
    : '请回答澄清问题，需求明确后会继续生成报告。',
)
const assistantLabel = computed(() => (isReportMode.value ? '分析助手' : '需求澄清助手'))
const assistantMessageText = computed(() => {
  if (props.question) return props.question
  return isReportMode.value
    ? '请告诉我你希望如何调整当前报告。'
    : '当前需求还需要补充一些关键信息，请说明分析目标、范围、数据来源偏好或输出要求。'
})
const placeholderText = computed(() =>
  isReportMode.value
    ? '例如：请补充近两年方法对比，并重点分析可复现性和工程成本。'
    : '例如：我希望输出排名报告，数据来源不限，重点比较评分、热度和特色。',
)
const normalizedMessages = computed(() => {
  const messages = [...props.messages]
  if (!messages.length && props.question) {
    messages.push({ role: 'assistant', content: props.question })
  }
  return messages.filter((message) => message.content)
})

watch(
  () => props.modelText,
  (value) => {
    draft.value = value
  },
)

watch(draft, (value) => {
  emit('update:modelText', value)
})

watch(
  () => [props.modelValue, normalizedMessages.value.length],
  () => {
    scrollToBottom()
  },
)

function renderMarkdown(content: string) {
  return md.render(content || '')
}

function scrollToBottom() {
  nextTick(() => {
    if (!chatBodyRef.value) return
    chatBodyRef.value.scrollTop = chatBodyRef.value.scrollHeight
  })
}

function handleSubmit() {
  const value = draft.value.trim()
  if (!value) {
    ElMessage.warning('请输入补充内容')
    return
  }

  emit('submit', value)
}
</script>

<style scoped>
.chat-shell {
  height: 100%;
  display: flex;
  flex-direction: column;
  background: #fff;
}

.chat-header {
  flex: 0 0 auto;
  display: grid;
  grid-template-columns: 38px minmax(0, 1fr) 34px;
  gap: 12px;
  align-items: center;
  padding: 18px 20px;
  border-bottom: 1px solid #eef0f3;
}

.agent-mark,
.avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  background: #111827;
}

.agent-mark {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  font-size: 18px;
}

.title-row {
  display: flex;
  align-items: center;
  gap: 9px;
}

.title-row h2 {
  margin: 0;
  font-size: 18px;
  line-height: 1.3;
  color: #111827;
}

.header-main p {
  margin: 5px 0 0;
  color: #6b7280;
  font-size: 12px;
  line-height: 1.5;
}

.chat-body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 22px 24px 18px;
  background: #fff;
}

.context-block {
  max-width: 86%;
  margin: 0 auto 22px;
  padding: 13px 14px;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  background: #f9fafb;
}

.context-title {
  display: flex;
  align-items: center;
  gap: 7px;
  margin-bottom: 8px;
  font-size: 12px;
  font-weight: 800;
  color: #374151;
}

.context-content {
  max-height: 180px;
  overflow: auto;
  color: #4b5563;
  font-size: 13px;
  line-height: 1.75;
}

.message-row {
  display: flex;
  gap: 10px;
  margin-bottom: 22px;
}

.message-row.assistant {
  align-items: flex-start;
}

.message-row.user {
  justify-content: flex-end;
}

.avatar {
  flex: 0 0 auto;
  width: 30px;
  height: 30px;
  border-radius: 8px;
  font-size: 16px;
  margin-top: 2px;
}

.bubble {
  max-width: min(500px, 82%);
  padding: 12px 14px;
  border-radius: 16px;
}

.assistant-bubble {
  color: #111827;
  background: #f4f4f5;
  border-top-left-radius: 6px;
}

.user-bubble {
  color: #fff;
  background: #111827;
  border-top-right-radius: 6px;
}

.bubble-label {
  margin-bottom: 6px;
  font-size: 11px;
  font-weight: 800;
  opacity: 0.72;
}

.bubble-content {
  word-break: break-word;
  font-size: 14px;
  line-height: 1.75;
}

.user-bubble .bubble-content {
  white-space: pre-wrap;
}

.markdown-content :deep(p),
.markdown-content :deep(ol),
.markdown-content :deep(ul) {
  margin: 0 0 10px;
}

.markdown-content :deep(p:last-child),
.markdown-content :deep(ol:last-child),
.markdown-content :deep(ul:last-child) {
  margin-bottom: 0;
}

.markdown-content :deep(ol),
.markdown-content :deep(ul) {
  padding-left: 20px;
}

.markdown-content :deep(li) {
  margin: 4px 0;
}

.markdown-content :deep(strong) {
  font-weight: 800;
}

.markdown-content :deep(code) {
  padding: 2px 5px;
  border-radius: 4px;
  background: rgba(17, 24, 39, 0.08);
}

.composer-wrap {
  flex: 0 0 auto;
  padding: 14px 20px 16px;
  border-top: 1px solid #eef0f3;
  background: #fff;
}

.composer {
  position: relative;
  border: 1px solid #dcdfe6;
  border-radius: 18px;
  padding: 4px 50px 4px 6px;
  background: #fff;
  box-shadow: 0 10px 28px rgba(17, 24, 39, 0.08);
}

.composer :deep(.el-textarea__inner) {
  border: 0;
  box-shadow: none;
  padding: 10px 8px;
  background: transparent;
  line-height: 1.7;
}

.composer :deep(.el-input__count) {
  right: 4px;
  bottom: -25px;
  background: transparent;
}

.send-btn {
  position: absolute;
  right: 10px;
  bottom: 10px;
  width: 32px;
  height: 32px;
  background: #111827;
  border-color: #111827;
}

.composer-hint {
  height: 18px;
  margin-top: 8px;
  text-align: center;
  font-size: 11px;
  color: #9ca3af;
}

@media (max-width: 760px) {
  .context-block,
  .bubble {
    max-width: 100%;
  }
}
</style>
