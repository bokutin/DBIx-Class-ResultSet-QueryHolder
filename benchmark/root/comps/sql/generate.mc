DROP TABLE IF EXISTS "artist";
DROP TABLE IF EXISTS "album";
DROP TABLE IF EXISTS "cover";

CREATE TABLE "artist" (
  "id" serial NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
% for (1..10) {
  "column<% $_ %>" text NOT NULL,
% }
  PRIMARY KEY ("id")
);

CREATE TABLE "album" (
  "id" serial NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "artist_id" integer NOT NULL,
% for (1..20) {
  "column<% $_ %>" text NOT NULL,
% }
  PRIMARY KEY ("id")
);

CREATE TABLE "cover" (
  "id" serial NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "album_id" integer NOT NULL,
% for (1..5) {
  "column<% $_ %>" text NOT NULL,
% }
  PRIMARY KEY ("id")
);
