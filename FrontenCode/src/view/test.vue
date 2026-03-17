<template>
  <div class="page">
    <!-- 顶部栏 -->
    <div class="header">
      <div class="header-left">
        <div class="title">新建需求</div>
        <div class="sub">填写研究主题与检索条件，点击“解析需求”进入后续完善流程</div>
      </div>

      <div class="header-right">
        <el-button plain @click="goBack">返回列表</el-button>
      </div>
    </div>

    <div class="content" v-loading="loading">
      <!-- 左：表单 -->
      <el-card class="card form-card" shadow="never">
        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          class="form"
        >
          <el-form-item label="主题/技术方向" prop="name">
            <el-input
              v-model="form.name"
              placeholder="请输入研究主题或技术方向"
              maxlength="80"
              show-word-limit
            />
          </el-form-item>

          <el-form-item label="时间范围" prop="dateRange">
            <el-date-picker
              v-model="form.dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              style="width: 360px"
            />
          </el-form-item>

          <el-form-item label="文档类型" prop="docTypes">
            <el-checkbox-group v-model="form.docTypes">
              <el-checkbox v-for="type in REQUIREMENT_DOC_TYPE_ALL " :key="type" :label="type">
                {{ type }} 
              </el-checkbox> 
            </el-checkbox-group>
          </el-form-item>

          <el-form-item label="关键词" prop="keywords">
            <!-- PPT效果：输入关键词，回车确认；这里用 el-select 多选+可创建实现 -->
            <el-select
              v-model="form.keywords"
              multiple
              filterable
              allow-create
              default-first-option
              placeholder="请输入关键词，按回车确认"
              style="width: 100%"
            />
          </el-form-item>

          <el-form-item label="具体需求" prop="detail">
            <el-input
              v-model="form.detail"
              type="textarea"
              :rows="7"
              placeholder="请输入你的具体需求，例如：希望对某方向进行技术路线梳理、对比近两年方法优缺点、给出可复现的基线与改进点等…"
              maxlength="2000"
              show-word-limit
              class="no-resize"
            />
          </el-form-item>

          <div class="footer">
            <el-button @click="reset">重置</el-button>
            <el-button
              type="primary"
              :loading="submitting"
              :icon="MagicStick"
              @click="submit"
            >
              解析需求
            </el-button>
          </div>
        </el-form>
      </el-card>

      <!-- 右：预览与提示 -->
      <div class="side">
        <el-card class="card" shadow="never">
          <div class="side-title">请求 JSON 预览</div>
          <el-input
            class="preview no-resize"
            type="textarea"
            :rows="14"
            :model-value="payloadPreview"
            readonly
          />
          <div class="side-actions">
            <el-button size="small" plain @click="copyPreview">复制</el-button>
          </div>
        </el-card>

        <el-card class="card tips" shadow="never">
          <div class="side-title">填写建议</div>
          <ul class="tips-list">
            <li>主题尽量包含领域与任务，例如：夜晚 UAV 小目标检测 / 雾霾鲁棒检测。</li>
            <li>关键词建议包含：任务词 + 场景词 + 方法词（可多组）。</li>
            <li>时间范围可先给近 3–5 年，后续可在完善页继续细化。</li>
            <li>点击“解析需求”后将进入需求完善/后续交互流程（与 PPT 一致）。</li>
          </ul>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'
import { MagicStick } from '@element-plus/icons-vue'

import { createRequirement } from '@/api/modules/requirementsApi'
import  {type  RequirementCreateRequest, type RequirementDocType, REQUIREMENT_DOC_TYPE_ALL} from '@/api/modules/requirementsApi'
const router = useRouter()

const formRef = ref<FormInstance>()

const form = reactive<{
  name: string
  dateRange: [string, string] | null
  docTypes: RequirementDocType[]
  keywords: string[]
  detail: string
}>({
  name: '',
  dateRange: null,
  docTypes: ['ACL'],
  keywords: [],
  detail: '',
})

