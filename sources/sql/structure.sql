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


--
-- Name: deploy(text, character); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION deploy(OUT changes text, _sql text, _md5 character) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
_DeployID integer;
_FunctionID oid;
_RemovedFunctionID oid;
_NewFunctionID oid;
_Schema text;
_FunctionName text;
_Diff text;
_ record;
_CountRemoved integer;
_CountNew integer;
_ReplacedFunctions integer[][];
BEGIN

    BEGIN

        RAISE DEBUG 'Creating FunctionsBefore';
        CREATE TEMP TABLE FunctionsBefore ON COMMIT DROP AS
        SELECT * FROM View_Functions;
        
        EXECUTE _SQL;
        
        RAISE DEBUG 'Creating FunctionsAfter';
        CREATE TEMP TABLE FunctionsAfter ON COMMIT DROP AS
        SELECT * FROM View_Functions;
        
        RAISE DEBUG 'Creating AllFunctions';
        CREATE TEMP TABLE AllFunctions ON COMMIT DROP AS
        SELECT FunctionID, Schema, Name FROM FunctionsAfter
        UNION
        SELECT FunctionID, Schema, Name FROM FunctionsBefore;
        
        RAISE DEBUG 'Creating NewFunctions';
        CREATE TEMP TABLE NewFunctions ON COMMIT DROP AS
        SELECT FunctionID FROM FunctionsAfter
        EXCEPT
        SELECT FunctionID FROM FunctionsBefore;
        
        RAISE DEBUG 'Creating RemovedFunctions';
        CREATE TEMP TABLE RemovedFunctions ON COMMIT DROP AS
        SELECT FunctionID FROM FunctionsBefore
        EXCEPT
        SELECT FunctionID FROM FunctionsAfter;
        
        RAISE DEBUG 'Creating ReplacedFunctions';
        CREATE TEMP TABLE ReplacedFunctions (
        RemovedFunctionID oid,
        NewFunctionID oid
        ) ON COMMIT DROP;
        
        FOR _ IN SELECT DISTINCT FunctionsAfter.Schema, FunctionsAfter.Name
        FROM RemovedFunctions, NewFunctions, FunctionsBefore, FunctionsAfter
        WHERE FunctionsBefore.FunctionID  = RemovedFunctions.FunctionID
        AND   FunctionsAfter.FunctionID   = NewFunctions.FunctionID
        AND   FunctionsBefore.Schema      = FunctionsAfter.Schema
        AND   FunctionsBefore.Name        = FunctionsAfter.Name
        LOOP
            SELECT COUNT(*) INTO _CountRemoved FROM RemovedFunctions
            INNER JOIN FunctionsBefore USING (FunctionID)
            WHERE FunctionsBefore.Schema = _.Schema AND FunctionsBefore.Name = _.Name;
        
            SELECT COUNT(*) INTO _CountNew FROM NewFunctions
            INNER JOIN FunctionsAfter USING (FunctionID)
            WHERE FunctionsAfter.Schema = _.Schema AND FunctionsAfter.Name = _.Name;
        
            IF _CountRemoved = 1 AND _CountNew = 1 THEN
                -- Exactly one function removed with identical name as a new function
        
                SELECT RemovedFunctions.FunctionID INTO STRICT _RemovedFunctionID FROM RemovedFunctions
                INNER JOIN FunctionsBefore USING (FunctionID)
                WHERE FunctionsBefore.Schema = _.Schema AND FunctionsBefore.Name = _.Name;
        
                SELECT NewFunctions.FunctionID INTO STRICT _NewFunctionID FROM NewFunctions
                INNER JOIN FunctionsAfter USING (FunctionID)
                WHERE FunctionsAfter.Schema = _.Schema AND FunctionsAfter.Name = _.Name;
        
                INSERT INTO ReplacedFunctions (RemovedFunctionID,NewFunctionID) VALUES (_RemovedFunctionID,_NewFunctionID);
            END IF;
        END LOOP;
        
        RAISE DEBUG 'Deleting ReplacedFunctions from RemovedFunctions';
        DELETE FROM RemovedFunctions WHERE FunctionID IN (SELECT RemovedFunctionID FROM ReplacedFunctions);
        
        RAISE DEBUG 'Deleting ReplacedFunctions from NewFunctions';
        DELETE FROM NewFunctions     WHERE FunctionID IN (SELECT NewFunctionID     FROM ReplacedFunctions);
        
        RAISE DEBUG 'Creating ChangedFunctions';
        
        CREATE TEMP TABLE ChangedFunctions ON COMMIT DROP AS
        SELECT AllFunctions.FunctionID FROM AllFunctions
        INNER JOIN FunctionsBefore ON (FunctionsBefore.FunctionID = AllFunctions.FunctionID)
        INNER JOIN FunctionsAfter  ON (FunctionsAfter.FunctionID  = AllFunctions.FunctionID)
        WHERE FunctionsBefore.Schema         <> FunctionsAfter.Schema
        OR FunctionsBefore.Name              <> FunctionsAfter.Name
        OR FunctionsBefore.ResultDataType    <> FunctionsAfter.ResultDataType
        OR FunctionsBefore.ArgumentDataTypes <> FunctionsAfter.ArgumentDataTypes
        OR FunctionsBefore.Type              <> FunctionsAfter.Type
        OR FunctionsBefore.Volatility        <> FunctionsAfter.Volatility
        OR FunctionsBefore.Owner             <> FunctionsAfter.Owner
        OR FunctionsBefore.Language          <> FunctionsAfter.Language
        OR FunctionsBefore.Sourcecode        <> FunctionsAfter.Sourcecode
        ;
        
        Changes := '';
        
        RAISE DEBUG 'Removed functions...';
        
        Changes := Changes || '+-------------------+' || E'\n';
        Changes := Changes || '| Removed functions |' || E'\n';
        Changes := Changes || '+-------------------+' || E'\n\n';
        
        FOR _ IN
        SELECT
            RemovedFunctions.FunctionID,
            FunctionsBefore.Schema                                     AS SchemaBefore,
            FunctionsBefore.Name                                       AS NameBefore,
            FunctionsBefore.ArgumentDataTypes                          AS ArgumentDataTypesBefore,
            FunctionsBefore.ResultDataType                             AS ResultDataTypeBefore,
            FunctionsBefore.Language                                   AS LanguageBefore,
            FunctionsBefore.Type                                       AS TypeBefore,
            FunctionsBefore.Volatility                                 AS VolatilityBefore,
            FunctionsBefore.Owner                                      AS OwnerBefore,
            length(FunctionsBefore.Sourcecode)                         AS SourcecodeLength
        FROM RemovedFunctions
        INNER JOIN FunctionsBefore USING (FunctionID)
        ORDER BY 2,3,4,5,6,7,8,9,10
        LOOP
            Changes := Changes || 'Schema................- ' || _.SchemaBefore || E'\n';
            Changes := Changes || 'Name..................- ' || _.NameBefore || E'\n';
            Changes := Changes || 'Argument data types...- ' || _.ArgumentDataTypesBefore || E'\n';
            Changes := Changes || 'Result data type......- ' || _.ResultDataTypeBefore || E'\n';
            Changes := Changes || 'Language..............- ' || _.LanguageBefore || E'\n';
            Changes := Changes || 'Type..................- ' || _.TypeBefore || E'\n';
            Changes := Changes || 'Volatility............- ' || _.VolatilityBefore || E'\n';
            Changes := Changes || 'Owner.................- ' || _.OwnerBefore || E'\n';
            Changes := Changes || 'Source code (chars)...- ' || _.SourcecodeLength || E'\n';
        END LOOP;
        Changes := Changes || E'\n\n';
        
        RAISE DEBUG 'New functions...';
        
        Changes := Changes || '+---------------+' || E'\n';
        Changes := Changes || '| New functions |' || E'\n';
        Changes := Changes || '+---------------+' || E'\n\n';
        
        FOR _ IN
        SELECT
            NewFunctions.FunctionID,
            FunctionsAfter.Schema                                     AS SchemaAfter,
            FunctionsAfter.Name                                       AS NameAfter,
            FunctionsAfter.ArgumentDataTypes                          AS ArgumentDataTypesAfter,
            FunctionsAfter.ResultDataType                             AS ResultDataTypeAfter,
            FunctionsAfter.Language                                   AS LanguageAfter,
            FunctionsAfter.Type                                       AS TypeAfter,
            FunctionsAfter.Volatility                                 AS VolatilityAfter,
            FunctionsAfter.Owner                                      AS OwnerAfter,
            length(FunctionsAfter.Sourcecode)                         AS SourcecodeLength
        FROM NewFunctions
        INNER JOIN FunctionsAfter USING (FunctionID)
        ORDER BY 2,3,4,5,6,7,8,9,10
        LOOP
            Changes := Changes || 'Schema................+ ' || _.SchemaAfter || E'\n';
            Changes := Changes || 'Name..................+ ' || _.NameAfter || E'\n';
            Changes := Changes || 'Argument data types...+ ' || _.ArgumentDataTypesAfter || E'\n';
            Changes := Changes || 'Result data type......+ ' || _.ResultDataTypeAfter || E'\n';
            Changes := Changes || 'Language..............+ ' || _.LanguageAfter || E'\n';
            Changes := Changes || 'Type..................+ ' || _.TypeAfter || E'\n';
            Changes := Changes || 'Volatility............+ ' || _.VolatilityAfter || E'\n';
            Changes := Changes || 'Owner.................+ ' || _.OwnerAfter || E'\n';
            Changes := Changes || 'Source code (chars)...+ ' || _.SourcecodeLength || E'\n';
        END LOOP;
        Changes := Changes || E'\n\n';
        
        RAISE DEBUG 'Updated or replaced functions...';
        
        Changes := Changes || '+-------------------------------+' || E'\n';
        Changes := Changes || '| Updated or replaced functions |' || E'\n';
        Changes := Changes || '+-------------------------------+' || E'\n\n';
        
        FOR _ IN
        SELECT
            ChangedFunctions.FunctionID,
            FunctionsBefore.Schema                                     AS SchemaBefore,
            FunctionsBefore.Name                                       AS NameBefore,
            FunctionsBefore.ArgumentDataTypes                          AS ArgumentDataTypesBefore,
            FunctionsBefore.ResultDataType                             AS ResultDataTypeBefore,
            FunctionsBefore.Language                                   AS LanguageBefore,
            FunctionsBefore.Type                                       AS TypeBefore,
            FunctionsBefore.Volatility                                 AS VolatilityBefore,
            FunctionsBefore.Owner                                      AS OwnerBefore,
            FunctionsAfter.Schema                                      AS SchemaAfter,
            FunctionsAfter.Name                                        AS NameAfter,
            FunctionsAfter.ArgumentDataTypes                           AS ArgumentDataTypesAfter,
            FunctionsAfter.ResultDataType                              AS ResultDataTypeAfter,
            FunctionsAfter.Language                                    AS LanguageAfter,
            FunctionsAfter.Type                                        AS TypeAfter,
            FunctionsAfter.Volatility                                  AS VolatilityAfter,
            FunctionsAfter.Owner                                       AS OwnerAfter,
            Diff(FunctionsBefore.Sourcecode,FunctionsAfter.Sourcecode) AS Diff
        FROM ChangedFunctions
        INNER JOIN FunctionsBefore ON (FunctionsBefore.FunctionID = ChangedFunctions.FunctionID)
        INNER JOIN FunctionsAfter  ON (FunctionsAfter.FunctionID  = ChangedFunctions.FunctionID)
        UNION ALL
        SELECT
            FunctionsAfter.FunctionID,
            FunctionsBefore.Schema                                     AS SchemaBefore,
            FunctionsBefore.Name                                       AS NameBefore,
            FunctionsBefore.ArgumentDataTypes                          AS ArgumentDataTypesBefore,
            FunctionsBefore.ResultDataType                             AS ResultDataTypeBefore,
            FunctionsBefore.Language                                   AS LanguageBefore,
            FunctionsBefore.Type                                       AS TypeBefore,
            FunctionsBefore.Volatility                                 AS VolatilityBefore,
            FunctionsBefore.Owner                                      AS OwnerBefore,
            FunctionsAfter.Schema                                      AS SchemaAfter,
            FunctionsAfter.Name                                        AS NameAfter,
            FunctionsAfter.ArgumentDataTypes                           AS ArgumentDataTypesAfter,
            FunctionsAfter.ResultDataType                              AS ResultDataTypeAfter,
            FunctionsAfter.Language                                    AS LanguageAfter,
            FunctionsAfter.Type                                        AS TypeAfter,
            FunctionsAfter.Volatility                                  AS VolatilityAfter,
            FunctionsAfter.Owner                                       AS OwnerAfter,
            Diff(FunctionsBefore.Sourcecode,FunctionsAfter.Sourcecode) AS Diff
        FROM ReplacedFunctions
        INNER JOIN FunctionsBefore ON (FunctionsBefore.FunctionID = ReplacedFunctions.RemovedFunctionID)
        INNER JOIN FunctionsAfter  ON (FunctionsAfter.FunctionID  = ReplacedFunctions.NewFunctionID)
        ORDER BY 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
        LOOP
            IF _.SchemaBefore = _.SchemaAfter THEN
                Changes := Changes || 'Schema................: ' || _.SchemaAfter || E'\n';
            ELSE
                Changes := Changes || 'Schema................- ' || _.SchemaBefore || E'\n';
                Changes := Changes || 'Schema................+ ' || _.SchemaAfter || E'\n';
            END IF;
        
            IF _.NameBefore = _.NameAfter THEN
                Changes := Changes || 'Name..................: ' || _.NameAfter || E'\n';
            ELSE
                Changes := Changes || 'Name..................- ' || _.NameBefore || E'\n';
                Changes := Changes || 'Name..................+ ' || _.NameAfter || E'\n';
            END IF;
        
            IF _.ArgumentDataTypesBefore = _.ArgumentDataTypesAfter THEN
                Changes := Changes || 'Argument data types...: ' || _.ArgumentDataTypesAfter || E'\n';
            ELSE
                Changes := Changes || 'Argument data types...- ' || _.ArgumentDataTypesBefore || E'\n';
                Changes := Changes || 'Argument data types...+ ' || _.ArgumentDataTypesAfter || E'\n';
            END IF;
        
            IF _.ResultDataTypeBefore = _.ResultDataTypeAfter THEN
                Changes := Changes || 'Result data type......: ' || _.ResultDataTypeAfter || E'\n';
            ELSE
                Changes := Changes || 'Result data type......- ' || _.ResultDataTypeBefore || E'\n';
                Changes := Changes || 'Result data type......+ ' || _.ResultDataTypeAfter || E'\n';
            END IF;
        
            IF _.LanguageBefore = _.LanguageAfter THEN
                Changes := Changes || 'Language..............: ' || _.LanguageAfter || E'\n';
            ELSE
                Changes := Changes || 'Language..............- ' || _.LanguageBefore || E'\n';
                Changes := Changes || 'Language..............+ ' || _.LanguageAfter || E'\n';
            END IF;
        
            IF _.TypeBefore = _.TypeAfter THEN
                Changes := Changes || 'Type..................: ' || _.TypeAfter || E'\n';
            ELSE
                Changes := Changes || 'Type..................- ' || _.TypeBefore || E'\n';
                Changes := Changes || 'Type..................+ ' || _.TypeAfter || E'\n';
            END IF;
        
            IF _.VolatilityBefore = _.VolatilityAfter THEN
                Changes := Changes || 'Volatility............: ' || _.VolatilityAfter || E'\n';
            ELSE
                Changes := Changes || 'Volatility............- ' || _.VolatilityBefore || E'\n';
                Changes := Changes || 'Volatility............+ ' || _.VolatilityAfter || E'\n';
            END IF;
        
            IF _.OwnerBefore = _.OwnerAfter THEN
                Changes := Changes || 'Owner.................: ' || _.OwnerAfter || E'\n';
            ELSE
                Changes := Changes || 'Owner.................- ' || _.OwnerBefore || E'\n';
                Changes := Changes || 'Owner.................+ ' || _.OwnerAfter || E'\n';
            END IF;
        
            Changes := Changes || _.Diff || E'\n\n';
        END LOOP;
        
        IF _MD5 IS NULL THEN
            -- We are testing, raise exception to rollback changes
            RAISE EXCEPTION 'OK';
        ELSIF md5(Changes) = _MD5 THEN
            -- Hash matches, proceed, keep changes
        ELSE
            RAISE EXCEPTION 'ERROR_INVALID_MD5 Invalid MD5, % <> %', md5(Changes), _MD5;
        END IF;

    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM <> 'OK' THEN
            RAISE EXCEPTION '%', SQLERRM;
        END IF;
    END;

    IF _MD5 IS NOT NULL THEN
        INSERT INTO Deploys (SQL,MD5,Diff) VALUES (_SQL,_MD5,Changes) RETURNING DeployID INTO STRICT _DeployID;
    END IF;

    Changes := Changes || 'MD5 of changes: ' || md5(Changes);

