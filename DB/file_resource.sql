/*
 Navicat Premium Dump SQL

 Source Server         : deep_research
 Source Server Type    : PostgreSQL
 Source Server Version : 180001 (180001)
 Source Host           : localhost:5432
 Source Catalog        : deep_research
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 180001 (180001)
 File Encoding         : 65001

 Date: 15/04/2026 14:42:29
*/


-- ----------------------------
-- Table structure for file_resource
-- ----------------------------
DROP TABLE IF EXISTS "public"."file_resource";
CREATE TABLE "public"."file_resource" (
  "id" int4 NOT NULL,
  "path" varchar(256) COLLATE "pg_catalog"."default" NOT NULL,
  "name" varchar(128) COLLATE "pg_catalog"."default" NOT NULL,
  "type" varchar(16) COLLATE "pg_catalog"."default",
  "source" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "created_time" timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
)
;

-- ----------------------------
-- Records of file_resource
-- ----------------------------
INSERT INTO "public"."file_resource" VALUES (1, 'D:\8\Desktop\papers\MinerU_markdown_ReAct_2033118043273228288.md', 'MinerU_markdown_ReAct_2033118043273228288.md', 'arxiv', 'upload', '2026-03-15 20:06:52.0308');
INSERT INTO "public"."file_resource" VALUES (2, 'D:\8\Desktop\papers\MinerU_markdown_deepresearch_2033117939149627392.md', 'MinerU_markdown_deepresearch_2033117939149627392.md', 'arxiv', 'upload', '2026-03-15 20:06:52.0308');
INSERT INTO "public"."file_resource" VALUES (4, 'D:\8\Desktop\papers\MinerU_markdown_DeepResearcher_2_1_2033116461311782912.md', 'MinerU_markdown_DeepResearcher_2_1_2033116461311782912.md', 'arxiv', 'upload', '2026-03-15 20:06:52.0308');
INSERT INTO "public"."file_resource" VALUES (3, 'D:\8\Desktop\papers\MinerU_markdown_DeepResearch_Arena_1_3_2033118066316726272.md', 'MinerU_markdown_DeepResearch_Arena_1_3_2033118066316726272.md', 'arxiv', 'upload', '2026-03-15 20:06:52.0308');
INSERT INTO "public"."file_resource" VALUES (5, 'D:\8\Desktop\papers\MinerU_markdown_A_Survey_on_RAG_Meeting_LLMs_0_1_2033117711134674944.md', 'MinerU_markdown_A_Survey_on_RAG_Meeting_LLMs_0_1_2033117711134674944.md', 'arxiv', 'upload', '2026-03-15 20:06:52.0308');

-- ----------------------------
-- Primary Key structure for table file_resource
-- ----------------------------
ALTER TABLE "public"."file_resource" ADD CONSTRAINT "file_resource_pk" PRIMARY KEY ("id");
