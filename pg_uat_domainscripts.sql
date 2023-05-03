CREATE DOMAIN public.udd_amount AS numeric(18,2) NOT NULL DEFAULT 0;


ALTER DOMAIN public.udd_amount OWNER TO postgres;

--
-- TOC entry 1418 (class 1247 OID 16393)
-- Name: udd_amount4d; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_amount4d AS numeric(18,4) NOT NULL DEFAULT 0;


ALTER DOMAIN public.udd_amount4d OWNER TO postgres;

--
-- TOC entry 1421 (class 1247 OID 16395)
-- Name: udd_bigint; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_bigint AS bigint;


ALTER DOMAIN public.udd_bigint OWNER TO postgres;

--
-- TOC entry 1424 (class 1247 OID 16397)
-- Name: udd_boolean; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_boolean AS boolean;


ALTER DOMAIN public.udd_boolean OWNER TO postgres;

--
-- TOC entry 1427 (class 1247 OID 16399)
-- Name: udd_code; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_code AS character varying(32) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_code OWNER TO postgres;

--
-- TOC entry 1430 (class 1247 OID 16401)
-- Name: udd_date; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_date AS date;


ALTER DOMAIN public.udd_date OWNER TO postgres;

--
-- TOC entry 1433 (class 1247 OID 16403)
-- Name: udd_datetime; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_datetime AS timestamp without time zone;


ALTER DOMAIN public.udd_datetime OWNER TO postgres;

--
-- TOC entry 1436 (class 1247 OID 16405)
-- Name: udd_datetimenow; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_datetimenow AS timestamp without time zone NOT NULL DEFAULT now();


ALTER DOMAIN public.udd_datetimenow OWNER TO postgres;

--
-- TOC entry 1440 (class 1247 OID 16407)
-- Name: udd_desc; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_desc AS character varying(1024) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_desc OWNER TO postgres;

--
-- TOC entry 1448 (class 1247 OID 16409)
-- Name: udd_email; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_email AS text COLLATE public.case_insensitive;


ALTER DOMAIN public.udd_email OWNER TO postgres;

--
-- TOC entry 1451 (class 1247 OID 16411)
-- Name: udd_file; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_file AS bytea;


ALTER DOMAIN public.udd_file OWNER TO postgres;

--
-- TOC entry 1454 (class 1247 OID 16413)
-- Name: udd_flag; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_flag AS character varying(16) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_flag OWNER TO postgres;

--
-- TOC entry 1457 (class 1247 OID 16415)
-- Name: udd_int; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_int AS integer;


ALTER DOMAIN public.udd_int OWNER TO postgres;

--
-- TOC entry 1460 (class 1247 OID 16417)
-- Name: udd_json; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_json AS json;


ALTER DOMAIN public.udd_json OWNER TO postgres;

--
-- TOC entry 1463 (class 1247 OID 16419)
-- Name: udd_jsonb; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_jsonb AS jsonb;


ALTER DOMAIN public.udd_jsonb OWNER TO postgres;

--
-- TOC entry 1466 (class 1247 OID 16421)
-- Name: udd_mobile; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_mobile AS character varying(10) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_mobile OWNER TO postgres;

--
-- TOC entry 1469 (class 1247 OID 16423)
-- Name: udd_numeric; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_numeric AS numeric(18,0) NOT NULL DEFAULT 0;


ALTER DOMAIN public.udd_numeric OWNER TO postgres;

--
-- TOC entry 1472 (class 1247 OID 16425)
-- Name: udd_pincode; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_pincode AS character varying(6) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_pincode OWNER TO postgres;

--
-- TOC entry 1475 (class 1247 OID 16427)
-- Name: udd_qty; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_qty AS numeric(10,4) NOT NULL DEFAULT 0;


ALTER DOMAIN public.udd_qty OWNER TO postgres;

--
-- TOC entry 1486 (class 1247 OID 16429)
-- Name: udd_rate; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_rate AS numeric(12,4) NOT NULL DEFAULT 0;


ALTER DOMAIN public.udd_rate OWNER TO postgres;

--
-- TOC entry 1489 (class 1247 OID 16431)
-- Name: udd_short_code; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_short_code AS character varying(16) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_short_code OWNER TO postgres;

--
-- TOC entry 1492 (class 1247 OID 16433)
-- Name: udd_short_desc; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_short_desc AS character varying(512) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_short_desc OWNER TO postgres;

--
-- TOC entry 1495 (class 1247 OID 16435)
-- Name: udd_smallint; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_smallint AS smallint;


ALTER DOMAIN public.udd_smallint OWNER TO postgres;

--
-- TOC entry 1498 (class 1247 OID 16437)
-- Name: udd_text; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_text AS text COLLATE public.case_insensitive;


ALTER DOMAIN public.udd_text OWNER TO postgres;

--
-- TOC entry 1501 (class 1247 OID 16439)
-- Name: udd_user; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.udd_user AS character varying(32) COLLATE public.case_insensitive DEFAULT NULL::character varying;


ALTER DOMAIN public.udd_user OWNER TO postgres;