RETURN;
END;
$$;


--
-- Name: diff(text, text); Type: FUNCTION; Schema: taf; Owner: -
--

CREATE FUNCTION diff(_original text, _new text) RETURNS text
    LANGUAGE plperlu
    AS $_X$
use Algorithm::Diff;
my $in = {};
@{$in->{old}} = split "\n", $_[0];
@{$in->{new}} = split "\n", $_[1];
my @diff = Algorithm::Diff::sdiff($in->{old},$in->{new});
my $str;
my $line_num = 0;
for my $d (@diff) {
    $line_num++;
    next if $d->[0] eq 'u';
    $str .= $line_num . ' ' . $d->[0] . ' ' . $d->[1] . "\n";
    $str .= $line_num . ' ' . $d->[0] . ' ' . $d->[2] . "\n";
    $str .= "\n";
}
return $str;
$_X$;


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
-- Name: view_functions; Type: VIEW; Schema: taf; Owner: -
--

CREATE VIEW view_functions AS
    SELECT p.oid AS functionid, n.nspname AS schema, p.proname AS name, pg_get_function_result(p.oid) AS resultdatatype, pg_get_function_arguments(p.oid) AS argumentdatatypes, CASE WHEN p.proisagg THEN 'agg'::text WHEN p.proiswindow THEN 'window'::text WHEN (p.prorettype = ('trigger'::regtype)::oid) THEN 'trigger'::text ELSE 'normal'::text END AS type, CASE WHEN (p.provolatile = 'i'::"char") THEN 'IMMUTABLE'::text WHEN (p.provolatile = 's'::"char") THEN 'STABLE'::text WHEN (p.provolatile = 'v'::"char") THEN 'VOLATILE'::text ELSE NULL::text END AS volatility, pg_get_userbyid(p.proowner) AS owner, l.lanname AS language, p.prosrc AS sourcecode FROM ((pg_proc p LEFT JOIN pg_namespace n ON ((n.oid = p.pronamespace))) LEFT JOIN pg_language l ON ((l.oid = p.prolang))) WHERE ((pg_function_is_visible(p.oid) AND (n.nspname <> 'pg_catalog'::name)) AND (n.nspname <> 'information_schema'::name)) ORDER BY p.oid;


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
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    session_token character(32),
    session_start timestamp without time zone
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

