<template>
  <div class="page">
    <div class="content">
      <!-- 左侧：上传与解析 -->
      <el-card class="left" shadow="never">
        <template #header>
          <div class="card-title">
            <span>本地离线库 / 上传离线文件</span>
            <el-tag v-if="uiStateTag" :type="uiStateTag.type" size="small" effect="light">
              {{ uiStateTag.text }}
            </el-tag>
          </div>
        </template>

        <div class="steps">
          <el-steps :active="stepActive" align-center>
            <el-step title="选择文件" />
            <el-step title="选择类型" />
            <el-step title="开始解析" />
            <el-step title="确定入库" />
          </el-steps>
        </div>

        <div class="upload-box">
          <el-upload
            v-model:file-list="fileList"
            drag
            action="#"
            :auto-upload="false"
            :limit="1"
            :on-change="onFileChange"
            :on-remove="onFileRemove"
          >
            <el-icon class="upload-icon" :size="28"><UploadFilled /></el-icon>
            <div class="upload-text">
              <div class="primary">点击或拖拽选择文件</div>
              <div class="secondary">不会立即上传；点击“开始解析”才会上传并解析</div>
            </div>
          </el-upload>

          <div v-if="selectedFile" class="file-tip">
            已选择：
            <span class="fn">{{ selectedFile.name }}</span>
            <span class="meta">({{ humanSize(selectedFile.size) }})</span>
          </div>
        </div>

        <div class="section">
          <div class="section-title">
            <span>文档类型</span>
            <span class="hint">选择后才能开始解析</span>
          </div>

          <el-select
            v-model="selectedType"
            class="type-select"
            placeholder="请选择文档类型"
            clearable
          >
            <el-option v-for="t in docTypes" :key="t" :label="t" :value="t" />
          </el-select>

          <div class="actions">
            <el-button
              type="primary"
              :loading="parsing"
              :disabled="!selectedFile || !selectedType"
              @click="startParse"
            >
              开始解析
            </el-button>
            <el-button :disabled="parsing || ingesting" @click="resetAll">重置</el-button>
          </div>
        </div>

        <div class="note">
          <el-alert
            title="说明"
            type="info"
            :closable="false"
            show-icon
          >
            点击“开始解析”时，会把 文件 + 文档类型 一起发送到后端；后端返回 Markdown 解析结果。右侧支持预览/修改，确认无误后再入库。
          </el-alert>
        </div>
      </el-card>

      <!-- 右侧：Markdown 结果（预览/编辑） -->
      <el-card class="right" shadow="never">
        <template #header>
          <div class="right-header">
            <div class="card-title">
              <div class="title-left">
                <span>解析结果</span>
                <el-tag v-if="selectedFile" size="small" effect="plain" class="mini-tag">
                  {{ selectedFile.name }}
                </el-tag>
                <el-tag v-if="selectedType" size="small" effect="plain" class="mini-tag">
                  {{ selectedType }}
                </el-tag>
              </div>

              <div class="title-actions">
                <el-button
                  v-if="mdText"
                  :type="editing ? 'warning' : 'default'"
                  @click="toggleEdit"
                >
                  {{ editing ? '退出修改' : '修改' }}
                </el-button>

                <el-button
                  v-if="editing"
                  type="primary"
                  @click="saveMd"
                >
                  保存修改
                </el-button>

                <el-button
                  type="success"
                  :disabled="!mdText || ingesting"
                  :loading="ingesting"
                  @click="confirmIngest"
                >
                  确定入库
                </el-button>
              </div>
            </div>
            <!-- 方案一：标题区下方的“标签栏”（展示 + 编辑），不改变主体布局 -->
            <div v-if="mdText" class="tag-bar">
              <div class="tag-bar-left">
                <span class="tag-label">主题标签：</span>

                <!-- 展示态：分级标签（单行横向滚动，不挤压预览/源码区域） -->
                <div v-if="!tagEditing" class="tag-scroll" title="横向滚动查看更多">
                  <el-tag
                    v-for="(t, idx) in tagsPieces"
                    :key="`${t}-${idx}`"
                    size="small"
                    effect="plain"
                    class="tag-item"
                  >
                    {{ t }}
                  </el-tag>
                  <span v-if="!tags" class="tag-empty">未设置</span>
                </div>

                <!-- 编辑态：分类级联选择器（v-model 输出 string，如 计算机-AI-NLP） -->
                <div v-else class="tag-editor">
                  <TagsCategoryCascader
                    v-model="tagsDraft"
                    emit-as="string"
                    separator="-"
                    :clearable="true"
                    :filterable="true"
                  />
                </div>
              </div>

              <div class="tag-bar-actions">
                <el-button v-if="!tagEditing" size="small" @click="startTagEdit">编辑</el-button>

                <template v-else>
                  <el-button size="small" type="primary" @click="saveTags">保存</el-button>
                  <el-button size="small" @click="cancelTagEdit">取消</el-button>
                </template>
              </div>
            </div>
          </div>
        </template>

        <!-- 空态 -->
        <el-empty
          v-if="!parsing && !mdText"
          description="请选择文件与文档类型，然后开始解析"
        />

        <!-- 解析中 -->
        <div v-if="parsing" class="skeleton">
          <el-skeleton :rows="8" animated />
        </div>

        <!-- 结果展示 -->
        <div v-if="!parsing && mdText" class="md-wrap">
          <!-- 编辑模式：预览 + 源码 -->
          <div v-if="editing" class="md-grid">
            <div class="pane">
              <div class="pane-title">预览（双击段落可定位源码）</div>
              <div
                ref="previewRef"
                class="markdown-body md-preview"
                v-html="mdHtml"
                @dblclick="onPreviewDblClick"
              />
            </div>

            <div class="pane">
              <div class="pane-title">Markdown 源码</div>
              <textarea
                ref="textareaRef"
                v-model="mdDraft"
                class="md-editor"
                spellcheck="false"
                wrap="off"
              />
              <div class="editor-hint">
                提示：双击左侧预览的段落/标题/列表项，会自动定位到此处。
              </div>
            </div>
          </div>

          <!-- 预览模式：只显示 -->
          <div v-else class="pane">
            <div
              ref="previewRef"
              class="markdown-body md-preview"
              v-html="mdHtml"
              @dblclick="onPreviewDblClick"
            />
            <div class="preview-hint">
              点击“修改”可进行校正；也可双击段落自动进入修改并定位源码。
            </div>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import type { Options as MarkdownItOptions } from 'markdown-it'
