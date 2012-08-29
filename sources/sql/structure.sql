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

DROP SCHEMA taf CASCADE;
CREATE SCHEMA taf;


SET search_path = taf, pg_catalog;

--
-- Name: after_insert_delete_active_task(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE OR REPLACE FUNCTION taf.after_insert_delete_active_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM taf.reorder_tasks();

  RETURN NEW;
END;
$$;

--
-- Name: before_insert_active_task(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE OR REPLACE FUNCTION before_insert_active_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- manage ranking if not provided 
    IF NEW.rank IS NULL THEN
         NEW.rank := max(t.rank) + 1 FROM taf.active_task t WHERE t.worker_id = NEW.worker_id;
    ELSE
        UPDATE taf.active_task t SET rank = rank + 1 WHERE t.rank >= NEW.rank AND t.worker_id = NEW.worker_id;
    END IF;

    -- generate slug if not provided
    IF NEW.slug IS NULL THEN
      NEW.slug := taf.slugify(NEW.title);
    END IF;

    RETURN NEW;
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
-- Name: reorder_tasks(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE OR REPLACE FUNCTION taf.reorder_tasks() RETURNS void
    LANGUAGE sql
    AS $$
  WITH
    order_task AS (
      SELECT
        id,
        row_number() OVER (PARTITION BY worker_id ORDER BY rank ASC) AS rank
      FROM
        taf.active_task
  )
  UPDATE taf.active_task t SET rank = ot.rank FROM order_task ot WHERE t.id = ot.id AND t.rank <> ot.rank;
$$;


--
-- Name: slugify(character varying); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE OR REPLACE FUNCTION slugify(character varying) RETURNS character varying
    LANGUAGE sql
    AS $_$
SELECT trim(both '-' from regexp_replace(lower(taf.transliterate($1)), '[^a-z0-9]+', '-', 'g'))||'-'||substring(md5(to_hex(extract(millisecond from now())::int4)||CAST(random() AS varchar)), 0, 4);
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


--
-- Name: update_rank_active_task(integer, integer); Type: FUNCTION; Schema: taf; Owner: -
--

-- $1 id of the active_task to move
-- $2 new rank to be set

CREATE OR REPLACE FUNCTION update_rank_active_task(integer, integer) RETURNS SETOF taf.active_task
    LANGUAGE sql
    AS $_$
    UPDATE 
        taf.active_task at 
    SET 
        rank = at.rank + ( (t.rank - $2) / abs(t.rank - $2) )
    FROM 
        taf.active_task t 
    WHERE 
            t.id = $1 
        AND 
            at.rank >= least($2, t.rank)
        AND 
            at.rank <= greatest($2, t.rank)
        AND
            at.worker_id = t.worker_id
            ;
    UPDATE taf.active_task SET rank = $2 WHERE id = $1 RETURNING *;
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

CREATE TRIGGER after_insert_delete_active_task_trig AFTER INSERT OR DELETE ON taf.active_task FOR EACH STATEMENT EXECUTE PROCEDURE taf.after_insert_delete_active_task();


--
-- Name: before_insert_task_trig; Type: TRIGGER; Schema: taf; Owner: -
--

CREATE TRIGGER before_insert_task_trig BEFORE INSERT ON taf.active_task FOR EACH ROW EXECUTE PROCEDURE taf.before_insert_active_task();


--
-- PostgreSQL database dump complete
--

