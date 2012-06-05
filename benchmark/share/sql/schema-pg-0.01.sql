--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: album; Type: TABLE; Schema: public; Owner: bokutin; Tablespace: 
--

CREATE TABLE album (
    id integer NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    artist_id integer NOT NULL,
    column1 text NOT NULL,
    column2 text NOT NULL,
    column3 text NOT NULL,
    column4 text NOT NULL,
    column5 text NOT NULL,
    column6 text NOT NULL,
    column7 text NOT NULL,
    column8 text NOT NULL,
    column9 text NOT NULL,
    column10 text NOT NULL,
    column11 text NOT NULL,
    column12 text NOT NULL,
    column13 text NOT NULL,
    column14 text NOT NULL,
    column15 text NOT NULL,
    column16 text NOT NULL,
    column17 text NOT NULL,
    column18 text NOT NULL,
    column19 text NOT NULL,
    column20 text NOT NULL
);


ALTER TABLE public.album OWNER TO bokutin;

--
-- Name: album_id_seq; Type: SEQUENCE; Schema: public; Owner: bokutin
--

CREATE SEQUENCE album_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.album_id_seq OWNER TO bokutin;

--
-- Name: album_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bokutin
--

ALTER SEQUENCE album_id_seq OWNED BY album.id;


--
-- Name: artist; Type: TABLE; Schema: public; Owner: bokutin; Tablespace: 
--

CREATE TABLE artist (
    id integer NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    column1 text NOT NULL,
    column2 text NOT NULL,
    column3 text NOT NULL,
    column4 text NOT NULL,
    column5 text NOT NULL,
    column6 text NOT NULL,
    column7 text NOT NULL,
    column8 text NOT NULL,
    column9 text NOT NULL,
    column10 text NOT NULL
);


ALTER TABLE public.artist OWNER TO bokutin;

--
-- Name: artist_id_seq; Type: SEQUENCE; Schema: public; Owner: bokutin
--

CREATE SEQUENCE artist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.artist_id_seq OWNER TO bokutin;

--
-- Name: artist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bokutin
--

ALTER SEQUENCE artist_id_seq OWNED BY artist.id;


--
-- Name: cover; Type: TABLE; Schema: public; Owner: bokutin; Tablespace: 
--

CREATE TABLE cover (
    id integer NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    album_id integer NOT NULL,
    column1 text NOT NULL,
    column2 text NOT NULL,
    column3 text NOT NULL,
    column4 text NOT NULL,
    column5 text NOT NULL
);


ALTER TABLE public.cover OWNER TO bokutin;

--
-- Name: cover_id_seq; Type: SEQUENCE; Schema: public; Owner: bokutin
--

CREATE SEQUENCE cover_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cover_id_seq OWNER TO bokutin;

--
-- Name: cover_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bokutin
--

ALTER SEQUENCE cover_id_seq OWNED BY cover.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: bokutin
--

ALTER TABLE album ALTER COLUMN id SET DEFAULT nextval('album_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: bokutin
--

ALTER TABLE artist ALTER COLUMN id SET DEFAULT nextval('artist_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: bokutin
--

ALTER TABLE cover ALTER COLUMN id SET DEFAULT nextval('cover_id_seq'::regclass);


--
-- Name: album_pkey; Type: CONSTRAINT; Schema: public; Owner: bokutin; Tablespace: 
--

ALTER TABLE ONLY album
    ADD CONSTRAINT album_pkey PRIMARY KEY (id);


--
-- Name: artist_pkey; Type: CONSTRAINT; Schema: public; Owner: bokutin; Tablespace: 
--

ALTER TABLE ONLY artist
    ADD CONSTRAINT artist_pkey PRIMARY KEY (id);


--
-- Name: cover_pkey; Type: CONSTRAINT; Schema: public; Owner: bokutin; Tablespace: 
--

ALTER TABLE ONLY cover
    ADD CONSTRAINT cover_pkey PRIMARY KEY (id);


--
-- Name: album_id; Type: INDEX; Schema: public; Owner: bokutin; Tablespace: 
--

CREATE UNIQUE INDEX album_id ON cover USING btree (album_id, name);


--
-- Name: artist_id; Type: INDEX; Schema: public; Owner: bokutin; Tablespace: 
--

CREATE INDEX artist_id ON album USING btree (artist_id, name);


--
-- Name: name; Type: INDEX; Schema: public; Owner: bokutin; Tablespace: 
--

CREATE UNIQUE INDEX name ON artist USING btree (name);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