import { parseFile, ingestFile } from '@/api/modules/uploadParseApi'
import TagsCategoryCascader from '@/components/TagsCategoryCascader.vue'

import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js'
import mk from 'markdown-it-katex'
import 'katex/dist/katex.min.css'
import 'github-markdown-css/github-markdown-light.css'
import 'highlight.js/styles/github.css'

/** =========================
 *  接口（按你后端实际改）
 *  =========================
 *  解析：multipart/form-data
 *    - file: 文件
 *    - doc_type: 文档类型（下拉框）
 *  返回：string（Markdown）
 *
 *  入库：application/json（建议）
 *    - doc_type
 *    - filename
 *    - markdown
 *    - (可选) parse_id
 */
// const API_PARSE = '/docs/upload/parse'
// const API_INGEST = '/uploadparse/ingest'
// const API_PARSE = 'http://127.0.0.1:4523/m2/7688138-7430664-default/405628960'
// const API_INGEST = '/uploadparse/ingest'

// const http = axios.create({
//   timeout: 30_000,
// })

/** =========================
 *  Markdown 渲染器
 *  ========================= */
const mdOptions: MarkdownItOptions = {
  html: true,
  linkify: true,
  breaks: true,
  highlight: (code: string, lang: string): string => {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return `<pre class="hljs"><code>${hljs.highlight(code, { language: lang }).value}</code></pre>`
      } catch {
        // ignore
      }
    }
    // 关键：这里不要用 md.utils，改用 MarkdownIt 自带工具或手动 escape
    const escaped = code
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;')
    return `<pre class="hljs"><code>${escaped}</code></pre>`
  },
}

