<script setup lang="ts">
import { onMounted, ref } from "vue"
import type { TableItem } from '@/types/type/types'
import { getFileList } from "@/api/modules/uploadParseApi"
const getImageUrl = (name: string) => {
  return new URL(`../assets/images/${name}.png`, import.meta.url).href
}

const tableData = ref<TableItem[]>([])

onMounted(async() => {
  tableData.value = await getFileList()
})
const tableLabel = ref({
    name: "技术类型",
    todayNew: "今日新增",
    needValue: "需求总数",
    paperValue: "总文献数",
})


</script>

<template>
    <el-row class="home" :gutter="20">
        <el-col :span="8" style="margin-top: 20px">
            <el-card shadow="hover" >
                <div class="user">
                    <img :src="getImageUrl('user')" class="user" />
                    <div class="user-info">
                        <p class="role">Admin</p>
                        <p>超级管理员</p>
                    </div>
                </div>
                <div class="login-info">
                    <p>上次登录时间：<span>2023-05-01 10:00:00</span></p>
                    <p>上次登录地点：<span>中国</span></p>
                </div>
            </el-card>
            <el-card class="paper-table"> 
                <el-table :data="tableData">
                    <el-table-column 
                        v-for="(val, key) in tableLabel"
                        :key="key"
                        :prop="key"
                        :label="val"
                    />
                </el-table>
            </el-card>
        </el-col> 
    </el-row>  
</template>

<style scoped lang="less">

    .home{
        height: 100%;
        overflow: hidden;
        .user{
            display: flex;
            align-items: center;
            border-bottom: 1px solid #ccc;
            margin-bottom: 20px;
            flex-wrap: wrap;  
            img{
                width: 150px;
                height: 150px;
                border-radius: 50%;
                margin-right:40px ;
            }
        }
        .login-info{
            p{
                display: flex;
                gap: 12px;
                line-height: 30px;
                font-size:14px;
                min-width: 0;   
                color: #999;
                span{
                    color:#666;
                }
            }
        }
        .role{
            font-size: 30px;
            font-weight: bold;
        }
        .paper-table{
            margin-top: 20px;
        }
    }
    
</style>
