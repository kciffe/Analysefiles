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

 Date: 15/04/2026 14:28:50
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
-- Primary Key structure for table file_resource
-- ----------------------------
ALTER TABLE "public"."file_resource" ADD CONSTRAINT "file_resource_pk" PRIMARY KEY ("id");
