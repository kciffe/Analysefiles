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

 Date: 15/04/2026 14:29:06
*/


-- ----------------------------
-- Table structure for labels
-- ----------------------------
DROP TABLE IF EXISTS "public"."labels";
CREATE TABLE "public"."labels" (
  "id" int8 NOT NULL GENERATED ALWAYS AS IDENTITY (
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1
),
  "top_label" varchar(128) COLLATE "pg_catalog"."default" NOT NULL,
  "sub_label" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "level" int8 NOT NULL
)
;
COMMENT ON COLUMN "public"."labels"."top_label" IS '主标签';
COMMENT ON COLUMN "public"."labels"."sub_label" IS '子标签';

-- ----------------------------
-- Uniques structure for table labels
-- ----------------------------
ALTER TABLE "public"."labels" ADD CONSTRAINT "unique_top_label" UNIQUE ("top_label");

-- ----------------------------
-- Primary Key structure for table labels
-- ----------------------------
ALTER TABLE "public"."labels" ADD CONSTRAINT "labels_pk" PRIMARY KEY ("id");