const md = new MarkdownIt(mdOptions).use(mk, {
  throwOnError: false,
})

/** =========================
 *  左侧：文件与类型
 *  ========================= */
const docTypes = [
  'ACL',
  'CVPR',
  'arxiv',
  '专利',
  '技术报告',
  '说明书',
]

const fileList = ref<any[]>([])
const selectedFile = ref<File | null>(null)
const selectedType = ref<string>('')

function onFileChange(uploadFile: any) {
  selectedFile.value = uploadFile.raw ?? null
  // 重新选文件时，清掉旧结果
  clearResult()
}

function onFileRemove() {
  selectedFile.value = null
  clearResult()
}

function clearResult() {
  mdText.value = ''
  mdDraft.value = ''
  editing.value = false
  parsing.value = false
  ingesting.value = false
  ingestedOK.value = false
  parseId.value = null
  tags.value = ''
  tagsDraft.value = ''
  tagEditing.value = false
}

/** =========================
 *  解析：后端返回 Markdown string
 *  ========================= */
const parsing = ref(false)
const mdText = ref('')      // 最终确认的 md
const mdDraft = ref('')     // 编辑中的 md
const editing = ref(false)
const parseId = ref<string | null>(null) // 后端若将来愿意返回，可保留

/** =========================
 *  方案一：标题区下方标签（展示 + 编辑）
 *  - 后端 ParseResponse.tags: string，例如 “计算机-AI-NLP”
 *  - 前端编辑后，IngestRequest.tags: string，例如 “计算机-AI-CV”
 *  ========================= */

type TagModel = string | string[] | null | undefined

// 最终用于入库的标签（统一存 string）
const tags = ref<string>('')
// 编辑草稿：给 TagsCategoryCascader v-model 用（它的 emit 可能是 string 或 string[]）
const tagsDraft = ref<TagModel>('')
const tagEditing = ref(false)

const tagsPieces = computed(() => {
  return tags.value
    ? tags.value.split('-').map((s) => s.trim()).filter(Boolean)
    : []
})

function normalizeTagPath(v: TagModel, sep = '-') {
  if (!v) return ''
  const s = Array.isArray(v) ? v.join(sep) : String(v)
  return s
    .split(sep)
    .map((x) => x.trim())
    .filter(Boolean)
    .join(sep)
}

function startTagEdit() {
  tagsDraft.value = tags.value
  tagEditing.value = true
}

function cancelTagEdit() {
  tagsDraft.value = tags.value
  tagEditing.value = false
}

function saveTags() {
  tags.value = normalizeTagPath(tagsDraft.value)
  tagsDraft.value = tags.value
  tagEditing.value = false
  ElMessage.success('标签已保存')
}

async function startParse() {
  if (!selectedFile.value) return ElMessage.warning('请先选择文件')
  if (!selectedType.value) return ElMessage.warning('请先选择文档类型')

  parsing.value = true
  ingestedOK.value = false
  try {
    const form = new FormData()
    form.append('file', selectedFile.value)
    form.append('doc_type', selectedType.value)

    // 关键：responseType 用 text，确保后端返回 string 时不被当成 JSON 解析
    // const res = await http.post(API_PARSE, form, {
    //   headers: { 'Content-Type': 'multipart/form-data' },
    //   responseType: 'text',
    // })

    const data = await parseFile(form)

    // const raw = String(res.data ?? '')
    // // 若将来后端改成 JSON（例如 { parse_id, markdown }），这里也兼容一下
    // const maybeJson = tryParseJson(raw)

    mdText.value = data.md
    mdDraft.value = data.md
    parseId.value = data.parse_id
    tags.value = normalizeTagPath(data.labels)
    tagsDraft.value = tags.value
    tagEditing.value = false
    // if (maybeJson && typeof maybeJson === 'object') {
    //   const anyObj = maybeJson as any
    //   const mdStr = String(anyObj.markdown ?? anyObj.md ?? anyObj.content ?? '')
    //   mdText.value = mdStr
    //   mdDraft.value = mdStr
    //   parseId.value = anyObj.parse_id ? String(anyObj.parse_id) : null
    // } else {
    //   mdText.value = raw
    //   mdDraft.value = raw
    // }

    if (!mdText.value.trim()) {
      ElMessage.warning('后端返回为空，请检查解析服务输出')
    } else {
      ElMessage.success('解析完成（Markdown 已返回）')
    }
  } catch (e: any) {
    ElMessage.error(axiosErrorMessage(e))
  } finally {
    parsing.value = false
  }
}

