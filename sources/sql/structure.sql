--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: taf; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA taf;


SET search_path = taf, pg_catalog;

--
-- Name: after_insert_delete_active_task(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION after_insert_delete_active_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  WITH
    order_task AS (
      SELECT
        id,
        row_number() OVER (ORDER BY rank ASC) AS rank,
        title,
        slug,
        work_time
      FROM
        active_task
  )
  UPDATE active_task t SET rank = ot.rank FROM order_task ot WHERE t.id = ot.id;

  RETURN NEW;
END;
$$;


--
-- Name: after_insert_task(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION after_insert_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  WITH
    order_task AS (
      SELECT
        id,
        row_number() OVER (ORDER BY rank ASC) AS rank,
        title,
        slug,
        finished_at,
        suspended_at,
        work_time
      FROM
        task
  )
  UPDATE task t SET rank = ot.rank FROM order_task ot WHERE t.id = ot.id;

  RETURN NEW;
END;
$$;


--
-- Name: before_insert_task(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION before_insert_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.slug IS NULL THEN
    NEW.slug := slugify(NEW.title);
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: slugify(character varying); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION slugify(character varying) RETURNS character varying
    LANGUAGE sql
    AS $_$
SELECT substring(md5(to_hex(extract(millisecond from now())::int4)||CAST(random() AS varchar)), 0, 4)||'-'||trim(both '-' from regexp_replace(lower(transliterate($1)), '[^a-z0-9]+', '-', 'g'));
$_$;


--
-- Name: transliterate(character varying); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION transliterate(my_text character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE 
      text_out VARCHAR DEFAULT '';
    BEGIN
           text_out := my_text;
           text_out := translate(text_out, 'àâäåáăąãāçċćčĉéèėëêēĕîïìíīñôöøõōùúüûūýÿỳ', 'aaaaaaaaaccccceeeeeeeiiiiinooooouuuuuyyy');
           text_out := translate(text_out, 'ÀÂÄÅÁĂĄÃĀÇĊĆČĈÉÈĖËÊĒĔÎÏÌÍĪÑÔÖØÕŌÙÚÜÛŪÝŸỲ', 'AAAAAAAAACCCCCEEEEEEEIIIIINOOOOOUUUUUYYY');
           text_out := replace(text_out, 'æ', 'ae');
           text_out := replace(text_out, 'Œ', 'OE');
           text_out := replace(text_out, 'Æ', 'AE');
           text_out := replace(text_out, 'ß', 'ss');
           text_out := replace(text_out, 'œ', 'oe');

           RETURN text_out;
    END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: active_task; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE active_task (
    id integer NOT NULL,
    rank integer,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    work_time integer DEFAULT 0 NOT NULL
);


--
-- Name: update_rank_active_task(integer, integer); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION update_rank_active_task(integer, integer) RETURNS SETOF active_task
    LANGUAGE sql
    AS $_$
UPDATE active_task at SET rank = at.rank + 1 FROM active_task t WHERE at.rank >= $2 AND t.id = $1 AND at.rank < t.rank;
UPDATE active_task SET rank = $2 WHERE id = $1 RETURNING *;
$_$;


--
-- Name: active_task_id_seq; Type: SEQUENCE; Schema: taf; Owner: -
--

CREATE SEQUENCE active_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_task_id_seq; Type: SEQUENCE OWNED BY; Schema: taf; Owner: -
--

ALTER SEQUENCE active_task_id_seq OWNED BY active_task.id;


--
-- Name: finished_task; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE finished_task (
    id integer NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    work_time integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: suspended_task; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE suspended_task (
    id integer NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    work_time integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: id; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY active_task ALTER COLUMN id SET DEFAULT nextval('active_task_id_seq'::regclass);


--
-- Name: active_task_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_task
    ADD CONSTRAINT active_task_pkey PRIMARY KEY (id);


--
-- Name: finished_task_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY finished_task
    ADD CONSTRAINT finished_task_pkey PRIMARY KEY (id);


--
-- Name: suspended_task_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY suspended_task
    ADD CONSTRAINT suspended_task_pkey PRIMARY KEY (id);


--
-- Name: after_insert_delete_active_task_trig; Type: TRIGGER; Schema: taf; Owner: -
--

CREATE TRIGGER after_insert_delete_active_task_trig AFTER INSERT OR DELETE ON active_task FOR EACH STATEMENT EXECUTE PROCEDURE after_insert_delete_active_task();


--
-- Name: before_insert_task_trig; Type: TRIGGER; Schema: taf; Owner: -
--

CREATE TRIGGER before_insert_task_trig BEFORE INSERT ON active_task FOR EACH ROW EXECUTE PROCEDURE before_insert_task();


--
-- PostgreSQL database dump complete
--

