<template>
  <div class="page">


    <div class="content">
      <!-- 左侧：上传 + 类型选择 + 解析 -->
      <el-card class="left" shadow="never">
        <template #header>
          <div class="card-title">
            <span>本地离线库 / 上传离线文件</span>
            <el-tag v-if="uiStateTag" :type="uiStateTag.type" effect="plain">
              {{ uiStateTag.text }}
            </el-tag>
          </div>
        </template>

        <el-steps :active="stepActive" finish-status="success" align-center class="steps">
          <el-step title="选择文件" />
          <el-step title="选择类型" />
          <el-step title="开始解析" />
          <el-step title="确定入库" />
        </el-steps>

        <!-- 上传区：不自动上传，只选择文件 -->
        <div class="upload-box">
          <el-upload
            class="uploader"
            drag
            :auto-upload="false"
            :limit="1"
            :show-file-list="true"
            :file-list="fileList"
            :on-change="onFileChange"
            :on-remove="onRemove"
            accept=".pdf,.doc,.docx,.txt"
          >
            <el-icon class="upload-icon"><UploadFilled /></el-icon>
            <div class="upload-text">
              <div class="primary">点击或拖拽选择文件</div>
              <div class="secondary">不会立即上传；点击“开始解析”才会上传并解析</div>
            </div>
          </el-upload>

          <div v-if="selectedFile" class="file-tip">
            已选择：<span class="fn">{{ selectedFile.name }}</span>
            <span class="meta">({{ humanSize(selectedFile.size) }})</span>
          </div>
        </div>

        <!-- 文档类型：下拉框单选 -->
        <div class="section">
          <div class="section-title">
            文档类型
            <span class="hint">选择后才能开始解析</span>
          </div>

          <el-select
            v-model="selectedType"
            class="type-select"
            placeholder="请选择文档类型"
            :disabled="!selectedFile || parsing"
            clearable
          >
            <el-option
              v-for="t in docTypeOptions"
              :key="t.value"
              :label="t.label"
              :value="t.value"
            />
          </el-select>
        </div>

        <!-- 开始解析 -->
        <div class="section actions">
          <el-button
            type="primary"
            size="large"
            :loading="parsing"
            :disabled="!canParse"
            @click="startParse"
          >
            开始解析
          </el-button>

          <el-button
            size="large"
            :disabled="parsing || ingesting"
            @click="resetAll"
          >
            重置
          </el-button>
        </div>

        <el-alert
          class="note"
          type="info"
          show-icon
          :closable="false"
          title="说明"
          description="点击“开始解析”时，会将文件 + 文档类型一起发送到后端；后端返回解析结果后在右侧展示，确认无误后可入库。"
        />
      </el-card>

      <!-- 右侧：解析结果 -->
      <el-card class="right" shadow="never">
        <template #header>
          <div class="card-title">
            <span>解析结果</span>
            <div class="right-actions">
              <el-button
                type="success"
                :loading="ingesting"
                :disabled="!parseResult || parsing"
                @click="confirmIngest"
              >
                确定入库
              </el-button>
            </div>
          </div>
        </template>

        <!-- 未解析：空状态 -->
        <el-empty
          v-if="!parseResult && !parsing"
          description="请选择文件与文档类型，然后开始解析"
        />

        <!-- 解析中：骨架屏 -->
        <div v-if="parsing" class="skeleton">
          <el-skeleton :rows="10" animated />
        </div>

        <!-- 解析完成：展示结果 -->
        <div v-if="parseResult && !parsing" class="result">
          <div class="block-title">文档基础信息</div>

          <el-descriptions :column="2" border class="desc">
            <el-descriptions-item label="文档ID">{{ parseResult.docId }}</el-descriptions-item>
            <el-descriptions-item label="原文档ID">{{ parseResult.rawDocId }}</el-descriptions-item>
            <el-descriptions-item label="文件名">{{ parseResult.filename }}</el-descriptions-item>
            <el-descriptions-item label="语言">{{ parseResult.language }}</el-descriptions-item>
            <el-descriptions-item label="文档类型">{{ parseResult.docType }}</el-descriptions-item>
            <el-descriptions-item label="来源">{{ parseResult.source }}</el-descriptions-item>
            <el-descriptions-item label="出版时间">{{ parseResult.publishTime }}</el-descriptions-item>
            <el-descriptions-item label="作者">{{ parseResult.authors }}</el-descriptions-item>
            <el-descriptions-item label="关键词" :span="2">
              <el-tag v-for="k in parseResult.keywords" :key="k" class="kw" effect="plain">
                {{ k }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="状态" :span="2">
              {{ parseResult.status }}
            </el-descriptions-item>
          </el-descriptions>

          <div class="block-title" style="margin-top: 16px;">章节结构</div>

          <el-table :data="parseResult.sections" border stripe class="table">
            <el-table-column prop="name" label="章节名" min-width="180" />
            <el-table-column prop="pages" label="页码" width="120" />
            <el-table-column prop="summary" label="内容摘要" min-width="320" />
            <el-table-column label="操作" width="120" align="center">
              <template #default="{ row }">
                <el-button type="primary" link @click="openEdit(row)">修改</el-button>
              </template>
            </el-table-column>
          </el-table>

          <div class="bottom-hint">
            入库前可人工修订章节摘要，提升结构化质量。
          </div>
        </div>
      </el-card>
    </div>

    <!-- 编辑摘要弹窗 -->
    <el-dialog v-model="editDialogVisible" title="修改章节摘要" width="640px">
      <el-form label-width="80px">
        <el-form-item label="章节名">
          <el-input v-model="editDraft.name" disabled />
        </el-form-item>
        <el-form-item label="页码">
          <el-input v-model="editDraft.pages" disabled />
        </el-form-item>
        <el-form-item label="摘要">
          <el-input
            v-model="editDraft.summary"
            type="textarea"
            :rows="6"
            maxlength="600"
            show-word-limit
            placeholder="请输入更准确的章节摘要..."
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveEdit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import type { UploadFile, UploadFiles } from 'element-plus'

/** =========================
 *  后端接口
 *  =========================
 *  解析接口：接收 multipart/form-data
 *    - file: File
 *    - doc_type: string
 *  返回：解析结果（包含 parse_id、sections 等）
 */
// const API_PARSE  = '/uploadparse/parse'
// const API_INGEST = '/uploadparse/ingest'
// const API_PARSE = '/docs/upload/parse'
const API_PARSE  = 'http://127.0.0.1:4523/m2/7688138-7430664-default/403780010'
const API_INGEST = 'api/m2/7688138-7430664-default/403844369'

/** axios 实例 */
const http = axios.create({
  // baseURL: 'http://192.168.19.19:8000', // 若需要可打开
  timeout: 60_000,
})

/** =========================
 *  类型定义
 *  ========================= */
type DocTypeValue = 'ACL' | '专利' | '技术报告' | '新闻' | '其他'

interface SectionItem {
  name: string
  pages: string
  summary: string
}

interface ParseResult {
  parseId: string
  docId: string
  rawDocId: string
  filename: string
  language: string
  docType: string
  source: string
  publishTime: string
  authors: string
  keywords: string[]
  status: string
  sections: SectionItem[]
}

/** =========================
 *  UI 状态
 *  ========================= */

const fileList = ref<UploadFile[]>([])   // 给 el-upload 展示用
const selectedFile = ref<File | null>(null)

const selectedType = ref<DocTypeValue | ''>('')

const parsing = ref(false)
const ingesting = ref(false)
const ingestedOK = ref(false)
const parseResult = ref<ParseResult | null>(null)

const docTypeOptions = [
  { label: 'ACL', value: 'ACL' as const },
  { label: '专利', value: '专利' as const },
  { label: '技术报告', value: '技术报告' as const },
  { label: '新闻', value: '新闻' as const },
  { label: '其他', value: '其他' as const },
]


const canParse = computed(() => !!selectedFile.value && !!selectedType.value && !parsing.value)

const stepActive = computed(() => {
  if (!selectedFile.value) {
    // console.log('stepActive=0');
    return 0;
  }
  
  if (selectedFile.value && !selectedType.value){
    // console.log('stepActive=1');
    return 1;
  } 
  
  if (!parseResult.value) {
    // console.log('stepActive=2')
    return 2;
  }
  if (parseResult.value&&!ingestedOK.value){
    // console.log('stepActive=3')
    return 3
  }
  // console.log('stepActive=4')
  return 4
})

const uiStateTag = computed(() => {
  if (ingesting.value) return { type: 'warning' as const, text: '入库中' }
  if (parsing.value) return { type: 'warning' as const, text: '解析中' }
  if (parseResult.value) return { type: 'success' as const, text: '解析完成' }
  if (selectedFile.value) return { type: 'info' as const, text: '已选择文件' }
  if(ingestedOK.value)return { type: 'success' as const, text: '已入库' }
  return null
})



function onFileChange(uploadFile: UploadFile, uploadFiles: UploadFiles) {
  const raw = uploadFile.raw as File | undefined
  if (!raw) return

  const maxMB = 50
  if (raw.size / 1024 / 1024 > maxMB) {
    ElMessage.error(`文件过大：请控制在 ${maxMB}MB 内`)
    fileList.value = []
    selectedFile.value = null
    return
  }

  // 只保留最后一个
  fileList.value = uploadFiles.slice(-1)
  selectedFile.value = (uploadFile.raw as File) || null

  // 换文件时清掉旧解析结果与类型（防止错配）
  parseResult.value = null
  selectedType.value = ''
}

function onRemove() {
  fileList.value = []
  selectedFile.value = null
  selectedType.value = ''
  parseResult.value = null
  ElMessage.info('已移除文件')
}

/** =========================
 *  开始解析：文件 + 类型 一起上传给后端
 *  ========================= */
async function startParse() {
  if (!canParse.value || !selectedFile.value || !selectedType.value) return

  parsing.value = true
  parseResult.value = null

  try {
    const form = new FormData()
    form.append('file', selectedFile.value)
    form.append('doc_type', selectedType.value)

    const res = await http.post(API_PARSE, form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    console.log(res.data.data[0]);

    parseResult.value = normalizeParseResult(res.data.data[0])
    ElMessage.success('解析完成')
  } catch (e: any) {
    ElMessage.error(`解析失败：${axiosErrorMessage(e)}`)
  } finally {
    parsing.value = false
  }
}

/** =========================
 *  入库：将解析结果写入数据库
 *  ========================= */
async function confirmIngest() {
  if (!parseResult.value) return

  try {
    await ElMessageBox.confirm(
      '确认将解析结果入库？入库后将写入数据库并可在后续模块检索使用。',
      '确定入库',
      { type: 'warning', confirmButtonText: '入库', cancelButtonText: '取消' }
    )
  } catch {
    return
  }

  ingesting.value = true
  try {
    await http.post(API_INGEST, {
      // parse_id: parseResult.value.parseId,
      result: parseResult.value,
    })
    ingestedOK.value=true;
    ElMessage.success('入库成功')
  } catch (e: any) {
    ElMessage.error(`入库失败：${axiosErrorMessage(e)}`)
  } finally {
    
    ingesting.value = false
  }
}

/** =========================
 *  章节摘要编辑
 *  ========================= */
const editDialogVisible = ref(false)
const editDraft = reactive<SectionItem>({ name: '', pages: '', summary: '' })
let editingRef: SectionItem | null = null

function openEdit(row: SectionItem) {
  editingRef = row
  editDraft.name = row.name
  editDraft.pages = row.pages
  editDraft.summary = row.summary
  editDialogVisible.value = true
}

function saveEdit() {
  if (!editingRef) return
  editingRef.summary = editDraft.summary
  editDialogVisible.value = false
  ElMessage.success('已更新章节摘要（入库前生效）')
}

/** =========================
 *  重置
 *  ========================= */
function resetAll() {
  fileList.value = []
  selectedFile.value = null
  selectedType.value = ''
  parseResult.value = null
  parsing.value = false
  ingesting.value = false
  ingestedOK.value = false
  ElMessage.info('已重置页面状态')
}

/** =========================
 *  工具：后端返回字段归一化
 *  ========================= */
function normalizeParseResult(data: any): ParseResult {
  const keywords =
    Array.isArray(data.keywords) ? data.keywords :
    typeof data.keywords === 'string' ? data.keywords.split(/[，,\/]/).map((s: string) => s.trim()).filter(Boolean) :
    []

  return {
    parseId: String(data.parse_id ?? data.parseId ?? 'parse_1'),
    docId: String(data.doc_id ?? data.docId ?? '1'),
    rawDocId: String(data.raw_doc_id ?? data.rawDocId ?? '1'),
    filename: String(data.filename ?? selectedFile.value?.name ?? 'unknown'),
    language: String(data.language ?? '—'),
    docType: String(data.doc_type ?? selectedType.value ?? '—'),
    source: String(data.source ?? '本地上传'),
    publishTime: String(data.publish_time ?? data.publishTime ?? '—'),
    authors: String(data.authors ?? '—'),
    keywords,
    status: String(data.status ?? '已解析 / 已生成结构化结果'),
    sections: Array.isArray(data.sections)
      ? data.sections.map((x: any) => ({
          name: String(x.name ?? ''),
          pages: String(x.pages ?? ''),
          summary: String(x.summary ?? ''),
        }))
      : [],
  }
}

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
  flex:1;
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

/* 让卡片 body 也填满（否则 card 仍然不会撑开） */
:deep(.left .el-card__body) {
  height: 100%;
  display: flex;
  flex-direction: column;
}
:deep(.right .el-card__body) {
  flex: 1;
  min-height: 0;
  overflow: auto;
}

.card-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-weight: 800;
  color: #111827;
}

.steps {
  margin: 40px 0px;
}

/* 上传区 */
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
  /* overflow: auto; */
}


/* section */
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
  display: flex;
  gap: 12px;
}

.note {
  margin-top: auto;
}

/* 右侧结果 */
.result {
  padding-bottom: 6px;
}
.block-title {
  font-size: 14px;
  font-weight: 900;
  color: #111827;
  margin-bottom: 10px;
}
.desc {
  border-radius: 12px;
  overflow: hidden;
}
.kw {
  margin-right: 8px;
  margin-bottom: 6px;
}
.table {
  border-radius: 12px;
  overflow: hidden;
}
.bottom-hint {
  margin-top: 10px;
  font-size: 12px;
  color: #6b7280;
}
.skeleton {
  padding: 8px 2px;
}

:deep(.el-input__wrapper) {
  border-radius: 12px;
}
</style>