// function tryParseJson(text: string) {
//   const t = text.trim()
//   if (!t.startsWith('{') && !t.startsWith('[')) return null
//   try {
//     return JSON.parse(t)
//   } catch {
//     return null
//   }
// }

/** =========================
 *  Markdown 预览 HTML
 *  ========================= */
const mdHtml = computed(() => {
  const source = editing.value ? mdDraft.value : mdText.value
  return md.render(source || '')
})

/** =========================
 *  修改 / 保存
 *  ========================= */
function toggleEdit() {
  if (!mdText.value) return
  if (!editing.value) {
    mdDraft.value = mdText.value
    editing.value = true
    nextTick(() => textareaRef.value?.focus())
  } else {
    // 退出修改：不覆盖 mdText（相当于取消）
    editing.value = false
    mdDraft.value = mdText.value
  }
}

function saveMd() {
  mdText.value = mdDraft.value
  editing.value = false
  ElMessage.success('已保存修改（入库前生效）')
}

/** =========================
 *  双击预览：定位源码
 *  ========================= */
const previewRef = ref<HTMLElement | null>(null)
const textareaRef = ref<HTMLTextAreaElement | null>(null)

function onPreviewDblClick(evt: MouseEvent) {
  const root = previewRef.value
  if (!root) return

  const target = evt.target as HTMLElement | null
  const block = findNearestBlock(target, root)
  if (!block) return

  const text = (block.innerText || '').trim()
  if (text.length < 4) return

  // 不在编辑状态：自动进入编辑再跳
  if (!editing.value) {
    mdDraft.value = mdText.value
    editing.value = true
    nextTick(() => jumpToSource(text))
    return
  }

  jumpToSource(text)
}

function findNearestBlock(el: HTMLElement | null, root: HTMLElement) {
  let cur = el
  const accept = new Set(['P', 'LI', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'BLOCKQUOTE'])
  while (cur && cur !== root) {
    if (accept.has(cur.tagName)) return cur
    cur = cur.parentElement
  }
  return null
}

function jumpToSource(previewText: string) {
  const ta = textareaRef.value
  if (!ta) return

  const src = mdDraft.value
  const normalized = normalizeText(previewText)

  // 先用完整文本找
  let idx = indexOfNormalized(src, normalized)

  // 找不到则用前 30 字找（更稳）
  if (idx < 0) {
    const short = normalized.slice(0, Math.min(30, normalized.length))
    idx = indexOfNormalized(src, short)
  }

  if (idx < 0) {
    ElMessage.warning('未能定位到对应源码片段（可能是渲染后文本与源码不完全一致）')
    return
  }

  // 光标定位
  ta.focus()
  ta.setSelectionRange(idx, idx)

  // 粗略滚动到附近行（避免定位了但看不到）
  const line = src.slice(0, idx).split('\n').length
  const approxLineHeight = 20
  ta.scrollTop = Math.max(0, (line - 3) * approxLineHeight)
}

function normalizeText(s: string) {
  return s.replace(/\s+/g, ' ').trim()
}

/**
 * 在源码中用“归一化文本”查找位置：
 * - 源码含换行、多个空格；预览 text 会被折叠，所以需要归一化后再找
 */
function indexOfNormalized(source: string, needleNormalized: string) {
  if (!needleNormalized) return -1
  const srcNorm = normalizeText(source)
  const posInNorm = srcNorm.indexOf(needleNormalized)
  if (posInNorm < 0) return -1

  // 把"归一化后的下标"映射回原始字符串下标：用逐字符扫描近似回推
  // 这是近似映射，但足够用于跳转定位
  let normCount = 0
  for (let i = 0; i < source.length; i++) {
    const ch = source.charAt(i) // 使用 charAt 避免 undefined
    const isSpace = /\s/.test(ch)
    if (isSpace) {
      // 归一化后空白折叠为单个空格：只在前一个不是空白时计一次
      const prevIsSpace = i > 0 ? /\s/.test(source.charAt(i - 1)) : false
      if (!prevIsSpace) normCount += 1
    } else {
      normCount += 1
    }
    if (normCount >= posInNorm + 1) return i
  }
  return -1
}

