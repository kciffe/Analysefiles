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

 Date: 15/04/2026 14:28:23
*/


-- ----------------------------
-- Table structure for doc_parsed
-- ----------------------------
DROP TABLE IF EXISTS "public"."doc_parsed";
CREATE TABLE "public"."doc_parsed" (
  "id" int4 NOT NULL,
  "doc_id" int4 NOT NULL,
  "full_text" text COLLATE "pg_catalog"."default" NOT NULL,
  "structure_info" jsonb NOT NULL,
  "parse_time" timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" varchar(32) COLLATE "pg_catalog"."default" NOT NULL,
  "error_info" text COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Primary Key structure for table doc_parsed
-- ----------------------------
ALTER TABLE "public"."doc_parsed" ADD CONSTRAINT "doc_parsed_pk" PRIMARY KEY ("id");
