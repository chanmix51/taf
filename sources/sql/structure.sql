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
-- Name: email_address; Type: DOMAIN; Schema: taf; Owner: -
--

CREATE DOMAIN email_address AS character varying
	CONSTRAINT email_address_check CHECK (((VALUE)::text ~* '^([^@\s]+)@((?:[a-z0-9-]+\.)+[a-z]{2,})$'::text));


--
-- Name: after_insert_delete_active_task(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION after_insert_delete_active_task() RETURNS trigger
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

CREATE FUNCTION before_insert_active_task() RETURNS trigger
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
-- Name: task; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE task (
    task_id integer NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    work_time integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    worker_id integer NOT NULL,
    block_stack json DEFAULT '{"blocks": []}'::json NOT NULL
);


--
-- Name: is_member_of(task); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION is_member_of(task) RETURNS character varying
    LANGUAGE sql
    AS $_$
SELECT pg_class.relname FROM pg_class WHERE $1.tableoid = pg_class.oid;
$_$;


--
-- Name: reorder_tasks(); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION reorder_tasks() RETURNS void
    LANGUAGE sql
    AS $$
  WITH
    order_task AS (
      SELECT
        task_id,
        row_number() OVER (PARTITION BY worker_id ORDER BY rank ASC) AS rank
      FROM
        taf.active_task
  )
  UPDATE taf.active_task t SET rank = ot.rank FROM order_task ot WHERE t.task_id = ot.task_id AND t.rank <> ot.rank;
$$;


--
-- Name: slugify(character varying); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION slugify(character varying) RETURNS character varying
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
-- Name: active_task; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE active_task (
    rank integer NOT NULL,
    active_at timestamp without time zone DEFAULT now() NOT NULL
)
INHERITS (task);


--
-- Name: update_rank_active_task(integer, integer); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION update_rank_active_task(integer, integer) RETURNS SETOF active_task
    LANGUAGE sql
    AS $_$
    UPDATE
        taf.active_task at
    SET
        rank = CASE
            WHEN t.rank - $2 <> 0 THEN at.rank + ( (t.rank - $2) / abs(t.rank - $2) )
            ELSE at.rank
        END 
    FROM
        taf.active_task t
    WHERE
            t.task_id = $1
        AND
            at.rank >= least($2, t.rank)
        AND
            at.rank <= greatest($2, t.rank)
        AND
            at.worker_id = t.worker_id
            ;
    UPDATE taf.active_task SET rank = $2 WHERE task_id = $1 RETURNING *;
$_$;


--
-- Name: finished_task; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE finished_task (
    changed_at timestamp without time zone DEFAULT now() NOT NULL
)
INHERITS (task);


--
-- Name: suspended_task; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE suspended_task (
    changed_at timestamp without time zone DEFAULT now() NOT NULL
)
INHERITS (task);


--
-- Name: task_id_seq; Type: SEQUENCE; Schema: taf; Owner: -
--

CREATE SEQUENCE task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: task_id_seq; Type: SEQUENCE OWNED BY; Schema: taf; Owner: -
--

ALTER SEQUENCE task_id_seq OWNED BY task.task_id;


--
-- Name: task_lnk; Type: VIEW; Schema: taf; Owner: -
--

CREATE VIEW task_lnk AS
    SELECT task.task_id, task.worker_id, task.slug, pg_class.relname FROM (task JOIN pg_class ON ((task.tableoid = pg_class.oid)));


--
-- Name: worker_id_seq; Type: SEQUENCE; Schema: taf; Owner: -
--

CREATE SEQUENCE worker_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker; Type: TABLE; Schema: taf; Owner: -; Tablespace: 
--

CREATE TABLE worker (
    worker_id integer DEFAULT nextval('worker_id_seq'::regclass) NOT NULL,
    email email_address NOT NULL,
    extra_data hstore
);


--
-- Name: task_id; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY active_task ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq'::regclass);


--
-- Name: work_time; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY active_task ALTER COLUMN work_time SET DEFAULT 0;


--
-- Name: created_at; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY active_task ALTER COLUMN created_at SET DEFAULT now();


--
-- Name: block_stack; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY active_task ALTER COLUMN block_stack SET DEFAULT '{"blocks": []}'::json;


--
-- Name: task_id; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY finished_task ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq'::regclass);


--
-- Name: work_time; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY finished_task ALTER COLUMN work_time SET DEFAULT 0;


--
-- Name: created_at; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY finished_task ALTER COLUMN created_at SET DEFAULT now();


--
-- Name: block_stack; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY finished_task ALTER COLUMN block_stack SET DEFAULT '{"blocks": []}'::json;


--
-- Name: task_id; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY suspended_task ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq'::regclass);


--
-- Name: work_time; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY suspended_task ALTER COLUMN work_time SET DEFAULT 0;


--
-- Name: created_at; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY suspended_task ALTER COLUMN created_at SET DEFAULT now();


--
-- Name: block_stack; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY suspended_task ALTER COLUMN block_stack SET DEFAULT '{"blocks": []}'::json;


--
-- Name: task_id; Type: DEFAULT; Schema: taf; Owner: -
--

ALTER TABLE ONLY task ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq'::regclass);


--
-- Name: active_task_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_task
    ADD CONSTRAINT active_task_pkey PRIMARY KEY (task_id);


--
-- Name: finished_task_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY finished_task
    ADD CONSTRAINT finished_task_pkey PRIMARY KEY (task_id);


--
-- Name: suspended_task_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY suspended_task
    ADD CONSTRAINT suspended_task_pkey PRIMARY KEY (task_id);


--
-- Name: task_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_pkey PRIMARY KEY (task_id);


--
-- Name: task_slug_key; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_slug_key UNIQUE (slug);


--
-- Name: worker_pkey; Type: CONSTRAINT; Schema: taf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY worker
    ADD CONSTRAINT worker_pkey PRIMARY KEY (worker_id);


--
-- Name: after_insert_delete_active_task_trig; Type: TRIGGER; Schema: taf; Owner: -
--

CREATE TRIGGER after_insert_delete_active_task_trig AFTER INSERT OR DELETE ON active_task FOR EACH STATEMENT EXECUTE PROCEDURE after_insert_delete_active_task();


--
-- Name: before_insert_active_task_trig; Type: TRIGGER; Schema: taf; Owner: -
--

CREATE TRIGGER before_insert_active_task_trig BEFORE INSERT ON active_task FOR EACH ROW EXECUTE PROCEDURE before_insert_active_task();


--
-- Name: task_worker_id_fkey; Type: FK CONSTRAINT; Schema: taf; Owner: -
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES worker(worker_id);


--
-- PostgreSQL database dump complete
--