/** =========================
 *  入库：保留功能（发送最终 md）
 *  ========================= */
const ingesting = ref(false)
const ingestedOK = ref(false)

async function confirmIngest() {
  if (!mdText.value.trim()) return ElMessage.warning('没有可入库的解析结果')
  if (!selectedType.value) return ElMessage.warning('请先选择文档类型')

  try {
    await ElMessageBox.confirm(
      '确认将当前校正后的 Markdown 解析结果入库？',
      '确定入库',
      { type: 'warning', confirmButtonText: '确认', cancelButtonText: '取消' }
    )
  } catch {
    return
  }

  ingesting.value = true
  try {
    const res = await ingestFile({
      doc_type: selectedType.value,
      filename: selectedFile.value?.name ?? '',
      md: mdText.value,
      labels: tags.value,
      parse_id: parseId.value,
    })

    ingestedOK.value = true
    ElMessage.success(`入库成功${res?.doc_id ? `：doc_id=${res.doc_id}` : ''}`)
  } catch (e: any) {
    ElMessage.error(axiosErrorMessage(e))
  } finally {
    ingesting.value = false
  }
}

/** =========================
 *  步骤条与状态
 *  ========================= */
const stepActive = computed(() => {
  // Element Plus Steps 的 active 是 0..(steps-1)，4 个步骤最大为 3
  if (!selectedFile.value) return 0
  if (selectedFile.value && !selectedType.value) return 1
  if (parsing.value || !mdText.value) return 2
  return 3
})

const uiStateTag = computed(() => {
  if (ingestedOK.value) return { type: 'success' as const, text: '已入库' }
  if (parsing.value) return { type: 'warning' as const, text: '解析中' }
  if (mdText.value) return { type: 'success' as const, text: '解析完成' }
  return null
})

/** =========================
 *  重置
 *  ========================= */
function resetAll() {
  fileList.value = []
  selectedFile.value = null
  selectedType.value = ''
  clearResult()
  ElMessage.info('已重置页面状态')
}

/** =========================
 *  工具
 *  ========================= */
function axiosErrorMessage(e: any) {
  if (axios.isAxiosError(e)) {
    const msg = (e.response?.data && (e.response.data.message || e.response.data.msg)) || e.message
    return String(msg || '网络错误')
  }
  return String(e?.message || '未知错误')
}

function humanSize(bytes: number) {
  const kb = bytes / 1024
  if (kb < 1024) return `${kb.toFixed(1)} KB`
  const mb = kb / 1024
  if (mb < 1024) return `${mb.toFixed(1)} MB`
  const gb = mb / 1024
  return `${gb.toFixed(2)} GB`
}
</script>

<style scoped>
.page {
  width: 100%;
  height: 100%;
  padding: 16px 18px 22px;
  box-sizing: border-box;
  background: #f6f7fb;
  display: flex;
}

.content {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 420px 1fr;
  gap: 16px;
  align-items: stretch;
}

@media (max-width: 1100px) {
  .content {
    grid-template-columns: 1fr;
  }
}

.left,
.right {
  height: 100%;
  border-radius: 14px;
  border: 1px solid #e6edf7;
  display: flex;
  flex-direction: column;
}

/* 让 el-card body 填满 */
:deep(.left .el-card__body) {
  height: 100%;
  display: flex;
  flex-direction: column;
}
:deep(.right .el-card__body) {
  flex: 1;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.card-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-weight: 800;
  color: #111827;
}

