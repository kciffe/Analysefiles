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

 Date: 15/04/2026 14:28:39
*/


-- ----------------------------
-- Table structure for file_metadata
-- ----------------------------
DROP TABLE IF EXISTS "public"."file_metadata";
CREATE TABLE "public"."file_metadata" (
  "id" int4 NOT NULL,
  "file_id" int4 NOT NULL,
  "source" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "title" varchar(256) COLLATE "pg_catalog"."default" NOT NULL,
  "authors" varchar(255) COLLATE "pg_catalog"."default",
  "institutions" varchar(255) COLLATE "pg_catalog"."default",
  "publish_year" timestamp(6),
  "publish_venue" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "keywords" jsonb DEFAULT '[]'::jsonb,
  "abstract" text COLLATE "pg_catalog"."default",
  "language" varchar(32) COLLATE "pg_catalog"."default",
  "created_time" timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "update_time" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Primary Key structure for table file_metadata
-- ----------------------------
ALTER TABLE "public"."file_metadata" ADD CONSTRAINT "file_metadata_pk" PRIMARY KEY ("id");