const rules: FormRules = {
  name: [{ required: true, message: '请填写主题/技术方向', trigger: 'blur' }],
  dateRange: [{ required: true, message: '请选择时间范围', trigger: 'change' }],
  docTypes: [
    {
      type: 'array',
      required: true,
      min: 1,
      message: '至少选择一种文档类型',
      trigger: 'change',
    },
  ],
  detail: [{ required: true, message: '请填写具体需求', trigger: 'blur' }],
}

const loading = ref(false)
const submitting = ref(false)

function buildPayload(): RequirementCreateRequest {
  const [start, end] = form.dateRange ?? [undefined, undefined]
  return {
    name: form.name.trim(),
    startDate: start,
    endDate: end,
    docTypes: form.docTypes,
    keywords: (form.keywords || []).map((x) => String(x).trim()).filter(Boolean),
    detail: form.detail.trim(),
  }
}

const payloadPreview = computed(() => {
  const p = buildPayload()
  return JSON.stringify(p, null, 2)
})

function goBack() {
  router.push('/RequirementList')
}

function reset() {
  form.name = ''
  form.dateRange = null
  form.docTypes = ['ACL']
  form.keywords = []
  form.detail = ''
}

async function submit() {
  if (!formRef.value) return

  try {
    loading.value = true
    submitting.value = true

    await formRef.value.validate()

    const payload = buildPayload()
    const resp = await createRequirement(payload)
    const item = (resp as any)?.item ?? resp

    if (!item?.id) {
      ElMessage.warning('后端未返回有效的需求 ID')
      return
    }

    ElMessage.success('需求已解析，进入后续完善流程')

    // PPT：解析后进入“需求完善/后续交互”
    // 若你暂时没做 refine 页，这里可先跳回列表：router.push('/requirements')
    try {
      await router.push(`/requirements/${item.id}/refine`)
    } catch {
      await router.push('/requirements')
    }
  } catch (e: any) {
    // element-plus validate 抛错时不需要额外提示；API 错误才提示
    if (e?.message) ElMessage.error(e.message)
  } finally {
    loading.value = false
    submitting.value = false
  }
}

async function copyPreview() {
  try {
    await navigator.clipboard.writeText(payloadPreview.value)
    ElMessage.success('已复制')
  } catch {
    ElMessage.warning('复制失败，请手动复制')
  }
}
</script>

<style scoped>
.page {
  width: 100%;
  height: 100%;
  min-height: 100vh;
  min-height: 100%;
  padding: 22px 26px;
  box-sizing: border-box;
  background: #f6f7fb;
}

.header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 18px;
  margin-bottom: 16px;
}

.title {
  font-size: 20px;
  font-weight: 800;
  color: #111827;
}

.sub {
  margin-top: 6px;
  font-size: 12px;
  color: #6b7280;
}

.content {
  flex:1;
  display: grid;
  height: 100%;
  grid-template-columns: 1fr 360px;
  gap: 16px;
  align-items: start;
}

.card {
  border-radius: 16px;
  border: 1px solid #e6edf7;
  background: #fff;
}

.form-card :deep(.el-card__body) {
  padding: 16px 18px;
}

.form :deep(.el-form-item__label) {
  font-weight: 700;
  color: #111827;
}

.footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 6px;
}

.side {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.side-title {
  font-size: 13px;
  font-weight: 800;
  color: #111827;
  margin-bottom: 10px;
}

.side-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 10px;
}

.tips :deep(.el-card__body) {
  padding: 14px 16px;
}

.tips-list {
  margin: 0;
  padding-left: 18px;
  color: #374151;
  font-size: 12px;
  line-height: 1.8;
}

.no-resize :deep(textarea) {
  resize: none;
}

/* 响应式：窄屏堆叠 */
@media (max-width: 1100px) {
  .content {
    grid-template-columns: 1fr;
  }
}
</style>