/* 右侧 header：保持原视觉，只在标题下方追加一行“标签栏” */
.right-header {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.tag-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.tag-bar-left {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.tag-label {
  font-size: 12px;
  font-weight: 700;
  color: #374151;
  flex: 0 0 auto;
}

.tag-scroll {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: nowrap;
  overflow-x: auto;
  overflow-y: hidden;
  padding-bottom: 2px;
}

.tag-item {
  flex: 0 0 auto;
}

.tag-empty {
  font-size: 12px;
  color: #9ca3af;
}

.tag-editor {
  flex: 1;
  min-width: 260px;
  max-width: 720px;
}

/* 级联选择器在标签栏中占满可用宽度 */
:deep(.tag-editor .el-cascader) {
  width: 100%;
}

.tag-bar-actions {
  flex: 0 0 auto;
  display: flex;
  gap: 8px;
}

.title-left {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}
.mini-tag {
  max-width: 650px;
  overflow: hidden;
  text-overflow: ellipsis;
}
.title-actions {
  display: flex;
  gap: 10px;
}

.steps {
  margin: 18px 0 8px;
}

.upload-box {
  margin-top: 10px;
}
:deep(.el-upload-dragger) {
  border-radius: 14px;
  border: 1px dashed #cbd5e1;
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}
.upload-icon {
  margin-bottom: 10px;
  color: #4f46e5;
}
.upload-text .primary {
  font-size: 14px;
  font-weight: 800;
  color: #111827;
}
.upload-text .secondary {
  margin-top: 4px;
  font-size: 12px;
  color: #6b7280;
}

.file-tip {
  margin-top: 10px;
  font-size: 12px;
  color: #6b7280;
}
.file-tip .fn {
  color: #111827;
  font-weight: 700;
}
.file-tip .meta {
  margin-left: 8px;
}

.section {
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid #eef2f7;
}
.section-title {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  font-size: 13px;
  font-weight: 800;
  color: #111827;
  margin-bottom: 10px;
}
.hint {
  font-size: 12px;
  font-weight: 500;
  color: #6b7280;
}
.type-select {
  width: 100%;
}
.actions {
  margin-top: 12px;
  display: flex;
  gap: 12px;
}
.note {
  margin-top: auto;
}

.skeleton {
  padding: 8px 2px;
}

.md-wrap {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

.md-grid {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: minmax(0, 60%) minmax(0, 40%);
  gap: 12px;
}

@media (max-width: 1200px)   {
  .md-grid {
    grid-template-columns: 1fr;
  }
}

.pane {
  flex: 1;
  min-height: 0;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.pane-title {
  font-size: 12px;
  font-weight: 800;
  color: #111827;
  margin-bottom: 8px;
}

.md-preview {
  flex: 1 1 0;
  height: 0; 
  min-height: 0;
  min-width: 0;
  overflow-x: auto;
  overflow-y: auto;
  padding: 14px 16px;
  background: #fff;
  border: 1px solid #eef2f7;
  border-radius: 12px;
  word-break: normal;
  overflow-wrap: normal;
}
.md-preview pre{
  max-width: 100%;
  overflow-x: auto;
  white-space: pre;
}
/* 表格：超出就横向滚动 */
.md-preview table {
  display: block;
  max-width: 100%;
  overflow-x: auto;
}
/* 图片：不要把容器撑宽 */
.md-preview img {
  max-width: 100%;
  height: auto;
}
/* 让预览整体不换行，从而产生横向滚动条 */
.md-preview.markdown-body {
  white-space: pre;     /* 或 pre-wrap，看你要不要保留换行 */
}
.md-preview,
.md-preview * {
  min-width: 0;
}
.md-editor {
  flex: 1 1 0;
  height: 0;
  min-height: 0;
  min-width: 0;
  overflow: auto;
  width: 100%;
  resize: none;
  padding: 12px;
  border-radius: 12px;
  border: 1px solid #eef2f7;
  background: #fff;
  outline: none;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New",
    monospace;
  font-size: 13px;
  line-height: 1.55;
  white-space:pre;
}

.editor-hint,
.preview-hint {
  margin-top: 8px;
  font-size: 12px;
  color: #6b7280;
}

:deep(.el-input__wrapper) {
  border-radius: 12px;
}
</style>
