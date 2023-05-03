--
-- PostgreSQL database dump
--

-- Dumped from database version 13.9
-- Dumped by pg_dump version 14.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bank_branch_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bank_branch_master (
    bank_branch_id bigint NOT NULL,
    bank_id integer,
    bank_code character varying(10) DEFAULT NULL::character varying,
    bank_branch_code integer,
    bank_branch_name character varying(200) DEFAULT NULL::character varying,
    ifsc_code character varying(20) DEFAULT NULL::character varying,
    bank_branch_address character varying(255) DEFAULT NULL::character varying,
    rural_urban_branch character varying(1) DEFAULT NULL::character varying,
    village_id integer,
    block_id integer,
    district_id integer,
    state_id integer,
    pincode character varying(6) DEFAULT NULL::character varying,
    branch_merged_with integer,
    is_active boolean NOT NULL,
    created_date timestamp without time zone,
    created_by character varying NOT NULL,
    updated_date timestamp without time zone,
    updated_by integer,
    entity_code character varying(30)
);


ALTER TABLE public.bank_branch_master OWNER TO postgres;

--
-- Name: bank_branch_master_copy_bank_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bank_branch_master_copy_bank_branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_branch_master_copy_bank_branch_id_seq OWNER TO postgres;

--
-- Name: bank_branch_master_copy_bank_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bank_branch_master_copy_bank_branch_id_seq OWNED BY public.bank_branch_master.bank_branch_id;


--
-- Name: bank_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bank_master (
    bank_id integer NOT NULL,
    language_id character varying(2),
    bank_code character varying(10),
    bank_name character varying(100),
    bank_shortname character varying(20),
    bank_type smallint,
    ifsc_mask character varying(11),
    bank_merged_with character varying(20),
    bank_level smallint,
    is_active smallint,
    created_date timestamp without time zone,
    created_by integer,
    updated_date timestamp without time zone,
    updated_by integer,
    bank_account_len character varying(20)
);


ALTER TABLE public.bank_master OWNER TO postgres;

--
-- Name: bank_master_bank_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bank_master_bank_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_master_bank_id_seq OWNER TO postgres;

--
-- Name: bank_master_bank_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bank_master_bank_id_seq OWNED BY public.bank_master.bank_id;


--
-- Name: bank_masterlokos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bank_masterlokos (
    bank_id integer DEFAULT nextval('public.bank_masterlokos_bank_id_seq'::regclass) NOT NULL,
    language_id character varying(2),
    bank_code character varying(10),
    bank_name character varying(100),
    bank_shortname character varying(20),
    bank_type smallint,
    ifsc_mask character varying(11),
    bank_merged_with character varying(20),
    bank_level smallint,
    is_active smallint,
    bank_account_len character varying(20),
    created_date timestamp without time zone,
    created_by integer,
    updated_date timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.bank_masterlokos OWNER TO postgres;

--
-- Name: block_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.block_master (
    block_id integer NOT NULL,
    state_id integer,
    district_id integer,
    block_code character(7),
    block_name_en character varying(100),
    block_name_local character varying(200),
    block_short_name_en character varying(20),
    block_short_name_local character varying(40),
    rural_urban_area character varying(1),
    language_id character varying(2),
    is_active boolean DEFAULT true NOT NULL,
    created_date timestamp without time zone NOT NULL,
    created_by integer NOT NULL,
    updated_date timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.block_master OWNER TO postgres;

--
-- Name: block_master_copy_block_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.block_master_copy_block_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.block_master_copy_block_id_seq OWNER TO postgres;

--
-- Name: block_master_copy_block_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.block_master_copy_block_id_seq OWNED BY public.block_master.block_id;


--
-- Name: core_mst_tfinyear; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tfinyear (
    finyear_gid integer NOT NULL,
    finyear_id public.udd_code NOT NULL,
    finyear_name public.udd_desc NOT NULL,
    finyear_start_date public.udd_date NOT NULL,
    finyear_end_date public.udd_date NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tfinyear OWNER TO postgres;

--
-- Name: pg_trn_tbussplan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tbussplan (
    bussplan_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    blockofficer_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    period_from public.udd_date NOT NULL,
    period_to public.udd_date NOT NULL,
    reviewer_type_code public.udd_code NOT NULL,
    clf_block_id public.udd_int NOT NULL,
    reviewer_code public.udd_code NOT NULL,
    bussplan_review_flag public.udd_flag NOT NULL,
    bussplan_remark public.udd_text,
    ops_exp_amount public.udd_amount,
    net_pl_amount public.udd_amount,
    fundreq_id public.udd_code,
    last_action_date public.udd_datetime NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    row_timestamp public.udd_datetime NOT NULL,
    reviewer_name public.udd_desc DEFAULT NULL::character varying
);


ALTER TABLE public.pg_trn_tbussplan OWNER TO postgres;

--
-- Name: pg_trn_tbussplanfinyear; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tbussplanfinyear (
    bussplancalender_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    finyear_id public.udd_code NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    uom_code public.udd_code NOT NULL,
    prodrevenue_rate public.udd_rate NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    prodprocure_rate public.udd_rate
);


ALTER TABLE public.pg_trn_tbussplanfinyear OWNER TO postgres;

--
-- Name: pg_trn_tbussplanproduce; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tbussplanproduce (
    bussplanproduce_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    finyear_id public.udd_code NOT NULL,
    produce_month public.udd_date NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    uom_code public.udd_code NOT NULL,
    sowing_flag public.udd_flag NOT NULL,
    harvesting_qty public.udd_qty NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tbussplanproduce OWNER TO postgres;

--
-- Name: pg_trn_tbussplanproduct; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tbussplanproduct (
    bussplanprod_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    uom_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    selection_flag public.udd_flag NOT NULL
);


ALTER TABLE public.pg_trn_tbussplanproduct OWNER TO postgres;

--
-- Name: cbo_mapping_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cbo_mapping_details (
    cbo_mapping_id integer NOT NULL,
    cbo_guid character varying(50),
    cbo_child_guid character varying(50),
    cbo_id bigint,
    cbo_child_id bigint,
    cbo_child_code bigint,
    cbo_level smallint,
    cbo_child_level smallint,
    joining_date date,
    leaving_date date,
    settlement_status smallint,
    leaving_reason character varying(150),
    status smallint,
    entry_source smallint,
    is_edited integer,
    last_uploaded_date timestamp without time zone,
    uploaded_by character varying(100),
    created_date timestamp without time zone,
    created_by character varying(100),
    updated_date timestamp without time zone,
    updated_by character varying(100),
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cbo_mapping_details OWNER TO postgres;

--
-- Name: cbo_mapping_details_cbo_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cbo_mapping_details_cbo_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cbo_mapping_details_cbo_mapping_id_seq OWNER TO postgres;

--
-- Name: cbo_mapping_details_cbo_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cbo_mapping_details_cbo_mapping_id_seq OWNED BY public.cbo_mapping_details.cbo_mapping_id;


--
-- Name: federation_profile_consolidated; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.federation_profile_consolidated (
    local_id bigint NOT NULL,
    state_id integer,
    state_code character varying NOT NULL,
    district_id integer,
    district_code character varying NOT NULL,
    block_id integer,
    block_code character varying NOT NULL,
    gp_id integer,
    gp_code character varying,
    village_id integer,
    village_code character varying,
    cbo_type smallint,
    cbo_id bigint,
    cbo_code character varying(50),
    federation_name character varying(250),
    federation_name_local character varying(200),
    federation_formation_date date,
    federation_revival_date date,
    promoted_by smallint,
    promoter_name character varying(50),
    promoter_code character varying(5),
    meeting_frequency smallint,
    meeting_frequency_value smallint,
    meeting_on smallint,
    monthly_comp_saving integer,
    parent_cbo_type smallint,
    parent_cbo_id bigint,
    parent_cbo_code character varying(30),
    savings_frequency smallint,
    primary_activity smallint,
    secondary_activity smallint,
    tertiary_activity smallint,
    bookkeeper_identified smallint,
    bookkeeper_name character varying(100),
    bookkeeper_mobile character varying(12),
    election_tenure smallint,
    savings_interest double precision,
    voluntary_savings_interest double precision,
    does_financial_intermediation boolean,
    has_voluntary_savings boolean,
    status smallint,
    is_active boolean,
    source smallint,
    dedupl_status smallint,
    activation_status smallint,
    approve_status smallint,
    settlement_status smallint,
    created_date date,
    last_updated_date date,
    activation_date date,
    last_approval_date date,
    is_model_clf boolean,
    phone1_mobile_no bigint,
    phone1_phone_ownership smallint,
    phone2_mobile_no bigint,
    phone2_phone_ownership smallint,
    other_phones_json text,
    phone1_member_id bigint,
    phone2_member_id bigint,
    bank1_account_type smallint,
    bank1_account_no character varying(20),
    bank1_branch_code character varying(12),
    bank1_ifsc_code character varying(20),
    bank1_account_open_date date,
    bank1_passbook_name character varying(60),
    bank1_verification_status smallint,
    bank2_account_type smallint,
    bank2_account_no character varying(20),
    bank2_branch_code character varying(12),
    bank2_ifsc_code character varying(20),
    bank2_account_open_date date,
    bank2_passbook_name character varying(60),
    bank2_verification_status smallint,
    other_banks_json text
);


ALTER TABLE public.federation_profile_consolidated OWNER TO postgres;

--
-- Name: pg_mst_taddress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_taddress (
    pgaddress_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    addr_type_code public.udd_code NOT NULL,
    addr_line public.udd_text NOT NULL,
    pin_code public.udd_pincode NOT NULL,
    village_id public.udd_int NOT NULL,
    panchayat_id public.udd_int NOT NULL,
    block_id public.udd_int NOT NULL,
    district_id public.udd_int NOT NULL,
    state_id public.udd_int NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_taddress OWNER TO postgres;

--
-- Name: pg_mst_tproducergroup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tproducergroup (
    pg_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pg_name public.udd_desc NOT NULL,
    pg_ll_name public.udd_desc,
    pg_type_code public.udd_code NOT NULL,
    formation_date public.udd_date NOT NULL,
    promoter_code public.udd_code NOT NULL,
    state_id public.udd_int,
    district_id public.udd_int,
    block_id public.udd_int,
    panchayat_id public.udd_int,
    village_id public.udd_int,
    cbo_id public.udd_code,
    cbo_name public.udd_desc,
    clf_id public.udd_code,
    clf_name public.udd_desc,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    row_timestamp public.udd_datetime,
    pg_inactive_code public.udd_code
);


ALTER TABLE public.pg_mst_tproducergroup OWNER TO postgres;

--
-- Name: district_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.district_master (
    district_id integer NOT NULL,
    state_id integer NOT NULL,
    district_code character(4),
    district_name_en character varying(100),
    district_name_local character varying(200),
    district_short_name_en character varying(20),
    district_short_name_local character varying(40),
    fundrelease_flag boolean,
    language_id character varying(2),
    is_active boolean DEFAULT true NOT NULL,
    created_date timestamp without time zone NOT NULL,
    created_by integer NOT NULL,
    updated_date timestamp without time zone,
    updated_by integer,
    district_name_hi character varying(255)
);


ALTER TABLE public.district_master OWNER TO postgres;

--
-- Name: pg_mst_tpanchayatmapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpanchayatmapping (
    pgpanchayatmapping_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    panchayat_id public.udd_int NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    state_id public.udd_int,
    district_id public.udd_int,
    block_id public.udd_int
);


ALTER TABLE public.pg_mst_tpanchayatmapping OWNER TO postgres;

--
-- Name: state_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.state_master (
    state_id integer NOT NULL,
    state_code character(2),
    state_name_en character varying(50),
    state_name_hi character varying(100),
    state_name_local character varying(100),
    state_short_local_name character varying(10),
    state_short_name_en character varying(10),
    category smallint,
    is_active boolean DEFAULT true NOT NULL,
    created_date timestamp without time zone NOT NULL,
    created_by integer NOT NULL,
    updated_date timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.state_master OWNER TO postgres;

--
-- Name: federation_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.federation_profile (
    federation_id bigint NOT NULL,
    federation_code bigint,
    state_id integer NOT NULL,
    district_id integer NOT NULL,
    block_id integer NOT NULL,
    village_id integer,
    panchayat_id integer,
    federation_name character varying(200) NOT NULL,
    federation_type_code smallint,
    cbo_type smallint,
    cbo_level smallint,
    child_level smallint,
    federation_name_local character varying(120) DEFAULT NULL::character varying,
    promoted_by smallint,
    parent_cbo_code bigint,
    parent_cbo_type smallint,
    is_active boolean,
    status smallint,
    promoter_code character varying(5),
    created_date timestamp without time zone,
    updated_date timestamp without time zone
);


ALTER TABLE public.federation_profile OWNER TO postgres;

--
-- Name: member_profile_consolidated; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_profile_consolidated (
    local_id bigint NOT NULL,
    state_id integer,
    state_code character varying,
    district_id integer,
    district_code character varying,
    block_id integer,
    block_code character varying,
    gp_id integer,
    gp_code character varying,
    village_id integer,
    village_code character varying,
    member_id bigint,
    member_code bigint,
    shg_id bigint,
    shg_code character varying(50),
    seq_no smallint,
    member_name character varying(100) NOT NULL,
    member_name_local character varying(100),
    relation_type character varying(1),
    relation_name character varying(100),
    relation_name_local character varying(100),
    gender smallint,
    religion smallint,
    social_category smallint,
    tribal_category smallint,
    highest_education_level smallint,
    dob_available smallint,
    dob date,
    age smallint,
    age_as_on date,
    minority smallint,
    is_disabled smallint,
    disability_details smallint,
    primary_occupation smallint,
    secondary_occupation smallint,
    tertiary_occupation smallint,
    joining_date date NOT NULL,
    leaving_date date,
    reason_for_leaving smallint,
    guardian_name character varying(100),
    guardian_name_local character varying(100),
    guardian_relation smallint,
    house_hold_code smallint,
    head_house_hold integer,
    insurance integer,
    is_active boolean,
    mem_activation_status smallint,
    approve_status smallint,
    mem_dedup_status smallint,
    settlement_status smallint,
    source smallint,
    created_date date,
    last_updated_date date,
    activation_date date,
    last_approval_date date,
    add1_type smallint,
    add1_line1 character varying(255),
    add1_line2 character varying(255),
    add1_village_id integer,
    add1_state_id integer,
    add1_district_id integer,
    add1_block_id integer,
    add1_gp_id integer,
    add1_postal_code integer,
    other_addresses_json text,
    kyc1_type smallint,
    kyc1_number character varying(50),
    kyc1_status smallint,
    other_kyc_json text,
    bank1_account_type smallint,
    bank1_account_no character varying(20),
    bank1_branch_code character varying(12),
    bank1_ifsc_code character varying(20),
    bank1_account_open_date date,
    bank1_passbook_name character varying(60),
    bank1_verification_status smallint,
    other_banks_json text,
    id1_system_type smallint,
    id1_system_id character varying(25),
    id1_status smallint,
    id2_system_type smallint,
    id2_system_id character varying(25),
    id2_status smallint,
    id3_system_type smallint,
    id3_system_id character varying(25),
    id3_status smallint,
    other_ids_json text,
    design1_cbo_type smallint,
    design1_cbo_id integer,
    design1_cbo_code character varying(15),
    desig1_category smallint,
    desig1_role smallint,
    desig1_from date,
    desig1_to date,
    desig1_status smallint,
    design2_cbo_type smallint,
    design2_cbo_id integer,
    design2_cbo_code character varying(15),
    design2_category smallint,
    desig2_role smallint,
    desig2_from date,
    desig2_to date,
    desig2_status smallint,
    design3_cbo_type smallint,
    design3_cbo_id integer,
    design3_cbo_code character varying(15),
    desig3_category smallint,
    desig3_role smallint,
    desig3_from date,
    desig3_to date,
    desig3_status smallint,
    desig_others_json text,
    ins1_type smallint,
    ins1_valid_till date,
    ins2_type smallint,
    ins2_valid_till date,
    ins3_type smallint,
    ins3_valid_till date,
    ins_others_json text,
    phone1_mobile_no bigint,
    phone1_phone_ownership smallint,
    phone2_mobile_no bigint,
    phone2_phone_ownership bigint,
    other_phones_json text
);


ALTER TABLE public.member_profile_consolidated OWNER TO postgres;

--
-- Name: shg_profile_consolidated; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shg_profile_consolidated (
    local_id bigint NOT NULL,
    state_id integer,
    state_code character varying,
    district_id integer,
    district_code character varying,
    block_id integer,
    block_code character varying,
    gp_id integer,
    gp_code character varying,
    village_id integer,
    village_code character varying,
    shg_id bigint,
    shg_code character varying(50),
    shg_name character varying(200) NOT NULL,
    shg_type_code smallint,
    shg_type_other character varying(100),
    shg_name_local character varying(120),
    shg_formation_date date,
    shg_revival_date date,
    shg_cooption_date date,
    shg_promoted_by smallint,
    meeting_frequency smallint,
    meeting_frequency_value smallint,
    meeting_on smallint,
    monthly_comp_saving integer,
    interloaning_rate double precision,
    saving_interest double precision,
    voluntary_savings_interest double precision,
    parent_cbo_id bigint,
    parent_cbo_code character varying(50),
    is_active boolean,
    dedupl_status smallint,
    activation_status smallint,
    approve_status smallint,
    settlement_status smallint,
    primary_activity smallint,
    secondary_activity smallint,
    tertiary_activity smallint,
    saving_frequency smallint,
    status smallint,
    has_voluntary_savings boolean,
    bookkeeper_identified smallint,
    bookkeeper_name character varying(60),
    bookkeeper_mobile character varying(12),
    election_tenure smallint,
    created_date date,
    last_updated_date date,
    activation_date date,
    last_approval_date date,
    inactive_reason smallint,
    add1_line1 character varying(255),
    add1_line2 character varying(255),
    add1_village_id integer,
    add1_state_id integer,
    add1_district_id integer,
    add1_block_id integer,
    add1_gp_id integer,
    add1_postal_code integer,
    other_addresses_json text,
    kyc1_type smallint,
    kyc1_number character varying(50),
    kyc1_status smallint,
    other_kyc_json text,
    bank1_account_type smallint,
    bank1_account_no character varying(20),
    bank1_branch_code character varying(12),
    bank1_ifsc_code character varying(20),
    bank1_account_open_date date,
    bank1_passbook_name character varying(60),
    bank1_verification_status smallint,
    bank2_account_type smallint,
    bank2_account_no character varying(20),
    bank2_branch_code character varying(12),
    bank2_ifsc_code character varying(20),
    bank2_account_open_date date,
    bank2_passbook_name character varying(60),
    bank2_verification_status smallint,
    other_banks_json text,
    id1_system_type smallint,
    id1_system_id character varying(25),
    id1_status smallint,
    id2_system_type smallint,
    id2_system_id character varying(25),
    id2_status smallint,
    id3_system_type smallint,
    id3_system_id character varying(25),
    id3_status smallint,
    other_ids_json text,
    design1_type smallint,
    design1_member_id bigint,
    design1_is_signatory boolean,
    desig1_from date,
    desig1_to date,
    design2_type smallint,
    design2_member_id bigint,
    design2_is_signatory boolean,
    desig2_from date,
    desig2_to date,
    design3_type smallint,
    design3_member_id bigint,
    design3_is_signatory boolean,
    desig3_from date,
    desig3_to date,
    desig_others_json text,
    source smallint,
    phone1_mobile_no bigint,
    phone1_phone_ownership smallint,
    phone2_mobile_no bigint,
    phone2_phone_ownership smallint,
    other_phones_json text,
    phone1_member_id bigint,
    phone2_member_id bigint
);


ALTER TABLE public.shg_profile_consolidated OWNER TO postgres;

--
-- Name: core_mst_tproduct; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tproduct (
    prod_gid integer NOT NULL,
    prod_code public.udd_code NOT NULL,
    farm_prod_flag public.udd_code NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    category_code public.udd_code NOT NULL,
    subcategory_code public.udd_code NOT NULL,
    uom_code public.udd_code NOT NULL,
    prod_image public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    row_timestamp public.udd_datetime
);


ALTER TABLE public.core_mst_tproduct OWNER TO postgres;

--
-- Name: config_path; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.config_path (
    fn_get_configvalue public.udd_desc
);


ALTER TABLE public.config_path OWNER TO postgres;

--
-- Name: core_mst_tconfig; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tconfig (
    config_gid integer NOT NULL,
    config_name public.udd_desc NOT NULL,
    config_value public.udd_desc NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tconfig OWNER TO postgres;

--
-- Name: core_mst_tconfig_config_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tconfig_config_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tconfig_config_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tconfig_config_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tconfig_config_gid_seq OWNED BY public.core_mst_tconfig.config_gid;


--
-- Name: core_mst_tdocnum; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tdocnum (
    docnum_gid integer NOT NULL,
    activity_code public.udd_code NOT NULL,
    docnum_seq_no public.udd_int NOT NULL,
    docnum_remark public.udd_desc,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tdocnum OWNER TO postgres;

--
-- Name: core_mst_tdocnum_docnum_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tdocnum_docnum_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tdocnum_docnum_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tdocnum_docnum_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tdocnum_docnum_gid_seq OWNED BY public.core_mst_tdocnum.docnum_gid;


--
-- Name: core_mst_tfinyear_finyear_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tfinyear_finyear_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tfinyear_finyear_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tfinyear_finyear_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tfinyear_finyear_gid_seq OWNED BY public.core_mst_tfinyear.finyear_gid;


--
-- Name: core_mst_tifsc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tifsc (
    ifsc_gid integer NOT NULL,
    ifsc_code public.udd_code NOT NULL,
    bank_code public.udd_code NOT NULL,
    bank_name public.udd_desc NOT NULL,
    branch_name public.udd_desc,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tifsc OWNER TO postgres;

--
-- Name: core_mst_tifsc_ifsc_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tifsc_ifsc_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tifsc_ifsc_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tifsc_ifsc_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tifsc_ifsc_gid_seq OWNED BY public.core_mst_tifsc.ifsc_gid;


--
-- Name: core_mst_tinterfaceurl; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tinterfaceurl (
    ifaceurl_gid integer NOT NULL,
    ifaceurl_code public.udd_code NOT NULL,
    ifaceurl_name public.udd_desc NOT NULL,
    iface_url public.udd_text,
    user_id public.udd_code NOT NULL,
    user_pwd public.udd_text,
    user_role_id public.udd_mobile,
    tenant_id public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tinterfaceurl OWNER TO postgres;

--
-- Name: core_mst_tinterfaceurl_ifaceurl_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tinterfaceurl_ifaceurl_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tinterfaceurl_ifaceurl_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tinterfaceurl_ifaceurl_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tinterfaceurl_ifaceurl_gid_seq OWNED BY public.core_mst_tinterfaceurl.ifaceurl_gid;


--
-- Name: core_mst_tlanguage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tlanguage (
    lang_gid integer NOT NULL,
    lang_code public.udd_code NOT NULL,
    lang_name public.udd_desc NOT NULL,
    default_flag public.udd_flag NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tlanguage OWNER TO postgres;

--
-- Name: core_mst_tlanguage_lang_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tlanguage_lang_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tlanguage_lang_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tlanguage_lang_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tlanguage_lang_gid_seq OWNED BY public.core_mst_tlanguage.lang_gid;


--
-- Name: core_mst_tlokossync; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tlokossync (
    lokossync_gid integer DEFAULT nextval('public.core_mst_tlokossync_lokossync_gid_seq'::regclass) NOT NULL,
    state_id public.udd_int NOT NULL,
    db_name public.udd_desc,
    schema_name public.udd_desc,
    db_server_ip public.udd_code,
    db_user_name public.udd_code,
    db_user_pwd public.udd_text,
    last_sync_date public.udd_datetime NOT NULL,
    prev_last_sync_date public.udd_datetime,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tlokossync OWNER TO postgres;

--
-- Name: core_mst_tlokossyncqry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tlokossyncqry (
    lokossyncqry_gid integer NOT NULL,
    lokossync_qry_name public.udd_desc NOT NULL,
    lokossync_qry public.udd_text NOT NULL,
    pg_sp_name public.udd_desc NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    table_type_code public.udd_code
);


ALTER TABLE public.core_mst_tlokossyncqry OWNER TO postgres;

--
-- Name: core_mst_tlokossyncqry_lokossyncqry_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tlokossyncqry_lokossyncqry_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tlokossyncqry_lokossyncqry_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tlokossyncqry_lokossyncqry_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tlokossyncqry_lokossyncqry_gid_seq OWNED BY public.core_mst_tlokossyncqry.lokossyncqry_gid;


--
-- Name: core_mst_tmaster; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmaster (
    master_gid integer NOT NULL,
    parent_code public.udd_code NOT NULL,
    master_code public.udd_code NOT NULL,
    depend_parent_code public.udd_code,
    depend_code public.udd_code,
    rec_slno public.udd_int,
    sys_flag public.udd_flag NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    row_timestamp public.udd_datetime NOT NULL
);


ALTER TABLE public.core_mst_tmaster OWNER TO postgres;

--
-- Name: core_mst_tmaster_master_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmaster_master_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmaster_master_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmaster_master_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmaster_master_gid_seq OWNED BY public.core_mst_tmaster.master_gid;


--
-- Name: core_mst_tmastertranslate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmastertranslate (
    mastertranslate_gid integer NOT NULL,
    parent_code public.udd_code NOT NULL,
    master_code public.udd_code NOT NULL,
    lang_code public.udd_code NOT NULL,
    master_desc public.udd_desc NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_code NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_code
);


ALTER TABLE public.core_mst_tmastertranslate OWNER TO postgres;

--
-- Name: core_mst_tmastertranslate_mastertranslate_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmastertranslate_mastertranslate_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmastertranslate_mastertranslate_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmastertranslate_mastertranslate_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmastertranslate_mastertranslate_gid_seq OWNED BY public.core_mst_tmastertranslate.mastertranslate_gid;


--
-- Name: core_mst_tmenu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmenu (
    menu_gid integer NOT NULL,
    menu_code public.udd_code NOT NULL,
    parent_code public.udd_code NOT NULL,
    menu_slno public.udd_amount,
    url_action_method public.udd_desc,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    menu_type_code public.udd_code
);


ALTER TABLE public.core_mst_tmenu OWNER TO postgres;

--
-- Name: core_mst_tmenu_menu_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmenu_menu_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmenu_menu_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmenu_menu_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmenu_menu_gid_seq OWNED BY public.core_mst_tmenu.menu_gid;


--
-- Name: core_mst_tmenutranslate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmenutranslate (
    menutranslate_gid integer NOT NULL,
    menu_code public.udd_code NOT NULL,
    lang_code public.udd_code NOT NULL,
    menu_desc public.udd_desc NOT NULL,
    created_date public.udd_datetime,
    created_by public.udd_code,
    updated_date public.udd_datetime,
    updated_by public.udd_code
);


ALTER TABLE public.core_mst_tmenutranslate OWNER TO postgres;

--
-- Name: core_mst_tmenutranslate_menutranslate_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmenutranslate_menutranslate_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmenutranslate_menutranslate_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmenutranslate_menutranslate_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmenutranslate_menutranslate_gid_seq OWNED BY public.core_mst_tmenutranslate.menutranslate_gid;


--
-- Name: core_mst_tmessage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmessage (
    msg_gid integer NOT NULL,
    msg_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tmessage OWNER TO postgres;

--
-- Name: core_mst_tmessage_msg_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmessage_msg_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmessage_msg_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmessage_msg_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmessage_msg_gid_seq OWNED BY public.core_mst_tmessage.msg_gid;


--
-- Name: core_mst_tmessagetranslate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmessagetranslate (
    msgtranslate_gid integer NOT NULL,
    msg_code public.udd_code NOT NULL,
    lang_code public.udd_code NOT NULL,
    msg_desc public.udd_desc NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_code NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_code
);


ALTER TABLE public.core_mst_tmessagetranslate OWNER TO postgres;

--
-- Name: core_mst_tmessagetranslate_msgtranslate_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmessagetranslate_msgtranslate_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmessagetranslate_msgtranslate_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmessagetranslate_msgtranslate_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmessagetranslate_msgtranslate_gid_seq OWNED BY public.core_mst_tmessagetranslate.msgtranslate_gid;


--
-- Name: core_mst_tmobilesync; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmobilesync (
    mobilesync_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    role_code public.udd_code NOT NULL,
    user_code public.udd_code NOT NULL,
    mobile_no public.udd_mobile NOT NULL,
    sync_type_code public.udd_code NOT NULL,
    last_sync_date public.udd_datetime NOT NULL,
    prev_last_sync_date public.udd_datetime,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tmobilesync OWNER TO postgres;

--
-- Name: core_mst_tmobilesync_mobilesync_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmobilesync_mobilesync_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmobilesync_mobilesync_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmobilesync_mobilesync_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmobilesync_mobilesync_gid_seq OWNED BY public.core_mst_tmobilesync.mobilesync_gid;


--
-- Name: core_mst_tmobilesynctable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tmobilesynctable (
    mobilesynctable_gid integer NOT NULL,
    db_schema_name public.udd_desc NOT NULL,
    src_table_name public.udd_desc NOT NULL,
    dest_table_name public.udd_desc NOT NULL,
    conflict_key public.udd_text[] NOT NULL,
    ignore_fields_onupdate public.udd_text[],
    default_condition public.udd_text,
    sync_group_name public.udd_desc NOT NULL,
    table_order public.udd_int,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    ignore_fields public.udd_text[],
    date_flag public.udd_flag,
    pg_flag public.udd_flag,
    role_code public.udd_code,
    user_flag public.udd_code DEFAULT 'N'::character varying NOT NULL,
    role_flag public.udd_code DEFAULT 'N'::character varying NOT NULL,
    mobile_flag public.udd_code DEFAULT 'N'::character varying NOT NULL
);


ALTER TABLE public.core_mst_tmobilesynctable OWNER TO postgres;

--
-- Name: core_mst_tmobilesynctable_mobilesynctable_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tmobilesynctable_mobilesynctable_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tmobilesynctable_mobilesynctable_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tmobilesynctable_mobilesynctable_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tmobilesynctable_mobilesynctable_gid_seq OWNED BY public.core_mst_tmobilesynctable.mobilesynctable_gid;


--
-- Name: core_mst_tpatchqry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tpatchqry (
    patchqry_gid integer DEFAULT nextval('public.core_mst_tpatchqry_patchqry_gid_seq'::regclass) NOT NULL,
    patch_no public.udd_int NOT NULL,
    patch_qry public.udd_text NOT NULL,
    role_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tpatchqry OWNER TO postgres;

--
-- Name: core_mst_tpgdocnum; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tpgdocnum (
    pgdocnum_gid integer NOT NULL,
    activity_code public.udd_code NOT NULL,
    pg_id public.udd_code NOT NULL,
    finyear_id public.udd_code NOT NULL,
    tran_date public.udd_date NOT NULL,
    next_seq_no public.udd_int NOT NULL,
    docnum_format public.udd_code,
    docnum_remark public.udd_desc,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tpgdocnum OWNER TO postgres;

--
-- Name: core_mst_tpgdocnum_pgdocnum_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tpgdocnum_pgdocnum_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tpgdocnum_pgdocnum_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tpgdocnum_pgdocnum_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tpgdocnum_pgdocnum_gid_seq OWNED BY public.core_mst_tpgdocnum.pgdocnum_gid;


--
-- Name: core_mst_tproduct_prod_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tproduct_prod_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tproduct_prod_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tproduct_prod_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tproduct_prod_gid_seq OWNED BY public.core_mst_tproduct.prod_gid;


--
-- Name: pg_mst_tproductmapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tproductmapping (
    pgprodmapp_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    frequent_flag public.udd_flag NOT NULL,
    created_date public.udd_datetime,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    stock_reset_flag public.udd_flag NOT NULL
);


ALTER TABLE public.pg_mst_tproductmapping OWNER TO postgres;

--
-- Name: core_mst_tproductprice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tproductprice (
    prodprice_gid integer NOT NULL,
    prod_code public.udd_code NOT NULL,
    state_id public.udd_int NOT NULL,
    grade_code public.udd_code NOT NULL,
    msp_price public.udd_amount NOT NULL,
    procurement_price public.udd_amount NOT NULL,
    last_modified_date public.udd_date,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tproductprice OWNER TO postgres;

--
-- Name: core_mst_tproductprice_prodprice_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tproductprice_prodprice_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tproductprice_prodprice_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tproductprice_prodprice_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tproductprice_prodprice_gid_seq OWNED BY public.core_mst_tproductprice.prodprice_gid;


--
-- Name: core_mst_tproductquality; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tproductquality (
    prodqlty_gid integer NOT NULL,
    prod_code public.udd_code NOT NULL,
    qltyparam_code public.udd_code NOT NULL,
    range_from public.udd_rate,
    range_to public.udd_rate,
    range_flag public.udd_flag,
    qltyuom_code public.udd_code NOT NULL,
    threshold_value public.udd_rate,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tproductquality OWNER TO postgres;

--
-- Name: core_mst_tproductquality_prodqlty_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tproductquality_prodqlty_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tproductquality_prodqlty_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tproductquality_prodqlty_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tproductquality_prodqlty_gid_seq OWNED BY public.core_mst_tproductquality.prodqlty_gid;


--
-- Name: core_mst_tproducttranslate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tproducttranslate (
    prodtranslate_gid integer NOT NULL,
    prod_code public.udd_code NOT NULL,
    lang_code public.udd_code NOT NULL,
    prod_desc public.udd_desc NOT NULL,
    created_date public.udd_datetime,
    created_by public.udd_user,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tproducttranslate OWNER TO postgres;

--
-- Name: core_mst_tproducttranslate_prodtranslate_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tproducttranslate_prodtranslate_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tproducttranslate_prodtranslate_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tproducttranslate_prodtranslate_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tproducttranslate_prodtranslate_gid_seq OWNED BY public.core_mst_tproducttranslate.prodtranslate_gid;


--
-- Name: core_mst_treport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_treport (
    report_gid integer NOT NULL,
    report_code public.udd_code NOT NULL,
    sp_name public.udd_desc NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_treport OWNER TO postgres;

--
-- Name: core_mst_treport_report_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_treport_report_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_treport_report_gid_seq OWNER TO postgres;

--
-- Name: core_mst_treport_report_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_treport_report_gid_seq OWNED BY public.core_mst_treport.report_gid;


--
-- Name: core_mst_treportparam; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_treportparam (
    reportparam_gid integer NOT NULL,
    report_code public.udd_code NOT NULL,
    param_code public.udd_code NOT NULL,
    param_type_code public.udd_code NOT NULL,
    param_name public.udd_desc NOT NULL,
    param_datatype_code public.udd_code NOT NULL,
    param_order public.udd_int NOT NULL,
    display_flag public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_treportparam OWNER TO postgres;

--
-- Name: core_mst_treportparam_reportparam_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_treportparam_reportparam_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_treportparam_reportparam_gid_seq OWNER TO postgres;

--
-- Name: core_mst_treportparam_reportparam_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_treportparam_reportparam_gid_seq OWNED BY public.core_mst_treportparam.reportparam_gid;


--
-- Name: core_mst_trole; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_trole (
    role_gid integer NOT NULL,
    role_code public.udd_code NOT NULL,
    role_name public.udd_desc NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    row_timestamp public.udd_datetime NOT NULL
);


ALTER TABLE public.core_mst_trole OWNER TO postgres;

--
-- Name: core_mst_trole_role_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_trole_role_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_trole_role_gid_seq OWNER TO postgres;

--
-- Name: core_mst_trole_role_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_trole_role_gid_seq OWNED BY public.core_mst_trole.role_gid;


--
-- Name: core_mst_trolemenurights; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_trolemenurights (
    rolemenurights_gid integer NOT NULL,
    role_code public.udd_code NOT NULL,
    menu_code public.udd_code NOT NULL,
    add_flag public.udd_desc NOT NULL,
    modifiy_flag public.udd_flag NOT NULL,
    view_flag public.udd_flag NOT NULL,
    auth_flag public.udd_flag NOT NULL,
    print_flag public.udd_flag NOT NULL,
    inactive_flag public.udd_flag NOT NULL,
    deny_flag public.udd_flag NOT NULL
);


ALTER TABLE public.core_mst_trolemenurights OWNER TO postgres;

--
-- Name: core_mst_trolemenurights_rolemenurights_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_trolemenurights_rolemenurights_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_trolemenurights_rolemenurights_gid_seq OWNER TO postgres;

--
-- Name: core_mst_trolemenurights_rolemenurights_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_trolemenurights_rolemenurights_gid_seq OWNED BY public.core_mst_trolemenurights.rolemenurights_gid;


--
-- Name: core_mst_tscreen; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tscreen (
    screen_gid integer NOT NULL,
    screen_code public.udd_code NOT NULL,
    screen_name public.udd_desc NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tscreen OWNER TO postgres;

--
-- Name: core_mst_tscreen_screen_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tscreen_screen_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tscreen_screen_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tscreen_screen_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tscreen_screen_gid_seq OWNED BY public.core_mst_tscreen.screen_gid;


--
-- Name: core_mst_tscreendata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tscreendata (
    screendata_gid integer NOT NULL,
    screen_code public.udd_code NOT NULL,
    lang_code public.udd_code,
    ctrl_type_code public.udd_code NOT NULL,
    ctrl_id public.udd_desc NOT NULL,
    data_field public.udd_desc,
    label_desc public.udd_desc,
    tooltip_desc public.udd_desc,
    default_label_desc public.udd_desc,
    default_tooltip_desc public.udd_desc,
    ctrl_slno public.udd_int,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tscreendata OWNER TO postgres;

--
-- Name: core_mst_tscreendata_screendata_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tscreendata_screendata_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tscreendata_screendata_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tscreendata_screendata_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tscreendata_screendata_gid_seq OWNED BY public.core_mst_tscreendata.screendata_gid;


--
-- Name: core_mst_tsmstemplate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tsmstemplate (
    smstemplate_gid integer NOT NULL,
    smstemplate_code public.udd_code NOT NULL,
    sms_template public.udd_text NOT NULL,
    dlt_template_id public.udd_code NOT NULL,
    lang_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tsmstemplate OWNER TO postgres;

--
-- Name: core_mst_tsmstemplate_smstemplate_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tsmstemplate_smstemplate_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tsmstemplate_smstemplate_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tsmstemplate_smstemplate_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tsmstemplate_smstemplate_gid_seq OWNED BY public.core_mst_tsmstemplate.smstemplate_gid;


--
-- Name: core_mst_ttenantidentifier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_ttenantidentifier (
    tenant_gid integer DEFAULT nextval('public.core_mst_ttenantidentifier_tenant_gid_seq'::regclass) NOT NULL,
    tenant_identifier public.udd_code NOT NULL,
    geo_location_flag public.udd_flag NOT NULL,
    bank_branch_flag public.udd_flag NOT NULL,
    shg_profile_flag public.udd_flag,
    tenant_user public.udd_user,
    tenant_password public.udd_desc,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    state_id public.udd_int
);


ALTER TABLE public.core_mst_ttenantidentifier OWNER TO postgres;

--
-- Name: core_mst_tuomconv; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tuomconv (
    uomconv_gid integer NOT NULL,
    uom_code_from public.udd_code NOT NULL,
    uom_code_to public.udd_code,
    conv_rate public.udd_rate NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tuomconv OWNER TO postgres;

--
-- Name: core_mst_tuomconv_uomconv_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tuomconv_uomconv_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tuomconv_uomconv_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tuomconv_uomconv_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tuomconv_uomconv_gid_seq OWNED BY public.core_mst_tuomconv.uomconv_gid;


--
-- Name: core_mst_tuser; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tuser (
    user_gid integer NOT NULL,
    user_code public.udd_code NOT NULL,
    user_name public.udd_desc NOT NULL,
    role_code public.udd_code NOT NULL,
    user_pwd public.udd_text,
    mobile_no public.udd_mobile,
    email_id public.udd_desc,
    user_type_code public.udd_code,
    lokos_id public.udd_code,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tuser OWNER TO postgres;

--
-- Name: core_mst_tuser_user_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.core_mst_tuser_user_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.core_mst_tuser_user_gid_seq OWNER TO postgres;

--
-- Name: core_mst_tuser_user_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.core_mst_tuser_user_gid_seq OWNED BY public.core_mst_tuser.user_gid;


--
-- Name: core_mst_tuserblock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tuserblock (
    userblock_gid integer DEFAULT nextval('public.core_mst_tuserblock_userblock_gid_seq'::regclass) NOT NULL,
    user_code public.udd_code NOT NULL,
    block_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tuserblock OWNER TO postgres;

--
-- Name: core_mst_tusertoken; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_mst_tusertoken (
    token_gid integer DEFAULT nextval('public.core_mst_tusertoken_token_gid_seq'::regclass) NOT NULL,
    user_code public.udd_user NOT NULL,
    user_token public.udd_text NOT NULL,
    url public.udd_text,
    token_expired_date public.udd_datetime NOT NULL,
    token_expired_flag public.udd_flag NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.core_mst_tusertoken OWNER TO postgres;

--
-- Name: district_master_copy_district_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.district_master_copy_district_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.district_master_copy_district_id_seq OWNER TO postgres;

--
-- Name: district_master_copy_district_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.district_master_copy_district_id_seq OWNED BY public.district_master.district_id;


--
-- Name: executive_member; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.executive_member (
    executive_member_id bigint NOT NULL,
    cbo_id bigint,
    cbo_level smallint,
    ec_cbo_level smallint,
    ec_cbo_code character varying(50),
    ec_cbo_id bigint,
    ec_member_code bigint,
    designation smallint,
    joining_date date,
    leaving_date date,
    status smallint,
    is_active boolean,
    state_id integer,
    created_date timestamp without time zone,
    updated_date timestamp without time zone
);


ALTER TABLE public.executive_member OWNER TO postgres;

--
-- Name: executive_member_executive_member_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.executive_member_executive_member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.executive_member_executive_member_id_seq OWNER TO postgres;

--
-- Name: executive_member_executive_member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.executive_member_executive_member_id_seq OWNED BY public.executive_member.executive_member_id;


--
-- Name: member_address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_address (
    member_address_id integer NOT NULL,
    cbo_id bigint,
    member_code bigint,
    address_type smallint,
    address_line1 character varying(255) NOT NULL,
    address_line2 character varying(255),
    village integer NOT NULL,
    state integer NOT NULL,
    district integer NOT NULL,
    postal_code integer NOT NULL,
    status smallint,
    is_active boolean DEFAULT true NOT NULL,
    block_id integer DEFAULT 498 NOT NULL,
    panchayat_id integer DEFAULT 3 NOT NULL,
    state_id integer,
    created_date timestamp without time zone,
    updated_date timestamp without time zone
);


ALTER TABLE public.member_address OWNER TO postgres;

--
-- Name: member_bank_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_bank_details (
    member_bank_details_id integer NOT NULL,
    cbo_id bigint,
    member_code bigint,
    account_no character varying(20) NOT NULL,
    bank_id bigint NOT NULL,
    account_type smallint NOT NULL,
    mem_branch_code character varying(12),
    ifsc_code character varying(20),
    is_default_account integer NOT NULL,
    closing_date date,
    status smallint,
    is_active boolean DEFAULT true NOT NULL,
    state_id integer,
    created_date timestamp without time zone,
    updated_date timestamp without time zone
);


ALTER TABLE public.member_bank_details OWNER TO postgres;

--
-- Name: member_phone_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_phone_details (
    member_phone_details_id bigint NOT NULL,
    cbo_id bigint,
    member_code bigint,
    phone_no bigint NOT NULL,
    is_default smallint NOT NULL,
    status smallint,
    is_active boolean DEFAULT true NOT NULL,
    state_id integer,
    created_date timestamp without time zone,
    updated_date timestamp without time zone
);


ALTER TABLE public.member_phone_details OWNER TO postgres;

--
-- Name: member_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_profile (
    member_id integer NOT NULL,
    member_code bigint,
    cbo_id bigint NOT NULL,
    group_m_code integer,
    seq_no integer,
    member_name character varying(50) NOT NULL,
    member_name_local character varying(100),
    father_husband character varying(1) NOT NULL,
    relation_name character varying(50) NOT NULL,
    relation_name_local character varying(100),
    gender smallint NOT NULL,
    social_category smallint,
    dob date,
    is_active boolean DEFAULT true NOT NULL,
    mem_activation_status smallint,
    age integer,
    age_as_on date,
    dob_available integer,
    state_id integer,
    created_date timestamp without time zone,
    updated_date timestamp without time zone
);


ALTER TABLE public.member_profile OWNER TO postgres;

--
-- Name: panchayat_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.panchayat_master (
    panchayat_id integer NOT NULL,
    state_id integer,
    district_id integer,
    block_id integer,
    panchayat_code character(10),
    panchayat_name_en character varying(100),
    panchayat_name_local character varying(200),
    language_id character varying(2),
    rural_urban_area character varying(1),
    is_active boolean DEFAULT true NOT NULL,
    created_date timestamp without time zone NOT NULL,
    created_by integer NOT NULL,
    updated_date timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.panchayat_master OWNER TO postgres;

--
-- Name: panchayat_master_copy_panchayat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.panchayat_master_copy_panchayat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.panchayat_master_copy_panchayat_id_seq OWNER TO postgres;

--
-- Name: panchayat_master_copy_panchayat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.panchayat_master_copy_panchayat_id_seq OWNED BY public.panchayat_master.panchayat_id;


--
-- Name: pg_trn_tfundrepymt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tfundrepymt (
    fundrepymt_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    loan_acc_no public.udd_code NOT NULL,
    pymt_date public.udd_date NOT NULL,
    pay_mode_code public.udd_code NOT NULL,
    paid_amount public.udd_amount NOT NULL,
    pymt_ref_no public.udd_code NOT NULL,
    principal_amount public.udd_amount NOT NULL,
    interest_amount public.udd_amount NOT NULL,
    other_amount public.udd_amount NOT NULL,
    pymt_remarks public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tfundrepymt OWNER TO postgres;

--
-- Name: village_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.village_master (
    village_id integer NOT NULL,
    state_id integer,
    district_id integer,
    block_id integer,
    panchayat_id bigint,
    village_code character(16),
    village_name_en character varying(100),
    village_name_local character varying(200),
    is_active boolean DEFAULT true NOT NULL,
    created_date timestamp without time zone NOT NULL,
    created_by integer NOT NULL,
    updated_date timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.village_master OWNER TO postgres;

--
-- Name: pg_mst_tactivity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tactivity (
    pgactivitity_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    seq_no public.udd_int NOT NULL,
    activity_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    prod_code public.udd_code NOT NULL
);


ALTER TABLE public.pg_mst_tactivity OWNER TO postgres;

--
-- Name: pg_mst_tactivity_pgactivitity_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tactivity_pgactivitity_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tactivity_pgactivitity_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tactivity_pgactivitity_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tactivity_pgactivitity_gid_seq OWNED BY public.pg_mst_tactivity.pgactivitity_gid;


--
-- Name: pg_mst_taddress_pgaddress_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_taddress_pgaddress_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_taddress_pgaddress_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_taddress_pgaddress_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_taddress_pgaddress_gid_seq OWNED BY public.pg_mst_taddress.pgaddress_gid;


--
-- Name: pg_mst_tattachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tattachment (
    pgattachment_gid integer DEFAULT nextval('public.pg_mst_tattachment_pgattachment_gid_seq'::regclass) NOT NULL,
    pg_id public.udd_code NOT NULL,
    doc_type_code public.udd_code NOT NULL,
    doc_subtype_code public.udd_code NOT NULL,
    file_path public.udd_text NOT NULL,
    file_name public.udd_desc NOT NULL,
    attachment_remark public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    original_verified_flag public.udd_flag DEFAULT 'N'::character varying NOT NULL
);


ALTER TABLE public.pg_mst_tattachment OWNER TO postgres;

--
-- Name: pg_mst_tbank; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tbank (
    pgbank_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    bankacc_type_code public.udd_code NOT NULL,
    ifsc_code public.udd_code NOT NULL,
    bank_code public.udd_code NOT NULL,
    bank_name public.udd_desc NOT NULL,
    branch_name public.udd_desc NOT NULL,
    bankacc_no public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tbank OWNER TO postgres;

--
-- Name: pg_mst_tbank_pgbank_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tbank_pgbank_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tbank_pgbank_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tbank_pgbank_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tbank_pgbank_gid_seq OWNED BY public.pg_mst_tbank.pgbank_gid;


--
-- Name: pg_mst_tbomanager; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tbomanager (
    pgbomanager_gid integer DEFAULT nextval('public.pg_mst_tbomanager_pgbomanager_gid_seq'::regclass) NOT NULL,
    pg_id public.udd_code NOT NULL,
    bomanager_id public.udd_code NOT NULL,
    bomanager_name public.udd_desc NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tbomanager OWNER TO postgres;

--
-- Name: pg_mst_tclf; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tclf (
    pgclf_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    clf_id public.udd_code NOT NULL,
    clf_name public.udd_desc NOT NULL,
    clf_officer_id public.udd_code NOT NULL,
    clf_officer_name public.udd_desc NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    tran_status_code public.udd_code
);


ALTER TABLE public.pg_mst_tclf OWNER TO postgres;

--
-- Name: pg_mst_tclf_pgclf_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tclf_pgclf_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tclf_pgclf_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tclf_pgclf_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tclf_pgclf_gid_seq OWNED BY public.pg_mst_tclf.pgclf_gid;


--
-- Name: pg_mst_tcollectionpoint; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tcollectionpoint (
    collpoint_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    collpoint_no public.udd_int NOT NULL,
    collpoint_name public.udd_desc NOT NULL,
    collpoint_ll_name public.udd_desc,
    latitude_code public.udd_code,
    longitude_code public.udd_code,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    collpoint_lang_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL
);


ALTER TABLE public.pg_mst_tcollectionpoint OWNER TO postgres;

--
-- Name: pg_mst_tcollectionpoint_collpoint_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tcollectionpoint_collpoint_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tcollectionpoint_collpoint_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tcollectionpoint_collpoint_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tcollectionpoint_collpoint_gid_seq OWNED BY public.pg_mst_tcollectionpoint.collpoint_gid;


--
-- Name: pg_mst_tfinancesumm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tfinancesumm (
    pgfinsumm_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    till_date public.udd_date NOT NULL,
    cash_in_hand public.udd_amount,
    cash_in_bank public.udd_amount,
    opening_stock_value public.udd_amount,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tfinancesumm OWNER TO postgres;

--
-- Name: pg_mst_tfinancesumm_pgfinsumm_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tfinancesumm_pgfinsumm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tfinancesumm_pgfinsumm_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tfinancesumm_pgfinsumm_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tfinancesumm_pgfinsumm_gid_seq OWNED BY public.pg_mst_tfinancesumm.pgfinsumm_gid;


--
-- Name: pg_mst_tfundsupport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tfundsupport (
    pgfundsupp_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    fund_source_code public.udd_code NOT NULL,
    fund_type_code public.udd_code NOT NULL,
    fund_supp_date public.udd_date NOT NULL,
    fund_supp_amount public.udd_amount NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    purpose_code public.udd_code NOT NULL
);


ALTER TABLE public.pg_mst_tfundsupport OWNER TO postgres;

--
-- Name: pg_mst_tfundsupport_pgfundsupp_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tfundsupport_pgfundsupp_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tfundsupport_pgfundsupp_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tfundsupport_pgfundsupp_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tfundsupport_pgfundsupp_gid_seq OWNED BY public.pg_mst_tfundsupport.pgfundsupp_gid;


--
-- Name: pg_mst_tofficebearers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tofficebearers (
    pgoffbearer_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    offbearer_name public.udd_desc NOT NULL,
    designation_code public.udd_code NOT NULL,
    signatory_code public.udd_code NOT NULL,
    mobile_no public.udd_mobile NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tofficebearers OWNER TO postgres;

--
-- Name: pg_mst_tofficebearers_pgoffbearer_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tofficebearers_pgoffbearer_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tofficebearers_pgoffbearer_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tofficebearers_pgoffbearer_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tofficebearers_pgoffbearer_gid_seq OWNED BY public.pg_mst_tofficebearers.pgoffbearer_gid;


--
-- Name: pg_mst_tpanchayatmapping_pgpanchayatmapping_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpanchayatmapping_pgpanchayatmapping_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpanchayatmapping_pgpanchayatmapping_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpanchayatmapping_pgpanchayatmapping_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpanchayatmapping_pgpanchayatmapping_gid_seq OWNED BY public.pg_mst_tpanchayatmapping.pgpanchayatmapping_gid;


--
-- Name: pg_mst_tpgbuyer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgbuyer (
    pgbuyer_gid public.udd_int,
    pg_id public.udd_code NOT NULL,
    buyer_name public.udd_desc NOT NULL,
    mobile_no public.udd_mobile NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgbuyer OWNER TO postgres;

--
-- Name: pg_mst_tpgmember; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmember (
    pgmember_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    pgmember_type_code public.udd_code NOT NULL,
    pgmember_name public.udd_desc NOT NULL,
    pgmember_ll_name public.udd_desc,
    fatherhusband_name public.udd_desc NOT NULL,
    fatherhusband_ll_name public.udd_desc,
    dob_date date,
    gender_code public.udd_code NOT NULL,
    caste_code public.udd_code NOT NULL,
    mobile_no_active public.udd_mobile NOT NULL,
    mobile_no_alternative public.udd_mobile,
    member_remark public.udd_text,
    shg_id public.udd_code,
    shgmember_id public.udd_code,
    sync_status_code public.udd_code,
    pgmember_photo public.udd_text,
    dbo_available_flag public.udd_flag DEFAULT NULL::character varying,
    age public.udd_int DEFAULT NULL::integer,
    age_ason_date public.udd_date DEFAULT NULL::date,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    pgmember_inactive_code public.udd_code,
    pgmember_stmt_date public.udd_date,
    officebearer_flag public.udd_flag NOT NULL,
    designation_code public.udd_code,
    signatory_code public.udd_code,
    pgmember_clas_code public.udd_code NOT NULL
);


ALTER TABLE public.pg_mst_tpgmember OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberaddress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmemberaddress (
    pgmemberaddress_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    addr_type_code public.udd_code NOT NULL,
    addr_line public.udd_text NOT NULL,
    pin_code public.udd_pincode NOT NULL,
    village_id public.udd_int NOT NULL,
    panchayat_id public.udd_int NOT NULL,
    block_id public.udd_int NOT NULL,
    district_id public.udd_int NOT NULL,
    state_id public.udd_int NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmemberaddress OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberaddress_pgmemberaddress_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmemberaddress_pgmemberaddress_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmemberaddress_pgmemberaddress_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberaddress_pgmemberaddress_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmemberaddress_pgmemberaddress_gid_seq OWNED BY public.pg_mst_tpgmemberaddress.pgmemberaddress_gid;


--
-- Name: pg_mst_tpgmemberasset; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmemberasset (
    pgmemberasset_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    asset_type_code public.udd_code NOT NULL,
    asset_code public.udd_code NOT NULL,
    ownership_type_code public.udd_code NOT NULL,
    asset_count public.udd_int NOT NULL,
    asset_desc public.udd_desc NOT NULL,
    hirer_mfg_name public.udd_desc,
    hirer_mfg_date public.udd_date,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmemberasset OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberasset_pgmemberasset_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmemberasset_pgmemberasset_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmemberasset_pgmemberasset_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberasset_pgmemberasset_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmemberasset_pgmemberasset_gid_seq OWNED BY public.pg_mst_tpgmemberasset.pgmemberasset_gid;


--
-- Name: pg_mst_tpgmemberattachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmemberattachment (
    pgmemberattachment_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    doc_type_code public.udd_code NOT NULL,
    doc_subtype_code public.udd_code NOT NULL,
    file_name public.udd_desc NOT NULL,
    attachment_remark public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    file_path public.udd_text
);


ALTER TABLE public.pg_mst_tpgmemberattachment OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberattachment_pgmemberattachment_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmemberattachment_pgmemberattachment_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmemberattachment_pgmemberattachment_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberattachment_pgmemberattachment_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmemberattachment_pgmemberattachment_gid_seq OWNED BY public.pg_mst_tpgmemberattachment.pgmemberattachment_gid;


--
-- Name: pg_mst_tpgmemberbank; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmemberbank (
    pgmemberbank_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    bankacc_type_code public.udd_code NOT NULL,
    ifsc_code public.udd_code NOT NULL,
    bank_code public.udd_code NOT NULL,
    bank_name public.udd_desc NOT NULL,
    branch_name public.udd_desc NOT NULL,
    bankacc_no public.udd_code NOT NULL,
    primary_flag public.udd_flag NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmemberbank OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberbank_pgmemberbank_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmemberbank_pgmemberbank_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmemberbank_pgmemberbank_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberbank_pgmemberbank_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmemberbank_pgmemberbank_gid_seq OWNED BY public.pg_mst_tpgmemberbank.pgmemberbank_gid;


--
-- Name: pg_mst_tpgmembercrop; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmembercrop (
    pgmembercrop_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    season_type_code public.udd_code NOT NULL,
    crop_type_code public.udd_code NOT NULL,
    crop_code public.udd_code NOT NULL,
    crop_name public.udd_desc NOT NULL,
    sowing_area public.udd_qty NOT NULL,
    pgmemberland_id public.udd_code,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmembercrop OWNER TO postgres;

--
-- Name: pg_mst_tpgmembercrop_pgmembercrop_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmembercrop_pgmembercrop_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmembercrop_pgmembercrop_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmembercrop_pgmembercrop_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmembercrop_pgmembercrop_gid_seq OWNED BY public.pg_mst_tpgmembercrop.pgmembercrop_gid;


--
-- Name: pg_mst_tpgmemberland; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmemberland (
    pgmemberland_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    pgmemberland_id public.udd_code NOT NULL,
    land_type_code public.udd_code NOT NULL,
    ownership_type_code public.udd_code NOT NULL,
    land_size public.udd_qty NOT NULL,
    cropping_area public.udd_qty NOT NULL,
    soil_type_code public.udd_code NOT NULL,
    irrigation_source_code public.udd_code NOT NULL,
    latitude_value public.udd_code,
    longitude_value public.udd_code,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmemberland OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberland_pgmemberland_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmemberland_pgmemberland_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmemberland_pgmemberland_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberland_pgmemberland_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmemberland_pgmemberland_gid_seq OWNED BY public.pg_mst_tpgmemberland.pgmemberland_gid;


--
-- Name: pg_mst_tpgmemberlivestock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmemberlivestock (
    pgmemberlivestock_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    livestock_type_code public.udd_code NOT NULL,
    livestock_code public.udd_code NOT NULL,
    ownership_type_code public.udd_code NOT NULL,
    livestock_qty public.udd_qty NOT NULL,
    livestock_remark public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmemberlivestock OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberlivestock_pgmemberlivestock_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmemberlivestock_pgmemberlivestock_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmemberlivestock_pgmemberlivestock_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberlivestock_pgmemberlivestock_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmemberlivestock_pgmemberlivestock_gid_seq OWNED BY public.pg_mst_tpgmemberlivestock.pgmemberlivestock_gid;


--
-- Name: pg_mst_tpgmembersequence; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmembersequence (
    pgmemberseq_gid integer DEFAULT nextval('public.core_mst_tpgmembersequence_pgmemberseq_gid_seq'::regclass) NOT NULL,
    pg_id public.udd_code NOT NULL,
    next_seq_no public.udd_int NOT NULL,
    sync_status_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmembersequence OWNER TO postgres;

--
-- Name: pg_mst_tpgmembership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tpgmembership (
    pgmembership_gid integer NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    membership_type_code public.udd_code NOT NULL,
    membership_amount public.udd_amount NOT NULL,
    effective_from public.udd_date,
    membership_status_code public.udd_code NOT NULL,
    created_date public.udd_datetime DEFAULT NULL::timestamp without time zone NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tpgmembership OWNER TO postgres;

--
-- Name: pg_mst_tpgmembership_pgmembership_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tpgmembership_pgmembership_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tpgmembership_pgmembership_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tpgmembership_pgmembership_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tpgmembership_pgmembership_gid_seq OWNED BY public.pg_mst_tpgmembership.pgmembership_gid;


--
-- Name: pg_mst_tproducergroup_pg_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tproducergroup_pg_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tproducergroup_pg_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tproducergroup_pg_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tproducergroup_pg_gid_seq OWNED BY public.pg_mst_tproducergroup.pg_gid;


--
-- Name: pg_mst_tproductmapping_pgprodmapp_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tproductmapping_pgprodmapp_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tproductmapping_pgprodmapp_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tproductmapping_pgprodmapp_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tproductmapping_pgprodmapp_gid_seq OWNED BY public.pg_mst_tproductmapping.pgprodmapp_gid;


--
-- Name: pg_mst_tudyogmitra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_mst_tudyogmitra (
    pgudyogmitra_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    udyogmitra_id public.udd_code NOT NULL,
    udyogmitra_name public.udd_desc NOT NULL,
    mobile_no public.udd_mobile NOT NULL,
    token_no public.udd_code,
    tran_status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    pgmember_type_code public.udd_code DEFAULT NULL::character varying,
    fatherhusband_name public.udd_desc DEFAULT NULL::character varying,
    village_id public.udd_int DEFAULT 0 NOT NULL,
    shgmember_relation_code public.udd_code,
    shgmember_id public.udd_code,
    shgmember_name public.udd_desc,
    shgmember_mobile_no public.udd_mobile
);


ALTER TABLE public.pg_mst_tudyogmitra OWNER TO postgres;

--
-- Name: pg_mst_tudyogmitra_pgudyogmitra_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_mst_tudyogmitra_pgudyogmitra_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tudyogmitra_pgudyogmitra_gid_seq OWNER TO postgres;

--
-- Name: pg_mst_tudyogmitra_pgudyogmitra_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_mst_tudyogmitra_pgudyogmitra_gid_seq OWNED BY public.pg_mst_tudyogmitra.pgudyogmitra_gid;


--
-- Name: pg_mst_tvillagemapping; Type: TABLE; Schema: public; Owner: flexi
--

CREATE TABLE public.pg_mst_tvillagemapping (
    pgvillagemapping_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    state_id public.udd_int NOT NULL,
    district_id public.udd_int NOT NULL,
    block_id public.udd_int NOT NULL,
    panchayat_id public.udd_int NOT NULL,
    village_id public.udd_int NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_mst_tvillagemapping OWNER TO flexi;

--
-- Name: pg_mst_tvillagemapping_pgvillagemapping_gid_seq; Type: SEQUENCE; Schema: public; Owner: flexi
--

CREATE SEQUENCE public.pg_mst_tvillagemapping_pgvillagemapping_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_mst_tvillagemapping_pgvillagemapping_gid_seq OWNER TO flexi;

--
-- Name: pg_mst_tvillagemapping_pgvillagemapping_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: flexi
--

ALTER SEQUENCE public.pg_mst_tvillagemapping_pgvillagemapping_gid_seq OWNED BY public.pg_mst_tvillagemapping.pgvillagemapping_gid;


--
-- Name: pg_trn_tbussplan_bussplan_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tbussplan_bussplan_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tbussplan_bussplan_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tbussplan_bussplan_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tbussplan_bussplan_gid_seq OWNED BY public.pg_trn_tbussplan.bussplan_gid;


--
-- Name: pg_trn_tbussplanattachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tbussplanattachment (
    bussplanattachment_gid integer DEFAULT nextval('public.pg_trn_tbussplanattachment_bussplanattachment_gid_seq'::regclass) NOT NULL,
    pg_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    doc_type_code public.udd_code NOT NULL,
    doc_subtype_code public.udd_code NOT NULL,
    file_path public.udd_text NOT NULL,
    file_name public.udd_desc NOT NULL,
    attachment_remark public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tbussplanattachment OWNER TO postgres;

--
-- Name: pg_trn_tbussplandownloadlog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tbussplandownloadlog (
    bussplandownloadlog_gid integer NOT NULL,
    bussplanattachment_gid public.udd_int,
    pg_id public.udd_code,
    bussplan_id public.udd_code NOT NULL,
    downloaded_date public.udd_datetime NOT NULL,
    downloaded_by public.udd_code NOT NULL
);


ALTER TABLE public.pg_trn_tbussplandownloadlog OWNER TO postgres;

--
-- Name: pg_trn_tbussplandownloadlog_bussplandownloadlog_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tbussplandownloadlog_bussplandownloadlog_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tbussplandownloadlog_bussplandownloadlog_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tbussplandownloadlog_bussplandownloadlog_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tbussplandownloadlog_bussplandownloadlog_gid_seq OWNED BY public.pg_trn_tbussplandownloadlog.bussplandownloadlog_gid;


--
-- Name: pg_trn_tbussplanexpenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tbussplanexpenses (
    bussplanexpenses_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    finyear_id public.udd_code NOT NULL,
    operating_expenses public.udd_amount NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tbussplanexpenses OWNER TO postgres;

--
-- Name: pg_trn_tbussplanexpenses_bussplanexpenses_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tbussplanexpenses_bussplanexpenses_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tbussplanexpenses_bussplanexpenses_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tbussplanexpenses_bussplanexpenses_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tbussplanexpenses_bussplanexpenses_gid_seq OWNED BY public.pg_trn_tbussplanexpenses.bussplanexpenses_gid;


--
-- Name: pg_trn_tbussplanfinyear_bussplancalender_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tbussplanfinyear_bussplancalender_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tbussplanfinyear_bussplancalender_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tbussplanfinyear_bussplancalender_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tbussplanfinyear_bussplancalender_gid_seq OWNED BY public.pg_trn_tbussplanfinyear.bussplancalender_gid;


--
-- Name: pg_trn_tbussplanproduce_bussplanproduce_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tbussplanproduce_bussplanproduce_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tbussplanproduce_bussplanproduce_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tbussplanproduce_bussplanproduce_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tbussplanproduce_bussplanproduce_gid_seq OWNED BY public.pg_trn_tbussplanproduce.bussplanproduce_gid;


--
-- Name: pg_trn_tbussplanproduct_bussplanprod_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tbussplanproduct_bussplanprod_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tbussplanproduct_bussplanprod_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tbussplanproduct_bussplanprod_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tbussplanproduct_bussplanprod_gid_seq OWNED BY public.pg_trn_tbussplanproduct.bussplanprod_gid;


--
-- Name: pg_trn_tfunddisbtranche; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tfunddisbtranche (
    funddisbtranche_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    funddisb_id public.udd_code NOT NULL,
    tranche_no public.udd_int NOT NULL,
    tranche_amount public.udd_amount NOT NULL,
    tranche_date public.udd_date NOT NULL,
    tranche_status_code public.udd_code NOT NULL,
    received_date public.udd_date,
    received_ref_no public.udd_code,
    sync_status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tfunddisbtranche OWNER TO postgres;

--
-- Name: pg_trn_tincomeexpense; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tincomeexpense (
    incomeexpense_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    acchead_type_code public.udd_code NOT NULL,
    acchead_code public.udd_code NOT NULL,
    tran_date public.udd_date NOT NULL,
    dr_amount public.udd_amount NOT NULL,
    cr_amount public.udd_amount NOT NULL,
    narration_code public.udd_code NOT NULL,
    tran_ref_no public.udd_text,
    tran_remark public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    pay_mode_code public.udd_code DEFAULT NULL::character varying
);


ALTER TABLE public.pg_trn_tincomeexpense OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberledger; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmemberledger (
    pgmemberledger_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    acchead_code public.udd_code NOT NULL,
    tran_date public.udd_datetime NOT NULL,
    dr_amount public.udd_amount NOT NULL,
    cr_amount public.udd_amount NOT NULL,
    tran_narration public.udd_text NOT NULL,
    tran_ref_no public.udd_text NOT NULL,
    tran_remark public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    payment_process_flag public.udd_flag DEFAULT 'N'::character varying NOT NULL,
    paid_date public.udd_datetime,
    paymode_code public.udd_code
);


ALTER TABLE public.pg_trn_tpgmemberledger OWNER TO postgres;

--
-- Name: pg_trn_tprocurecost; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tprocurecost (
    proccost_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    proc_date public.udd_date NOT NULL,
    tran_datetime public.udd_datetime NOT NULL,
    package_cost public.udd_amount,
    loading_unloading_cost public.udd_amount,
    transport_cost public.udd_amount,
    other_cost public.udd_amount,
    proccost_remark public.udd_text,
    sync_status_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    payment_calc_flag public.udd_code DEFAULT 'N'::character varying NOT NULL,
    paymentcalc_date public.udd_datetime
);


ALTER TABLE public.pg_trn_tprocurecost OWNER TO postgres;

--
-- Name: pg_trn_tsale; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tsale (
    sale_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    inv_date public.udd_date NOT NULL,
    inv_no public.udd_code NOT NULL,
    buyer_name public.udd_desc NOT NULL,
    collected_amount public.udd_amount,
    sync_status_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    buyer_regular_flag public.udd_code DEFAULT 'N'::character varying NOT NULL,
    buyer_mobile_no public.udd_mobile,
    inv_amount public.udd_amount NOT NULL
);


ALTER TABLE public.pg_trn_tsale OWNER TO postgres;

--
-- Name: pg_trn_tsaleproduct; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tsaleproduct (
    saleprod_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    inv_date public.udd_date NOT NULL,
    inv_no public.udd_code NOT NULL,
    rec_slno public.udd_int NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    sale_rate public.udd_rate NOT NULL,
    sale_qty public.udd_qty NOT NULL,
    sale_base_amount public.udd_amount NOT NULL,
    hsn_code public.udd_code,
    cgst_rate public.udd_rate,
    sgst_rate public.udd_rate,
    cgst_amount public.udd_amount,
    sgst_amount public.udd_amount,
    sale_amount public.udd_amount NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    payment_calc_flag public.udd_flag DEFAULT 'N'::character varying NOT NULL,
    sale_remark public.udd_text,
    paymentcalc_date public.udd_datetime,
    status_code public.udd_code DEFAULT 'A'::character varying NOT NULL,
    stock_adj_flag public.udd_flag DEFAULT 'Y'::character varying NOT NULL,
    inv_qty public.udd_qty NOT NULL,
    adjust_type_code public.udd_code,
    adjust_date public.udd_date
);


ALTER TABLE public.pg_trn_tsaleproduct OWNER TO postgres;

--
-- Name: pg_trn_tcollection; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tcollection (
    coll_gid integer DEFAULT nextval('public.pg_trn_tcollection_coll_gid_seq'::regclass) NOT NULL,
    pg_id public.udd_code NOT NULL,
    coll_no public.udd_int NOT NULL,
    coll_date public.udd_date NOT NULL,
    coll_amount public.udd_amount NOT NULL,
    pay_mode_code public.udd_code NOT NULL,
    pay_ref_no public.udd_desc,
    inv_no public.udd_code NOT NULL,
    coll_remark public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tcollection OWNER TO postgres;

--
-- Name: pg_trn_texcplog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_texcplog (
    excplog_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    role_code public.udd_code NOT NULL,
    user_code public.udd_code NOT NULL,
    mobile_no public.udd_mobile NOT NULL,
    excp_date public.udd_datetime,
    excp_from public.udd_code NOT NULL,
    excp_code public.udd_code NOT NULL,
    excp_text public.udd_text NOT NULL
);


ALTER TABLE public.pg_trn_texcplog OWNER TO postgres;

--
-- Name: pg_trn_texcplog_excplog_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_texcplog_excplog_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_texcplog_excplog_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_texcplog_excplog_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_texcplog_excplog_gid_seq OWNED BY public.pg_trn_texcplog.excplog_gid;


--
-- Name: pg_trn_tfunddisbtranche_funddisbtranche_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tfunddisbtranche_funddisbtranche_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tfunddisbtranche_funddisbtranche_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tfunddisbtranche_funddisbtranche_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tfunddisbtranche_funddisbtranche_gid_seq OWNED BY public.pg_trn_tfunddisbtranche.funddisbtranche_gid;


--
-- Name: pg_trn_tfunddisbursement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tfunddisbursement (
    funddisb_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    fundreq_id public.udd_code,
    funddisb_id public.udd_code NOT NULL,
    loan_acc_no public.udd_code,
    routing_inst_code public.udd_code NOT NULL,
    source_inst_code public.udd_code NOT NULL,
    funddisb_type_code public.udd_code NOT NULL,
    sanctioned_date public.udd_date NOT NULL,
    sanctioned_amount public.udd_amount NOT NULL,
    interest_rate public.udd_rate NOT NULL,
    repymt_tenure public.udd_numeric NOT NULL,
    repymt_freq_code public.udd_code,
    collateral_type_code public.udd_code,
    collateral_amount public.udd_amount,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    row_timestamp public.udd_datetime NOT NULL
);


ALTER TABLE public.pg_trn_tfunddisbursement OWNER TO postgres;

--
-- Name: pg_trn_tfunddisbursement_funddisb_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tfunddisbursement_funddisb_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tfunddisbursement_funddisb_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tfunddisbursement_funddisb_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tfunddisbursement_funddisb_gid_seq OWNED BY public.pg_trn_tfunddisbursement.funddisb_gid;


--
-- Name: pg_trn_tfundrepymt_fundrepymt_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tfundrepymt_fundrepymt_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tfundrepymt_fundrepymt_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tfundrepymt_fundrepymt_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tfundrepymt_fundrepymt_gid_seq OWNED BY public.pg_trn_tfundrepymt.fundrepymt_gid;


--
-- Name: pg_trn_tfundreqattachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tfundreqattachment (
    fundreqattachment_gid integer DEFAULT nextval('public.pg_trn_tfundreqattachment_fundreqattachment_gid_seq'::regclass) NOT NULL,
    pg_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    fundreq_id public.udd_code NOT NULL,
    doc_type_code public.udd_code NOT NULL,
    doc_subtype_code public.udd_code NOT NULL,
    file_path public.udd_text NOT NULL,
    file_name public.udd_desc NOT NULL,
    attachment_remark public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tfundreqattachment OWNER TO postgres;

--
-- Name: pg_trn_tfundrequisition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tfundrequisition (
    fundreq_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    blockofficer_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    fundreq_id public.udd_code NOT NULL,
    tot_fundreq_amount public.udd_amount NOT NULL,
    reviewer_type_code public.udd_code NOT NULL,
    clf_block_id public.udd_int NOT NULL,
    reviewer_code public.udd_code NOT NULL,
    fundreq_remark public.udd_text,
    last_action_date public.udd_datetime NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    row_timestamp public.udd_datetime NOT NULL,
    fundreq_purpose public.udd_text,
    reviewer_name public.udd_desc DEFAULT NULL::character varying
);


ALTER TABLE public.pg_trn_tfundrequisition OWNER TO postgres;

--
-- Name: pg_trn_tfundrequisition_fundreq_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tfundrequisition_fundreq_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tfundrequisition_fundreq_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tfundrequisition_fundreq_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tfundrequisition_fundreq_gid_seq OWNED BY public.pg_trn_tfundrequisition.fundreq_gid;


--
-- Name: pg_trn_tfundrequisitiondtl; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tfundrequisitiondtl (
    fundreq_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    blockofficer_id public.udd_code NOT NULL,
    bussplan_id public.udd_code NOT NULL,
    fundreq_id public.udd_code NOT NULL,
    routing_inst_code public.udd_code NOT NULL,
    fundreq_head_code public.udd_code NOT NULL,
    fundreq_amount public.udd_amount NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tfundrequisitiondtl OWNER TO postgres;

--
-- Name: pg_trn_tfundrequisitiondtl_fundreq_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tfundrequisitiondtl_fundreq_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tfundrequisitiondtl_fundreq_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tfundrequisitiondtl_fundreq_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tfundrequisitiondtl_fundreq_gid_seq OWNED BY public.pg_trn_tfundrequisitiondtl.fundreq_gid;


--
-- Name: pg_trn_thonorarium; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_thonorarium (
    honorarium_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    udyogmitra_id public.udd_code NOT NULL,
    record_date public.udd_date NOT NULL,
    period_from public.udd_date NOT NULL,
    period_to public.udd_date NOT NULL,
    honorarium_amount public.udd_amount NOT NULL,
    honorarium_remark public.udd_text NOT NULL,
    sync_status_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_thonorarium OWNER TO postgres;

--
-- Name: pg_trn_thonorarium_honorarium_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_thonorarium_honorarium_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_thonorarium_honorarium_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_thonorarium_honorarium_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_thonorarium_honorarium_gid_seq OWNED BY public.pg_trn_thonorarium.honorarium_gid;


--
-- Name: pg_trn_tincomeexpense_incomeexpense_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tincomeexpense_incomeexpense_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tincomeexpense_incomeexpense_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tincomeexpense_incomeexpense_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tincomeexpense_incomeexpense_gid_seq OWNED BY public.pg_trn_tincomeexpense.incomeexpense_gid;


--
-- Name: pg_trn_tloginhistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tloginhistory (
    loginhistory_gid integer DEFAULT nextval('public.pg_trn_tloginhistory_loginhistory_gid_seq'::regclass) NOT NULL,
    user_code public.udd_code NOT NULL,
    ip_address public.udd_desc NOT NULL,
    login_date public.udd_datetime NOT NULL,
    login_mode public.udd_code NOT NULL,
    login_status public.udd_code NOT NULL
);


ALTER TABLE public.pg_trn_tloginhistory OWNER TO postgres;

--
-- Name: pg_trn_tpgfund; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgfund (
    pgfund_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgfund_code public.udd_code NOT NULL,
    pgfund_date public.udd_date NOT NULL,
    pgfund_source_code public.udd_code NOT NULL,
    pgfund_amount public.udd_amount NOT NULL,
    pgfund_available_amount public.udd_amount NOT NULL,
    pgfund_remark public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tpgfund OWNER TO postgres;

--
-- Name: pg_trn_tpgfund_pgfund_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgfund_pgfund_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgfund_pgfund_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgfund_pgfund_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgfund_pgfund_gid_seq OWNED BY public.pg_trn_tpgfund.pgfund_gid;


--
-- Name: pg_trn_tpgfundexpenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgfundexpenses (
    pgfundexp_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgfund_code public.udd_code NOT NULL,
    expense_head_code public.udd_code NOT NULL,
    expense_date public.udd_date NOT NULL,
    expense_amount public.udd_amount NOT NULL,
    recovery_flag public.udd_flag NOT NULL,
    recovered_flag public.udd_flag NOT NULL,
    beneficiary_name public.udd_desc NOT NULL,
    expense_remark public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tpgfundexpenses OWNER TO postgres;

--
-- Name: pg_trn_tpgfundexpenses_pgfundexp_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgfundexpenses_pgfundexp_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgfundexpenses_pgfundexp_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgfundexpenses_pgfundexp_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgfundexpenses_pgfundexp_gid_seq OWNED BY public.pg_trn_tpgfundexpenses.pgfundexp_gid;


--
-- Name: pg_trn_tpgfundledger; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgfundledger (
    pgfundledger_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgfund_code public.udd_code NOT NULL,
    pgfund_trantype_code public.udd_code NOT NULL,
    pgfund_ledger_code public.udd_code NOT NULL,
    tran_date public.udd_date NOT NULL,
    dr_amount public.udd_amount DEFAULT 0 NOT NULL,
    cr_amount public.udd_amount DEFAULT 0 NOT NULL,
    recovery_flag public.udd_flag DEFAULT 'N'::character varying NOT NULL,
    recovered_flag public.udd_flag DEFAULT 'N'::character varying NOT NULL,
    beneficiary_name public.udd_desc,
    pgfund_remark public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    payment_calc_flag public.udd_code DEFAULT 'N'::character varying NOT NULL,
    paymentcalc_date public.udd_datetime DEFAULT NULL::timestamp without time zone
);


ALTER TABLE public.pg_trn_tpgfundledger OWNER TO postgres;

--
-- Name: pg_trn_tpgfundledger_pgfundledger_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgfundledger_pgfundledger_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgfundledger_pgfundledger_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgfundledger_pgfundledger_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgfundledger_pgfundledger_gid_seq OWNED BY public.pg_trn_tpgfundledger.pgfundledger_gid;


--
-- Name: pg_trn_tpgfundledgersumm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgfundledgersumm (
    pgfundledgersumm_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgfund_code public.udd_code NOT NULL,
    dr_amount public.udd_amount NOT NULL,
    cr_amount public.udd_amount NOT NULL,
    as_of_date public.udd_date NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tpgfundledgersumm OWNER TO postgres;

--
-- Name: pg_trn_tpgfundledgersumm_pgfundledgersumm_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgfundledgersumm_pgfundledgersumm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgfundledgersumm_pgfundledgersumm_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgfundledgersumm_pgfundledgersumm_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgfundledgersumm_pgfundledgersumm_gid_seq OWNED BY public.pg_trn_tpgfundledgersumm.pgfundledgersumm_gid;


--
-- Name: pg_trn_tpgmembercommcalc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmembercommcalc (
    pgmembercommcalc_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    paymentcalc_date public.udd_datetime NOT NULL,
    comm_date public.udd_date NOT NULL,
    dr_amount public.udd_amount NOT NULL,
    cr_amount public.udd_amount NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    ledger_tran_flag public.udd_code DEFAULT 'N'::character varying NOT NULL,
    tran_date public.udd_datetime
);


ALTER TABLE public.pg_trn_tpgmembercommcalc OWNER TO postgres;

--
-- Name: pg_trn_tpgmembercommcalc_pgmembercommcalc_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmembercommcalc_pgmembercommcalc_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmembercommcalc_pgmembercommcalc_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmembercommcalc_pgmembercommcalc_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmembercommcalc_pgmembercommcalc_gid_seq OWNED BY public.pg_trn_tpgmembercommcalc.pgmembercommcalc_gid;


--
-- Name: pg_trn_tpgmembercommcalcdtl; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmembercommcalcdtl (
    pgmembercommcalcdtl_gid integer NOT NULL,
    pgmembercommcalc_gid public.udd_int NOT NULL,
    pgmembersalecalc_gid public.udd_int NOT NULL
);


ALTER TABLE public.pg_trn_tpgmembercommcalcdtl OWNER TO postgres;

--
-- Name: pg_trn_tpgmembercommcalcdtl_pgmembercommcalcdtl_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmembercommcalcdtl_pgmembercommcalcdtl_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmembercommcalcdtl_pgmembercommcalcdtl_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmembercommcalcdtl_pgmembercommcalcdtl_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmembercommcalcdtl_pgmembercommcalcdtl_gid_seq OWNED BY public.pg_trn_tpgmembercommcalcdtl.pgmembercommcalcdtl_gid;


--
-- Name: pg_trn_tpgmemberledger_pgmemberledger_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberledger_pgmemberledger_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberledger_pgmemberledger_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberledger_pgmemberledger_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberledger_pgmemberledger_gid_seq OWNED BY public.pg_trn_tpgmemberledger.pgmemberledger_gid;


--
-- Name: pg_trn_tpgmemberledgersumm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmemberledgersumm (
    pgmemberledgersumm_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    dr_amount public.udd_amount NOT NULL,
    cr_amount public.udd_amount NOT NULL,
    as_of_date public.udd_datetime NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tpgmemberledgersumm OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberledgersumm_pgmemberledgersumm_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberledgersumm_pgmemberledgersumm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberledgersumm_pgmemberledgersumm_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberledgersumm_pgmemberledgersumm_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberledgersumm_pgmemberledgersumm_gid_seq OWNED BY public.pg_trn_tpgmemberledgersumm.pgmemberledgersumm_gid;


--
-- Name: pg_trn_tpgmemberpayment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmemberpayment (
    pgmemberpymt_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    paid_date public.udd_date NOT NULL,
    period_from public.udd_date,
    period_to public.udd_date,
    paymode_code public.udd_code NOT NULL,
    paid_amount public.udd_amount NOT NULL,
    pymt_ref_no public.udd_code NOT NULL,
    pymt_remark public.udd_text,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tpgmemberpayment OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberpayment_pgmemberpymt_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberpayment_pgmemberpymt_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberpayment_pgmemberpymt_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberpayment_pgmemberpymt_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberpayment_pgmemberpymt_gid_seq OWNED BY public.pg_trn_tpgmemberpayment.pgmemberpymt_gid;


--
-- Name: pg_trn_tpgmembersalecalc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmembersalecalc (
    pgmembersalecalc_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    paymentcalc_date public.udd_datetime NOT NULL,
    sale_date public.udd_date NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    calc_source_code public.udd_code NOT NULL,
    calc_applied_qty public.udd_qty NOT NULL,
    stock_qty public.udd_qty NOT NULL,
    dr_amount public.udd_amount NOT NULL,
    cr_amount public.udd_amount NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    ledger_tran_flag public.udd_flag DEFAULT 'N'::character varying NOT NULL,
    tran_date public.udd_datetime
);


ALTER TABLE public.pg_trn_tpgmembersalecalc OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberpaymentcalc_pgmembercalc_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberpaymentcalc_pgmembercalc_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberpaymentcalc_pgmembercalc_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberpaymentcalc_pgmembercalc_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberpaymentcalc_pgmembercalc_gid_seq OWNED BY public.pg_trn_tpgmembersalecalc.pgmembersalecalc_gid;


--
-- Name: pg_trn_tpgmemberproccostcalc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmemberproccostcalc (
    pgmemberproccostcalc_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    paymentcalc_date public.udd_datetime NOT NULL,
    proc_date public.udd_date NOT NULL,
    dr_amount public.udd_amount NOT NULL,
    cr_amount public.udd_amount NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    ledger_tran_flag public.udd_code DEFAULT 'N'::character varying NOT NULL,
    tran_date public.udd_datetime
);


ALTER TABLE public.pg_trn_tpgmemberproccostcalc OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberproccostcalc_pgmemberproccostcalc_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberproccostcalc_pgmemberproccostcalc_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberproccostcalc_pgmemberproccostcalc_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberproccostcalc_pgmemberproccostcalc_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberproccostcalc_pgmemberproccostcalc_gid_seq OWNED BY public.pg_trn_tpgmemberproccostcalc.pgmemberproccostcalc_gid;


--
-- Name: pg_trn_tpgmemberproccostcalcdtl; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmemberproccostcalcdtl (
    pgmemberproccostcalcdtl_gid integer NOT NULL,
    pgmemberproccostcalc_gid public.udd_int NOT NULL,
    pgmembersalecalc_gid public.udd_int NOT NULL
);


ALTER TABLE public.pg_trn_tpgmemberproccostcalcdtl OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberproccostcalcdtl_pgmemberproccostcalcdtl_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberproccostcalcdtl_pgmemberproccostcalcdtl_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberproccostcalcdtl_pgmemberproccostcalcdtl_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberproccostcalcdtl_pgmemberproccostcalcdtl_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberproccostcalcdtl_pgmemberproccostcalcdtl_gid_seq OWNED BY public.pg_trn_tpgmemberproccostcalcdtl.pgmemberproccostcalcdtl_gid;


--
-- Name: pg_trn_tpgmemberstock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmemberstock (
    pgmemberstock_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    uom_code public.udd_code,
    proc_qty public.udd_qty NOT NULL,
    sale_qty public.udd_qty NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tpgmemberstock OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberstock_pgmemberstock_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberstock_pgmemberstock_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberstock_pgmemberstock_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberstock_pgmemberstock_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberstock_pgmemberstock_gid_seq OWNED BY public.pg_trn_tpgmemberstock.pgmemberstock_gid;


--
-- Name: pg_trn_tpgmemberstockbydate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tpgmemberstockbydate (
    pgmemberstockbydate_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    uom_code public.udd_code,
    stock_date public.udd_date NOT NULL,
    opening_qty public.udd_qty NOT NULL,
    proc_qty public.udd_qty NOT NULL,
    sale_qty public.udd_qty NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tpgmemberstockbydate OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberstockbydate_pgmemberstockbydate_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tpgmemberstockbydate_pgmemberstockbydate_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tpgmemberstockbydate_pgmemberstockbydate_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tpgmemberstockbydate_pgmemberstockbydate_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tpgmemberstockbydate_pgmemberstockbydate_gid_seq OWNED BY public.pg_trn_tpgmemberstockbydate.pgmemberstockbydate_gid;


--
-- Name: pg_trn_tprocure; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tprocure (
    proc_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    session_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    proc_date public.udd_date NOT NULL,
    advance_amount public.udd_amount,
    sync_status_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tprocure OWNER TO postgres;

--
-- Name: pg_trn_tprocurecostproduct; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tprocurecostproduct (
    proccostprod_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    tran_datetime public.udd_datetime NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    uom_code public.udd_code NOT NULL,
    prod_qty public.udd_qty NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tprocurecostproduct OWNER TO postgres;

--
-- Name: pg_trn_tprocureproduct; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tprocureproduct (
    procprod_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    session_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    rec_slno public.udd_int NOT NULL,
    proc_date public.udd_date NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    proc_rate public.udd_rate,
    proc_qty public.udd_qty NOT NULL,
    uom_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    proc_remark public.udd_text,
    status_code public.udd_code DEFAULT 'A'::character varying NOT NULL
);


ALTER TABLE public.pg_trn_tprocureproduct OWNER TO postgres;

--
-- Name: pg_trn_tprocureproductqlty; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tprocureproductqlty (
    procprodqlty_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    session_id public.udd_code NOT NULL,
    pgmember_id public.udd_code NOT NULL,
    rec_slno public.udd_int NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    qltyparam_code public.udd_code NOT NULL,
    qltyuom_code public.udd_code NOT NULL,
    actual_value public.udd_desc,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tprocureproductqlty OWNER TO postgres;

--
-- Name: pg_trn_tproductstock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tproductstock (
    prodstock_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    uom_code public.udd_code,
    stock_date public.udd_date,
    opening_qty public.udd_qty DEFAULT 0 NOT NULL,
    proc_qty public.udd_qty DEFAULT 0 NOT NULL,
    sale_qty public.udd_qty DEFAULT 0 NOT NULL,
    stock_qty public.udd_qty NOT NULL,
    sync_status_code public.udd_code DEFAULT 'N'::character varying NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tproductstock OWNER TO postgres;

--
-- Name: pg_trn_tproductstock_prodstock_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tproductstock_prodstock_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tproductstock_prodstock_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tproductstock_prodstock_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tproductstock_prodstock_gid_seq OWNED BY public.pg_trn_tproductstock.prodstock_gid;


--
-- Name: pg_trn_tproductstockbydate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tproductstockbydate (
    prodstockbydate_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    uom_code public.udd_code,
    stock_date public.udd_date NOT NULL,
    opening_qty public.udd_qty NOT NULL,
    proc_qty public.udd_qty,
    sale_qty public.udd_qty,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tproductstockbydate OWNER TO postgres;

--
-- Name: pg_trn_tproductstockbydate_prodstockbydate_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tproductstockbydate_prodstockbydate_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tproductstockbydate_prodstockbydate_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tproductstockbydate_prodstockbydate_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tproductstockbydate_prodstockbydate_gid_seq OWNED BY public.pg_trn_tproductstockbydate.prodstockbydate_gid;


--
-- Name: pg_trn_tsalecalc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tsalecalc (
    salecalc_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    paymentcalc_date public.udd_datetime NOT NULL,
    sale_date public.udd_date NOT NULL,
    prod_type_code public.udd_code NOT NULL,
    prod_code public.udd_code NOT NULL,
    grade_code public.udd_code NOT NULL,
    sale_qty public.udd_qty NOT NULL,
    stock_qty public.udd_qty NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tsalecalc OWNER TO postgres;

--
-- Name: pg_trn_tsalecalc_salecalc_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tsalecalc_salecalc_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tsalecalc_salecalc_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tsalecalc_salecalc_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tsalecalc_salecalc_gid_seq OWNED BY public.pg_trn_tsalecalc.salecalc_gid;


--
-- Name: pg_trn_tsession; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tsession (
    session_gid public.udd_int NOT NULL,
    pg_id public.udd_code NOT NULL,
    session_id public.udd_code NOT NULL,
    session_date public.udd_date,
    collpoint_no public.udd_int,
    latitude_code public.udd_code,
    longitude_code public.udd_code,
    start_timestamp public.udd_datetime,
    end_timestamp public.udd_datetime,
    sync_status_code public.udd_code,
    status_code public.udd_code,
    created_date public.udd_datetime,
    created_by public.udd_user,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tsession OWNER TO postgres;

--
-- Name: pg_trn_tsmstran; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tsmstran (
    smstran_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    smstemplate_code public.udd_code NOT NULL,
    dlt_template_id public.udd_code NOT NULL,
    mobile_no public.udd_mobile NOT NULL,
    sms_text public.udd_text NOT NULL,
    scheduled_date public.udd_datetime NOT NULL,
    sms_delivered_flag public.udd_flag NOT NULL,
    user_code public.udd_code NOT NULL,
    role_code public.udd_code NOT NULL,
    status_code public.udd_code NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user,
    sms_remark public.udd_text
);


ALTER TABLE public.pg_trn_tsmstran OWNER TO postgres;

--
-- Name: pg_trn_tsmstran_smstran_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tsmstran_smstran_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tsmstran_smstran_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tsmstran_smstran_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tsmstran_smstran_gid_seq OWNED BY public.pg_trn_tsmstran.smstran_gid;


--
-- Name: pg_trn_tsqliteattachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pg_trn_tsqliteattachment (
    sqliteattachment_gid integer NOT NULL,
    pg_id public.udd_code NOT NULL,
    role_code public.udd_code NOT NULL,
    user_code public.udd_code NOT NULL,
    mobile_no public.udd_mobile NOT NULL,
    created_date public.udd_datetime NOT NULL,
    created_by public.udd_user NOT NULL,
    updated_date public.udd_datetime,
    updated_by public.udd_user
);


ALTER TABLE public.pg_trn_tsqliteattachment OWNER TO postgres;

--
-- Name: pg_trn_tsqliteattachment_sqliteattachment_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pg_trn_tsqliteattachment_sqliteattachment_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pg_trn_tsqliteattachment_sqliteattachment_gid_seq OWNER TO postgres;

--
-- Name: pg_trn_tsqliteattachment_sqliteattachment_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pg_trn_tsqliteattachment_sqliteattachment_gid_seq OWNED BY public.pg_trn_tsqliteattachment.sqliteattachment_gid;


--
-- Name: shg_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shg_profile (
    shg_id integer NOT NULL,
    state_id integer NOT NULL,
    district_id integer NOT NULL,
    block_id integer NOT NULL,
    panchayat_id integer NOT NULL,
    village_id integer NOT NULL,
    shg_code character varying(22),
    shg_name character varying(80) NOT NULL,
    shg_type_code smallint,
    language_id character varying(2),
    shg_name_local character varying(120),
    parent_cbo_code bigint,
    parent_cbo_type smallint,
    is_active boolean DEFAULT true NOT NULL,
    activation_status smallint,
    uploaded_by character varying(100),
    status smallint,
    promoter_code character varying(5),
    cbo_type smallint DEFAULT '0'::smallint NOT NULL,
    created_date timestamp without time zone,
    updated_date timestamp without time zone
);


ALTER TABLE public.shg_profile OWNER TO postgres;

--
-- Name: state_master_state_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.state_master_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.state_master_state_id_seq OWNER TO postgres;

--
-- Name: state_master_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.state_master_state_id_seq OWNED BY public.state_master.state_id;


--
-- Name: village_master_copy_village_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.village_master_copy_village_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.village_master_copy_village_id_seq OWNER TO postgres;

--
-- Name: village_master_copy_village_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.village_master_copy_village_id_seq OWNED BY public.village_master.village_id;


--
-- Name: bank_branch_master bank_branch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_branch_master ALTER COLUMN bank_branch_id SET DEFAULT nextval('public.bank_branch_master_copy_bank_branch_id_seq'::regclass);


--
-- Name: bank_master bank_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_master ALTER COLUMN bank_id SET DEFAULT nextval('public.bank_master_bank_id_seq'::regclass);


--
-- Name: block_master block_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.block_master ALTER COLUMN block_id SET DEFAULT nextval('public.block_master_copy_block_id_seq'::regclass);


--
-- Name: cbo_mapping_details cbo_mapping_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cbo_mapping_details ALTER COLUMN cbo_mapping_id SET DEFAULT nextval('public.cbo_mapping_details_cbo_mapping_id_seq'::regclass);


--
-- Name: core_mst_tconfig config_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tconfig ALTER COLUMN config_gid SET DEFAULT nextval('public.core_mst_tconfig_config_gid_seq'::regclass);


--
-- Name: core_mst_tdocnum docnum_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tdocnum ALTER COLUMN docnum_gid SET DEFAULT nextval('public.core_mst_tdocnum_docnum_gid_seq'::regclass);


--
-- Name: core_mst_tfinyear finyear_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tfinyear ALTER COLUMN finyear_gid SET DEFAULT nextval('public.core_mst_tfinyear_finyear_gid_seq'::regclass);


--
-- Name: core_mst_tifsc ifsc_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tifsc ALTER COLUMN ifsc_gid SET DEFAULT nextval('public.core_mst_tifsc_ifsc_gid_seq'::regclass);


--
-- Name: core_mst_tinterfaceurl ifaceurl_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tinterfaceurl ALTER COLUMN ifaceurl_gid SET DEFAULT nextval('public.core_mst_tinterfaceurl_ifaceurl_gid_seq'::regclass);


--
-- Name: core_mst_tlanguage lang_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tlanguage ALTER COLUMN lang_gid SET DEFAULT nextval('public.core_mst_tlanguage_lang_gid_seq'::regclass);


--
-- Name: core_mst_tlokossyncqry lokossyncqry_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tlokossyncqry ALTER COLUMN lokossyncqry_gid SET DEFAULT nextval('public.core_mst_tlokossyncqry_lokossyncqry_gid_seq'::regclass);


--
-- Name: core_mst_tmaster master_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmaster ALTER COLUMN master_gid SET DEFAULT nextval('public.core_mst_tmaster_master_gid_seq'::regclass);


--
-- Name: core_mst_tmastertranslate mastertranslate_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmastertranslate ALTER COLUMN mastertranslate_gid SET DEFAULT nextval('public.core_mst_tmastertranslate_mastertranslate_gid_seq'::regclass);


--
-- Name: core_mst_tmenu menu_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmenu ALTER COLUMN menu_gid SET DEFAULT nextval('public.core_mst_tmenu_menu_gid_seq'::regclass);


--
-- Name: core_mst_tmenutranslate menutranslate_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmenutranslate ALTER COLUMN menutranslate_gid SET DEFAULT nextval('public.core_mst_tmenutranslate_menutranslate_gid_seq'::regclass);


--
-- Name: core_mst_tmessage msg_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmessage ALTER COLUMN msg_gid SET DEFAULT nextval('public.core_mst_tmessage_msg_gid_seq'::regclass);


--
-- Name: core_mst_tmessagetranslate msgtranslate_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmessagetranslate ALTER COLUMN msgtranslate_gid SET DEFAULT nextval('public.core_mst_tmessagetranslate_msgtranslate_gid_seq'::regclass);


--
-- Name: core_mst_tmobilesync mobilesync_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmobilesync ALTER COLUMN mobilesync_gid SET DEFAULT nextval('public.core_mst_tmobilesync_mobilesync_gid_seq'::regclass);


--
-- Name: core_mst_tmobilesynctable mobilesynctable_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmobilesynctable ALTER COLUMN mobilesynctable_gid SET DEFAULT nextval('public.core_mst_tmobilesynctable_mobilesynctable_gid_seq'::regclass);


--
-- Name: core_mst_tpgdocnum pgdocnum_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tpgdocnum ALTER COLUMN pgdocnum_gid SET DEFAULT nextval('public.core_mst_tpgdocnum_pgdocnum_gid_seq'::regclass);


--
-- Name: core_mst_tproduct prod_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproduct ALTER COLUMN prod_gid SET DEFAULT nextval('public.core_mst_tproduct_prod_gid_seq'::regclass);


--
-- Name: core_mst_tproductprice prodprice_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproductprice ALTER COLUMN prodprice_gid SET DEFAULT nextval('public.core_mst_tproductprice_prodprice_gid_seq'::regclass);


--
-- Name: core_mst_tproductquality prodqlty_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproductquality ALTER COLUMN prodqlty_gid SET DEFAULT nextval('public.core_mst_tproductquality_prodqlty_gid_seq'::regclass);


--
-- Name: core_mst_tproducttranslate prodtranslate_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproducttranslate ALTER COLUMN prodtranslate_gid SET DEFAULT nextval('public.core_mst_tproducttranslate_prodtranslate_gid_seq'::regclass);


--
-- Name: core_mst_treport report_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_treport ALTER COLUMN report_gid SET DEFAULT nextval('public.core_mst_treport_report_gid_seq'::regclass);


--
-- Name: core_mst_treportparam reportparam_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_treportparam ALTER COLUMN reportparam_gid SET DEFAULT nextval('public.core_mst_treportparam_reportparam_gid_seq'::regclass);


--
-- Name: core_mst_trole role_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_trole ALTER COLUMN role_gid SET DEFAULT nextval('public.core_mst_trole_role_gid_seq'::regclass);


--
-- Name: core_mst_trolemenurights rolemenurights_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_trolemenurights ALTER COLUMN rolemenurights_gid SET DEFAULT nextval('public.core_mst_trolemenurights_rolemenurights_gid_seq'::regclass);


--
-- Name: core_mst_tscreen screen_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tscreen ALTER COLUMN screen_gid SET DEFAULT nextval('public.core_mst_tscreen_screen_gid_seq'::regclass);


--
-- Name: core_mst_tscreendata screendata_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tscreendata ALTER COLUMN screendata_gid SET DEFAULT nextval('public.core_mst_tscreendata_screendata_gid_seq'::regclass);


--
-- Name: core_mst_tsmstemplate smstemplate_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tsmstemplate ALTER COLUMN smstemplate_gid SET DEFAULT nextval('public.core_mst_tsmstemplate_smstemplate_gid_seq'::regclass);


--
-- Name: core_mst_tuomconv uomconv_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tuomconv ALTER COLUMN uomconv_gid SET DEFAULT nextval('public.core_mst_tuomconv_uomconv_gid_seq'::regclass);


--
-- Name: core_mst_tuser user_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tuser ALTER COLUMN user_gid SET DEFAULT nextval('public.core_mst_tuser_user_gid_seq'::regclass);


--
-- Name: district_master district_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.district_master ALTER COLUMN district_id SET DEFAULT nextval('public.district_master_copy_district_id_seq'::regclass);


--
-- Name: executive_member executive_member_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.executive_member ALTER COLUMN executive_member_id SET DEFAULT nextval('public.executive_member_executive_member_id_seq'::regclass);


--
-- Name: panchayat_master panchayat_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.panchayat_master ALTER COLUMN panchayat_id SET DEFAULT nextval('public.panchayat_master_copy_panchayat_id_seq'::regclass);


--
-- Name: pg_mst_tactivity pgactivitity_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tactivity ALTER COLUMN pgactivitity_gid SET DEFAULT nextval('public.pg_mst_tactivity_pgactivitity_gid_seq'::regclass);


--
-- Name: pg_mst_taddress pgaddress_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_taddress ALTER COLUMN pgaddress_gid SET DEFAULT nextval('public.pg_mst_taddress_pgaddress_gid_seq'::regclass);


--
-- Name: pg_mst_tbank pgbank_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tbank ALTER COLUMN pgbank_gid SET DEFAULT nextval('public.pg_mst_tbank_pgbank_gid_seq'::regclass);


--
-- Name: pg_mst_tclf pgclf_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tclf ALTER COLUMN pgclf_gid SET DEFAULT nextval('public.pg_mst_tclf_pgclf_gid_seq'::regclass);


--
-- Name: pg_mst_tcollectionpoint collpoint_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tcollectionpoint ALTER COLUMN collpoint_gid SET DEFAULT nextval('public.pg_mst_tcollectionpoint_collpoint_gid_seq'::regclass);


--
-- Name: pg_mst_tfinancesumm pgfinsumm_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tfinancesumm ALTER COLUMN pgfinsumm_gid SET DEFAULT nextval('public.pg_mst_tfinancesumm_pgfinsumm_gid_seq'::regclass);


--
-- Name: pg_mst_tfundsupport pgfundsupp_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tfundsupport ALTER COLUMN pgfundsupp_gid SET DEFAULT nextval('public.pg_mst_tfundsupport_pgfundsupp_gid_seq'::regclass);


--
-- Name: pg_mst_tofficebearers pgoffbearer_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tofficebearers ALTER COLUMN pgoffbearer_gid SET DEFAULT nextval('public.pg_mst_tofficebearers_pgoffbearer_gid_seq'::regclass);


--
-- Name: pg_mst_tpanchayatmapping pgpanchayatmapping_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpanchayatmapping ALTER COLUMN pgpanchayatmapping_gid SET DEFAULT nextval('public.pg_mst_tpanchayatmapping_pgpanchayatmapping_gid_seq'::regclass);


--
-- Name: pg_mst_tproducergroup pg_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tproducergroup ALTER COLUMN pg_gid SET DEFAULT nextval('public.pg_mst_tproducergroup_pg_gid_seq'::regclass);


--
-- Name: pg_mst_tproductmapping pgprodmapp_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tproductmapping ALTER COLUMN pgprodmapp_gid SET DEFAULT nextval('public.pg_mst_tproductmapping_pgprodmapp_gid_seq'::regclass);


--
-- Name: pg_mst_tudyogmitra pgudyogmitra_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tudyogmitra ALTER COLUMN pgudyogmitra_gid SET DEFAULT nextval('public.pg_mst_tudyogmitra_pgudyogmitra_gid_seq'::regclass);


--
-- Name: pg_mst_tvillagemapping pgvillagemapping_gid; Type: DEFAULT; Schema: public; Owner: flexi
--

ALTER TABLE ONLY public.pg_mst_tvillagemapping ALTER COLUMN pgvillagemapping_gid SET DEFAULT nextval('public.pg_mst_tvillagemapping_pgvillagemapping_gid_seq'::regclass);


--
-- Name: pg_trn_tbussplan bussplan_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplan ALTER COLUMN bussplan_gid SET DEFAULT nextval('public.pg_trn_tbussplan_bussplan_gid_seq'::regclass);


--
-- Name: pg_trn_tbussplandownloadlog bussplandownloadlog_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplandownloadlog ALTER COLUMN bussplandownloadlog_gid SET DEFAULT nextval('public.pg_trn_tbussplandownloadlog_bussplandownloadlog_gid_seq'::regclass);


--
-- Name: pg_trn_tbussplanexpenses bussplanexpenses_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanexpenses ALTER COLUMN bussplanexpenses_gid SET DEFAULT nextval('public.pg_trn_tbussplanexpenses_bussplanexpenses_gid_seq'::regclass);


--
-- Name: pg_trn_tbussplanfinyear bussplancalender_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanfinyear ALTER COLUMN bussplancalender_gid SET DEFAULT nextval('public.pg_trn_tbussplanfinyear_bussplancalender_gid_seq'::regclass);


--
-- Name: pg_trn_tbussplanproduce bussplanproduce_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanproduce ALTER COLUMN bussplanproduce_gid SET DEFAULT nextval('public.pg_trn_tbussplanproduce_bussplanproduce_gid_seq'::regclass);


--
-- Name: pg_trn_tbussplanproduct bussplanprod_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanproduct ALTER COLUMN bussplanprod_gid SET DEFAULT nextval('public.pg_trn_tbussplanproduct_bussplanprod_gid_seq'::regclass);


--
-- Name: pg_trn_texcplog excplog_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_texcplog ALTER COLUMN excplog_gid SET DEFAULT nextval('public.pg_trn_texcplog_excplog_gid_seq'::regclass);


--
-- Name: pg_trn_tfunddisbtranche funddisbtranche_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfunddisbtranche ALTER COLUMN funddisbtranche_gid SET DEFAULT nextval('public.pg_trn_tfunddisbtranche_funddisbtranche_gid_seq'::regclass);


--
-- Name: pg_trn_tfunddisbursement funddisb_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfunddisbursement ALTER COLUMN funddisb_gid SET DEFAULT nextval('public.pg_trn_tfunddisbursement_funddisb_gid_seq'::regclass);


--
-- Name: pg_trn_tfundrepymt fundrepymt_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfundrepymt ALTER COLUMN fundrepymt_gid SET DEFAULT nextval('public.pg_trn_tfundrepymt_fundrepymt_gid_seq'::regclass);


--
-- Name: pg_trn_tfundrequisition fundreq_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfundrequisition ALTER COLUMN fundreq_gid SET DEFAULT nextval('public.pg_trn_tfundrequisition_fundreq_gid_seq'::regclass);


--
-- Name: pg_trn_tfundrequisitiondtl fundreq_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfundrequisitiondtl ALTER COLUMN fundreq_gid SET DEFAULT nextval('public.pg_trn_tfundrequisitiondtl_fundreq_gid_seq'::regclass);


--
-- Name: pg_trn_thonorarium honorarium_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_thonorarium ALTER COLUMN honorarium_gid SET DEFAULT nextval('public.pg_trn_thonorarium_honorarium_gid_seq'::regclass);


--
-- Name: pg_trn_tincomeexpense incomeexpense_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tincomeexpense ALTER COLUMN incomeexpense_gid SET DEFAULT nextval('public.pg_trn_tincomeexpense_incomeexpense_gid_seq'::regclass);


--
-- Name: pg_trn_tpgfund pgfund_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfund ALTER COLUMN pgfund_gid SET DEFAULT nextval('public.pg_trn_tpgfund_pgfund_gid_seq'::regclass);


--
-- Name: pg_trn_tpgfundexpenses pgfundexp_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfundexpenses ALTER COLUMN pgfundexp_gid SET DEFAULT nextval('public.pg_trn_tpgfundexpenses_pgfundexp_gid_seq'::regclass);


--
-- Name: pg_trn_tpgfundledger pgfundledger_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfundledger ALTER COLUMN pgfundledger_gid SET DEFAULT nextval('public.pg_trn_tpgfundledger_pgfundledger_gid_seq'::regclass);


--
-- Name: pg_trn_tpgfundledgersumm pgfundledgersumm_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfundledgersumm ALTER COLUMN pgfundledgersumm_gid SET DEFAULT nextval('public.pg_trn_tpgfundledgersumm_pgfundledgersumm_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmembercommcalc pgmembercommcalc_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmembercommcalc ALTER COLUMN pgmembercommcalc_gid SET DEFAULT nextval('public.pg_trn_tpgmembercommcalc_pgmembercommcalc_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmembercommcalcdtl pgmembercommcalcdtl_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmembercommcalcdtl ALTER COLUMN pgmembercommcalcdtl_gid SET DEFAULT nextval('public.pg_trn_tpgmembercommcalcdtl_pgmembercommcalcdtl_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmemberledger pgmemberledger_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberledger ALTER COLUMN pgmemberledger_gid SET DEFAULT nextval('public.pg_trn_tpgmemberledger_pgmemberledger_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmemberledgersumm pgmemberledgersumm_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberledgersumm ALTER COLUMN pgmemberledgersumm_gid SET DEFAULT nextval('public.pg_trn_tpgmemberledgersumm_pgmemberledgersumm_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmemberpayment pgmemberpymt_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberpayment ALTER COLUMN pgmemberpymt_gid SET DEFAULT nextval('public.pg_trn_tpgmemberpayment_pgmemberpymt_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmemberproccostcalc pgmemberproccostcalc_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberproccostcalc ALTER COLUMN pgmemberproccostcalc_gid SET DEFAULT nextval('public.pg_trn_tpgmemberproccostcalc_pgmemberproccostcalc_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmemberproccostcalcdtl pgmemberproccostcalcdtl_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberproccostcalcdtl ALTER COLUMN pgmemberproccostcalcdtl_gid SET DEFAULT nextval('public.pg_trn_tpgmemberproccostcalcdtl_pgmemberproccostcalcdtl_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmembersalecalc pgmembersalecalc_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmembersalecalc ALTER COLUMN pgmembersalecalc_gid SET DEFAULT nextval('public.pg_trn_tpgmemberpaymentcalc_pgmembercalc_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmemberstock pgmemberstock_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberstock ALTER COLUMN pgmemberstock_gid SET DEFAULT nextval('public.pg_trn_tpgmemberstock_pgmemberstock_gid_seq'::regclass);


--
-- Name: pg_trn_tpgmemberstockbydate pgmemberstockbydate_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberstockbydate ALTER COLUMN pgmemberstockbydate_gid SET DEFAULT nextval('public.pg_trn_tpgmemberstockbydate_pgmemberstockbydate_gid_seq'::regclass);


--
-- Name: pg_trn_tproductstock prodstock_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tproductstock ALTER COLUMN prodstock_gid SET DEFAULT nextval('public.pg_trn_tproductstock_prodstock_gid_seq'::regclass);


--
-- Name: pg_trn_tproductstockbydate prodstockbydate_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tproductstockbydate ALTER COLUMN prodstockbydate_gid SET DEFAULT nextval('public.pg_trn_tproductstockbydate_prodstockbydate_gid_seq'::regclass);


--
-- Name: pg_trn_tsalecalc salecalc_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsalecalc ALTER COLUMN salecalc_gid SET DEFAULT nextval('public.pg_trn_tsalecalc_salecalc_gid_seq'::regclass);


--
-- Name: pg_trn_tsmstran smstran_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsmstran ALTER COLUMN smstran_gid SET DEFAULT nextval('public.pg_trn_tsmstran_smstran_gid_seq'::regclass);


--
-- Name: pg_trn_tsqliteattachment sqliteattachment_gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsqliteattachment ALTER COLUMN sqliteattachment_gid SET DEFAULT nextval('public.pg_trn_tsqliteattachment_sqliteattachment_gid_seq'::regclass);


--
-- Name: state_master state_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.state_master ALTER COLUMN state_id SET DEFAULT nextval('public.state_master_state_id_seq'::regclass);


--
-- Name: village_master village_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.village_master ALTER COLUMN village_id SET DEFAULT nextval('public.village_master_copy_village_id_seq'::regclass);


--
-- Name: bank_branch_master bank_branch_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_branch_master
    ADD CONSTRAINT bank_branch_master_pkey PRIMARY KEY (bank_branch_id);


--
-- Name: bank_master bank_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_master
    ADD CONSTRAINT bank_master_pkey PRIMARY KEY (bank_id);


--
-- Name: bank_masterlokos bank_masterlokos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_masterlokos
    ADD CONSTRAINT bank_masterlokos_pkey PRIMARY KEY (bank_id);


--
-- Name: block_master block_master_copy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.block_master
    ADD CONSTRAINT block_master_copy_pkey PRIMARY KEY (block_id);


--
-- Name: core_mst_tconfig core_mst_tconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tconfig
    ADD CONSTRAINT core_mst_tconfig_pkey PRIMARY KEY (config_gid);


--
-- Name: core_mst_tdocnum core_mst_tdocnum_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tdocnum
    ADD CONSTRAINT core_mst_tdocnum_pkey PRIMARY KEY (docnum_gid);


--
-- Name: core_mst_tfinyear core_mst_tfinyear_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tfinyear
    ADD CONSTRAINT core_mst_tfinyear_pkey PRIMARY KEY (finyear_gid);


--
-- Name: core_mst_tifsc core_mst_tifsc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tifsc
    ADD CONSTRAINT core_mst_tifsc_pkey PRIMARY KEY (ifsc_gid);


--
-- Name: core_mst_tinterfaceurl core_mst_tinterfaceurl_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tinterfaceurl
    ADD CONSTRAINT core_mst_tinterfaceurl_pkey PRIMARY KEY (ifaceurl_gid);


--
-- Name: core_mst_tlanguage core_mst_tlanguage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tlanguage
    ADD CONSTRAINT core_mst_tlanguage_pkey PRIMARY KEY (lang_gid);


--
-- Name: core_mst_tlokossync core_mst_tlokossync_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tlokossync
    ADD CONSTRAINT core_mst_tlokossync_pkey PRIMARY KEY (lokossync_gid);


--
-- Name: core_mst_tlokossyncqry core_mst_tlokossyncqry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tlokossyncqry
    ADD CONSTRAINT core_mst_tlokossyncqry_pkey PRIMARY KEY (lokossyncqry_gid);


--
-- Name: core_mst_tmaster core_mst_tmaster_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmaster
    ADD CONSTRAINT core_mst_tmaster_pkey PRIMARY KEY (master_gid);


--
-- Name: core_mst_tmastertranslate core_mst_tmastertranslate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmastertranslate
    ADD CONSTRAINT core_mst_tmastertranslate_pkey PRIMARY KEY (mastertranslate_gid);


--
-- Name: core_mst_tmenu core_mst_tmenu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmenu
    ADD CONSTRAINT core_mst_tmenu_pkey PRIMARY KEY (menu_gid);


--
-- Name: core_mst_tmenutranslate core_mst_tmenutranslate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmenutranslate
    ADD CONSTRAINT core_mst_tmenutranslate_pkey PRIMARY KEY (menutranslate_gid);


--
-- Name: core_mst_tmessage core_mst_tmessage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmessage
    ADD CONSTRAINT core_mst_tmessage_pkey PRIMARY KEY (msg_gid);


--
-- Name: core_mst_tmessagetranslate core_mst_tmessagetranslate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmessagetranslate
    ADD CONSTRAINT core_mst_tmessagetranslate_pkey PRIMARY KEY (msgtranslate_gid);


--
-- Name: core_mst_tmobilesynctable core_mst_tmobilesynctable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmobilesynctable
    ADD CONSTRAINT core_mst_tmobilesynctable_pkey PRIMARY KEY (mobilesynctable_gid);


--
-- Name: core_mst_tpatchqry core_mst_tpatchqry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tpatchqry
    ADD CONSTRAINT core_mst_tpatchqry_pkey PRIMARY KEY (patchqry_gid);


--
-- Name: core_mst_tpgdocnum core_mst_tpgdocnum_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tpgdocnum
    ADD CONSTRAINT core_mst_tpgdocnum_pkey PRIMARY KEY (activity_code, pg_id, finyear_id, tran_date);


--
-- Name: core_mst_tproduct core_mst_tproduct_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproduct
    ADD CONSTRAINT core_mst_tproduct_pkey PRIMARY KEY (prod_gid);


--
-- Name: core_mst_tproductprice core_mst_tproductprice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproductprice
    ADD CONSTRAINT core_mst_tproductprice_pkey PRIMARY KEY (prodprice_gid);


--
-- Name: core_mst_tproductquality core_mst_tproductquality_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproductquality
    ADD CONSTRAINT core_mst_tproductquality_pkey PRIMARY KEY (prodqlty_gid);


--
-- Name: core_mst_tproducttranslate core_mst_tproducttranslate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tproducttranslate
    ADD CONSTRAINT core_mst_tproducttranslate_pkey PRIMARY KEY (prodtranslate_gid);


--
-- Name: core_mst_treport core_mst_treport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_treport
    ADD CONSTRAINT core_mst_treport_pkey PRIMARY KEY (report_gid);


--
-- Name: core_mst_treportparam core_mst_treportparam_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_treportparam
    ADD CONSTRAINT core_mst_treportparam_pkey PRIMARY KEY (reportparam_gid);


--
-- Name: core_mst_trole core_mst_trole_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_trole
    ADD CONSTRAINT core_mst_trole_pkey PRIMARY KEY (role_gid);


--
-- Name: core_mst_trolemenurights core_mst_trolemenurights_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_trolemenurights
    ADD CONSTRAINT core_mst_trolemenurights_pkey PRIMARY KEY (rolemenurights_gid);


--
-- Name: core_mst_tscreen core_mst_tscreen_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tscreen
    ADD CONSTRAINT core_mst_tscreen_pkey PRIMARY KEY (screen_gid);


--
-- Name: core_mst_tscreendata core_mst_tscreendata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tscreendata
    ADD CONSTRAINT core_mst_tscreendata_pkey PRIMARY KEY (screendata_gid);


--
-- Name: core_mst_tsmstemplate core_mst_tsmstemplate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tsmstemplate
    ADD CONSTRAINT core_mst_tsmstemplate_pkey PRIMARY KEY (smstemplate_gid);


--
-- Name: core_mst_ttenantidentifier core_mst_ttenantidentifier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_ttenantidentifier
    ADD CONSTRAINT core_mst_ttenantidentifier_pkey PRIMARY KEY (tenant_gid);


--
-- Name: core_mst_tuomconv core_mst_tuomconv_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tuomconv
    ADD CONSTRAINT core_mst_tuomconv_pkey PRIMARY KEY (uomconv_gid);


--
-- Name: core_mst_tuser core_mst_tuser_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tuser
    ADD CONSTRAINT core_mst_tuser_pkey PRIMARY KEY (user_gid);


--
-- Name: core_mst_tuserblock core_mst_tuserblock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tuserblock
    ADD CONSTRAINT core_mst_tuserblock_pkey PRIMARY KEY (userblock_gid);


--
-- Name: core_mst_tuserblock core_mst_tuserblock_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tuserblock
    ADD CONSTRAINT core_mst_tuserblock_unique UNIQUE (user_code);


--
-- Name: core_mst_tusertoken core_mst_tusertoken_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tusertoken
    ADD CONSTRAINT core_mst_tusertoken_pkey PRIMARY KEY (token_gid);


--
-- Name: core_mst_tusertoken core_mst_tusertoken_ukey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tusertoken
    ADD CONSTRAINT core_mst_tusertoken_ukey UNIQUE (user_code, url) INCLUDE (user_code, url);


--
-- Name: district_master district_master_copy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.district_master
    ADD CONSTRAINT district_master_copy_pkey PRIMARY KEY (district_id);


--
-- Name: executive_member executive_member_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.executive_member
    ADD CONSTRAINT executive_member_unique UNIQUE (ec_member_code, state_id, cbo_id, cbo_level, ec_cbo_code, executive_member_id);


--
-- Name: federation_profile_consolidated federation_profile_consolidated_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.federation_profile_consolidated
    ADD CONSTRAINT federation_profile_consolidated_pkey PRIMARY KEY (local_id);


--
-- Name: federation_profile federation_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.federation_profile
    ADD CONSTRAINT federation_profile_pkey PRIMARY KEY (federation_id, state_id);


--
-- Name: member_address member_address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_address
    ADD CONSTRAINT member_address_pkey PRIMARY KEY (member_address_id, state);


--
-- Name: member_address member_address_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_address
    ADD CONSTRAINT member_address_unique UNIQUE (member_address_id, state_id);


--
-- Name: member_bank_details member_bank_details_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_bank_details
    ADD CONSTRAINT member_bank_details_unique UNIQUE (member_bank_details_id, state_id);


--
-- Name: member_phone_details member_phone_details_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_phone_details
    ADD CONSTRAINT member_phone_details_unique UNIQUE (member_phone_details_id, state_id);


--
-- Name: member_profile_consolidated member_profile_consolidated_pkey_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_profile_consolidated
    ADD CONSTRAINT member_profile_consolidated_pkey_1 PRIMARY KEY (local_id);


--
-- Name: member_profile member_profile_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_profile
    ADD CONSTRAINT member_profile_unique UNIQUE (member_id, state_id);


--
-- Name: panchayat_master panchayat_master_copy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.panchayat_master
    ADD CONSTRAINT panchayat_master_copy_pkey PRIMARY KEY (panchayat_id);


--
-- Name: pg_mst_tactivity pg_mst_tactivity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tactivity
    ADD CONSTRAINT pg_mst_tactivity_pkey PRIMARY KEY (pgactivitity_gid);


--
-- Name: pg_mst_tactivity pg_mst_tactivity_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tactivity
    ADD CONSTRAINT pg_mst_tactivity_unique UNIQUE (pg_id, prod_code, activity_code);


--
-- Name: pg_mst_taddress pg_mst_taddress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_taddress
    ADD CONSTRAINT pg_mst_taddress_pkey PRIMARY KEY (pgaddress_gid);


--
-- Name: pg_mst_tattachment pg_mst_tattachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tattachment
    ADD CONSTRAINT pg_mst_tattachment_pkey PRIMARY KEY (pgattachment_gid);


--
-- Name: pg_mst_tbank pg_mst_tbank_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tbank
    ADD CONSTRAINT pg_mst_tbank_pkey PRIMARY KEY (pgbank_gid);


--
-- Name: pg_mst_tbomanager pg_mst_tbomanager_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tbomanager
    ADD CONSTRAINT pg_mst_tbomanager_pkey PRIMARY KEY (pgbomanager_gid);


--
-- Name: pg_mst_tclf pg_mst_tclf_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tclf
    ADD CONSTRAINT pg_mst_tclf_pkey PRIMARY KEY (pgclf_gid);


--
-- Name: pg_mst_tcollectionpoint pg_mst_tcollectionpoint_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tcollectionpoint
    ADD CONSTRAINT pg_mst_tcollectionpoint_pkey PRIMARY KEY (collpoint_gid);


--
-- Name: pg_mst_tcollectionpoint pg_mst_tcollectionpoint_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tcollectionpoint
    ADD CONSTRAINT pg_mst_tcollectionpoint_unique UNIQUE (pg_id, collpoint_name, collpoint_lang_code);


--
-- Name: pg_mst_tfinancesumm pg_mst_tfinancesumm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tfinancesumm
    ADD CONSTRAINT pg_mst_tfinancesumm_pkey PRIMARY KEY (pgfinsumm_gid);


--
-- Name: pg_mst_tfundsupport pg_mst_tfundsupport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tfundsupport
    ADD CONSTRAINT pg_mst_tfundsupport_pkey PRIMARY KEY (pgfundsupp_gid);


--
-- Name: pg_mst_tofficebearers pg_mst_tofficebearers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tofficebearers
    ADD CONSTRAINT pg_mst_tofficebearers_pkey PRIMARY KEY (pgoffbearer_gid);


--
-- Name: pg_mst_tpanchayatmapping pg_mst_tpanchayatmapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpanchayatmapping
    ADD CONSTRAINT pg_mst_tpanchayatmapping_pkey PRIMARY KEY (pgpanchayatmapping_gid);


--
-- Name: pg_mst_tpgbuyer pg_mst_tpgbuyer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgbuyer
    ADD CONSTRAINT pg_mst_tpgbuyer_pkey PRIMARY KEY (pg_id, mobile_no);


--
-- Name: pg_mst_tpgmember pg_mst_tpgmember_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmember
    ADD CONSTRAINT pg_mst_tpgmember_pkey PRIMARY KEY (pg_id, pgmember_id);


--
-- Name: pg_mst_tpgmemberaddress pg_mst_tpgmemberaddress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmemberaddress
    ADD CONSTRAINT pg_mst_tpgmemberaddress_pkey PRIMARY KEY (pgmember_id, pgmemberaddress_gid);


--
-- Name: pg_mst_tpgmemberasset pg_mst_tpgmemberasset_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmemberasset
    ADD CONSTRAINT pg_mst_tpgmemberasset_pkey PRIMARY KEY (pgmemberasset_gid, pgmember_id);


--
-- Name: pg_mst_tpgmemberattachment pg_mst_tpgmemberattachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmemberattachment
    ADD CONSTRAINT pg_mst_tpgmemberattachment_pkey PRIMARY KEY (pgmemberattachment_gid, pgmember_id);


--
-- Name: pg_mst_tpgmemberbank pg_mst_tpgmemberbank_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmemberbank
    ADD CONSTRAINT pg_mst_tpgmemberbank_pkey PRIMARY KEY (pgmemberbank_gid, pgmember_id);


--
-- Name: pg_mst_tpgmembercrop pg_mst_tpgmembercrop_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmembercrop
    ADD CONSTRAINT pg_mst_tpgmembercrop_pkey PRIMARY KEY (pgmembercrop_gid, pgmember_id);


--
-- Name: pg_mst_tpgmemberland pg_mst_tpgmemberland_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmemberland
    ADD CONSTRAINT pg_mst_tpgmemberland_pkey PRIMARY KEY (pgmemberland_gid, pgmember_id);


--
-- Name: pg_mst_tpgmemberlivestock pg_mst_tpgmemberlivestock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmemberlivestock
    ADD CONSTRAINT pg_mst_tpgmemberlivestock_pkey PRIMARY KEY (pgmemberlivestock_gid, pgmember_id);


--
-- Name: pg_mst_tpgmembersequence pg_mst_tpgmembersequence_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmembersequence
    ADD CONSTRAINT pg_mst_tpgmembersequence_pkey PRIMARY KEY (pgmemberseq_gid, pg_id);


--
-- Name: pg_mst_tpgmembersequence pg_mst_tpgmembersequence_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmembersequence
    ADD CONSTRAINT pg_mst_tpgmembersequence_unique UNIQUE (pg_id);


--
-- Name: pg_mst_tpgmembership pg_mst_tpgmembership_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tpgmembership
    ADD CONSTRAINT pg_mst_tpgmembership_pkey PRIMARY KEY (pgmembership_gid, pgmember_id);


--
-- Name: pg_mst_tproducergroup pg_mst_tproducergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tproducergroup
    ADD CONSTRAINT pg_mst_tproducergroup_pkey PRIMARY KEY (pg_gid);


--
-- Name: pg_mst_tproductmapping pg_mst_tproductmapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tproductmapping
    ADD CONSTRAINT pg_mst_tproductmapping_pkey PRIMARY KEY (pgprodmapp_gid);


--
-- Name: pg_mst_tudyogmitra pg_mst_tudyogmitra_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_mst_tudyogmitra
    ADD CONSTRAINT pg_mst_tudyogmitra_pkey PRIMARY KEY (pgudyogmitra_gid);


--
-- Name: pg_mst_tvillagemapping pg_mst_tvillagemapping_pkey; Type: CONSTRAINT; Schema: public; Owner: flexi
--

ALTER TABLE ONLY public.pg_mst_tvillagemapping
    ADD CONSTRAINT pg_mst_tvillagemapping_pkey PRIMARY KEY (pgvillagemapping_gid);


--
-- Name: pg_trn_tbussplan pg_trn_tbussplan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplan
    ADD CONSTRAINT pg_trn_tbussplan_pkey PRIMARY KEY (bussplan_gid);


--
-- Name: pg_trn_tbussplan pg_trn_tbussplan_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplan
    ADD CONSTRAINT pg_trn_tbussplan_unique UNIQUE (pg_id, bussplan_id);


--
-- Name: pg_trn_tbussplanattachment pg_trn_tbussplanattachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanattachment
    ADD CONSTRAINT pg_trn_tbussplanattachment_pkey PRIMARY KEY (bussplanattachment_gid);


--
-- Name: pg_trn_tbussplandownloadlog pg_trn_tbussplandownloadlog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplandownloadlog
    ADD CONSTRAINT pg_trn_tbussplandownloadlog_pkey PRIMARY KEY (bussplandownloadlog_gid);


--
-- Name: pg_trn_tbussplanexpenses pg_trn_tbussplanexpenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanexpenses
    ADD CONSTRAINT pg_trn_tbussplanexpenses_pkey PRIMARY KEY (bussplanexpenses_gid);


--
-- Name: pg_trn_tbussplanexpenses pg_trn_tbussplanexpenses_ukey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanexpenses
    ADD CONSTRAINT pg_trn_tbussplanexpenses_ukey UNIQUE (pg_id, bussplan_id, finyear_id);


--
-- Name: pg_trn_tbussplanfinyear pg_trn_tbussplanfinyear_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanfinyear
    ADD CONSTRAINT pg_trn_tbussplanfinyear_pkey PRIMARY KEY (bussplancalender_gid);


--
-- Name: pg_trn_tbussplanfinyear pg_trn_tbussplanfinyear_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanfinyear
    ADD CONSTRAINT pg_trn_tbussplanfinyear_unique UNIQUE (pg_id, bussplan_id, finyear_id, prod_code);


--
-- Name: pg_trn_tbussplanproduce pg_trn_tbussplanproduce_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanproduce
    ADD CONSTRAINT pg_trn_tbussplanproduce_pkey PRIMARY KEY (bussplanproduce_gid);


--
-- Name: pg_trn_tbussplanproduce pg_trn_tbussplanproduce_ukey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanproduce
    ADD CONSTRAINT pg_trn_tbussplanproduce_ukey UNIQUE (pg_id, bussplan_id, finyear_id, prod_type_code, prod_code, produce_month);


--
-- Name: pg_trn_tbussplanproduct pg_trn_tbussplanproduct_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanproduct
    ADD CONSTRAINT pg_trn_tbussplanproduct_pkey PRIMARY KEY (bussplanprod_gid);


--
-- Name: pg_trn_tbussplanproduct pg_trn_tbussplanproduct_ukey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tbussplanproduct
    ADD CONSTRAINT pg_trn_tbussplanproduct_ukey UNIQUE (pg_id, bussplan_id, prod_code);


--
-- Name: pg_trn_tcollection pg_trn_tcollection_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tcollection
    ADD CONSTRAINT pg_trn_tcollection_pkey PRIMARY KEY (coll_gid);


--
-- Name: pg_trn_texcplog pg_trn_texcplog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_texcplog
    ADD CONSTRAINT pg_trn_texcplog_pkey PRIMARY KEY (excplog_gid);


--
-- Name: pg_trn_tfunddisbtranche pg_trn_tfunddisbtranche_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfunddisbtranche
    ADD CONSTRAINT pg_trn_tfunddisbtranche_pkey PRIMARY KEY (funddisbtranche_gid);


--
-- Name: pg_trn_tfunddisbursement pg_trn_tfunddisbursement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfunddisbursement
    ADD CONSTRAINT pg_trn_tfunddisbursement_pkey PRIMARY KEY (funddisb_gid);


--
-- Name: pg_trn_tfundrepymt pg_trn_tfundrepymt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfundrepymt
    ADD CONSTRAINT pg_trn_tfundrepymt_pkey PRIMARY KEY (fundrepymt_gid);


--
-- Name: pg_trn_tfundreqattachment pg_trn_tfundreqattachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfundreqattachment
    ADD CONSTRAINT pg_trn_tfundreqattachment_pkey PRIMARY KEY (fundreqattachment_gid);


--
-- Name: pg_trn_tfundrequisition pg_trn_tfundrequisition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfundrequisition
    ADD CONSTRAINT pg_trn_tfundrequisition_pkey PRIMARY KEY (fundreq_gid);


--
-- Name: pg_trn_tfundrequisitiondtl pg_trn_tfundrequisitiondtl_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tfundrequisitiondtl
    ADD CONSTRAINT pg_trn_tfundrequisitiondtl_pkey PRIMARY KEY (fundreq_gid);


--
-- Name: pg_trn_thonorarium pg_trn_thonorarium_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_thonorarium
    ADD CONSTRAINT pg_trn_thonorarium_pkey PRIMARY KEY (honorarium_gid);


--
-- Name: pg_trn_tincomeexpense pg_trn_tincomeexpense_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tincomeexpense
    ADD CONSTRAINT pg_trn_tincomeexpense_pkey PRIMARY KEY (incomeexpense_gid);


--
-- Name: pg_trn_tloginhistory pg_trn_tloginhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tloginhistory
    ADD CONSTRAINT pg_trn_tloginhistory_pkey PRIMARY KEY (loginhistory_gid);


--
-- Name: pg_trn_tpgfund pg_trn_tpgfund_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfund
    ADD CONSTRAINT pg_trn_tpgfund_pkey PRIMARY KEY (pgfund_gid);


--
-- Name: pg_trn_tpgfundexpenses pg_trn_tpgfundexpenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfundexpenses
    ADD CONSTRAINT pg_trn_tpgfundexpenses_pkey PRIMARY KEY (pgfundexp_gid);


--
-- Name: pg_trn_tpgfundledger pg_trn_tpgfundledger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfundledger
    ADD CONSTRAINT pg_trn_tpgfundledger_pkey PRIMARY KEY (pgfundledger_gid);


--
-- Name: pg_trn_tpgfundledgersumm pg_trn_tpgfundledgersumm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgfundledgersumm
    ADD CONSTRAINT pg_trn_tpgfundledgersumm_pkey PRIMARY KEY (pgfundledgersumm_gid);


--
-- Name: pg_trn_tpgmembercommcalc pg_trn_tpgmembercommcalc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmembercommcalc
    ADD CONSTRAINT pg_trn_tpgmembercommcalc_pkey PRIMARY KEY (pgmembercommcalc_gid);


--
-- Name: pg_trn_tpgmembercommcalcdtl pg_trn_tpgmembercommcalcdtl_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmembercommcalcdtl
    ADD CONSTRAINT pg_trn_tpgmembercommcalcdtl_pkey PRIMARY KEY (pgmembercommcalcdtl_gid);


--
-- Name: pg_trn_tpgmemberledger pg_trn_tpgmemberledger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberledger
    ADD CONSTRAINT pg_trn_tpgmemberledger_pkey PRIMARY KEY (pgmemberledger_gid);


--
-- Name: pg_trn_tpgmemberledgersumm pg_trn_tpgmemberledgersumm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberledgersumm
    ADD CONSTRAINT pg_trn_tpgmemberledgersumm_pkey PRIMARY KEY (pgmemberledgersumm_gid);


--
-- Name: pg_trn_tpgmemberpayment pg_trn_tpgmemberpayment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberpayment
    ADD CONSTRAINT pg_trn_tpgmemberpayment_pkey PRIMARY KEY (pgmemberpymt_gid);


--
-- Name: pg_trn_tpgmembersalecalc pg_trn_tpgmemberpaymentcalc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmembersalecalc
    ADD CONSTRAINT pg_trn_tpgmemberpaymentcalc_pkey PRIMARY KEY (pgmembersalecalc_gid);


--
-- Name: pg_trn_tpgmemberproccostcalc pg_trn_tpgmemberproccostcalc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberproccostcalc
    ADD CONSTRAINT pg_trn_tpgmemberproccostcalc_pkey PRIMARY KEY (pgmemberproccostcalc_gid);


--
-- Name: pg_trn_tpgmemberproccostcalcdtl pg_trn_tpgmemberproccostcalcdtl_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberproccostcalcdtl
    ADD CONSTRAINT pg_trn_tpgmemberproccostcalcdtl_pkey PRIMARY KEY (pgmemberproccostcalcdtl_gid);


--
-- Name: pg_trn_tpgmemberstock pg_trn_tpgmemberstock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberstock
    ADD CONSTRAINT pg_trn_tpgmemberstock_pkey PRIMARY KEY (pgmemberstock_gid);


--
-- Name: pg_trn_tpgmemberstock pg_trn_tpgmemberstock_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberstock
    ADD CONSTRAINT pg_trn_tpgmemberstock_unique UNIQUE (pg_id, pgmember_id, prod_type_code, prod_code, grade_code);


--
-- Name: pg_trn_tpgmemberstockbydate pg_trn_tpgmemberstockbydate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tpgmemberstockbydate
    ADD CONSTRAINT pg_trn_tpgmemberstockbydate_pkey PRIMARY KEY (pgmemberstockbydate_gid);


--
-- Name: pg_trn_tprocureproductqlty pg_trn_tprocproductqlty_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tprocureproductqlty
    ADD CONSTRAINT pg_trn_tprocproductqlty_unique UNIQUE (pg_id, session_id, pgmember_id, rec_slno, prod_code, grade_code, qltyparam_code);


--
-- Name: pg_trn_tprocure pg_trn_tprocure_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tprocure
    ADD CONSTRAINT pg_trn_tprocure_pkey PRIMARY KEY (pg_id, session_id, pgmember_id, proc_date);


--
-- Name: pg_trn_tprocure pg_trn_tprocure_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tprocure
    ADD CONSTRAINT pg_trn_tprocure_unique UNIQUE (pg_id, session_id, pgmember_id, proc_date);


--
-- Name: pg_trn_tprocurecost pg_trn_tprocurecost_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tprocurecost
    ADD CONSTRAINT pg_trn_tprocurecost_pkey PRIMARY KEY (pg_id, tran_datetime);


--
-- Name: pg_trn_tprocurecost pg_trn_tprocurecost_ukey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tprocurecost
    ADD CONSTRAINT pg_trn_tprocurecost_ukey UNIQUE (pg_id, tran_datetime);


--
-- Name: pg_trn_tprocureproduct pg_trn_tprocureproduct_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tprocureproduct
    ADD CONSTRAINT pg_trn_tprocureproduct_pkey PRIMARY KEY (pg_id, session_id, pgmember_id, rec_slno, prod_code, grade_code);


--
-- Name: pg_trn_tprocureproduct pg_trn_tprocureproduct_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tprocureproduct
    ADD CONSTRAINT pg_trn_tprocureproduct_unique UNIQUE (pg_id, session_id, pgmember_id, rec_slno, prod_code, grade_code);


--
-- Name: pg_trn_tproductstock pg_trn_tproductstock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tproductstock
    ADD CONSTRAINT pg_trn_tproductstock_pkey PRIMARY KEY (prodstock_gid);


--
-- Name: pg_trn_tproductstock pg_trn_tproductstock_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tproductstock
    ADD CONSTRAINT pg_trn_tproductstock_unique UNIQUE (pg_id, prod_type_code, prod_code, grade_code);


--
-- Name: pg_trn_tproductstockbydate pg_trn_tproductstockbydate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tproductstockbydate
    ADD CONSTRAINT pg_trn_tproductstockbydate_pkey PRIMARY KEY (prodstockbydate_gid);


--
-- Name: pg_trn_tsale pg_trn_tsale_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsale
    ADD CONSTRAINT pg_trn_tsale_unique UNIQUE (pg_id, inv_date, inv_no);


--
-- Name: pg_trn_tsalecalc pg_trn_tsalecalc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsalecalc
    ADD CONSTRAINT pg_trn_tsalecalc_pkey PRIMARY KEY (salecalc_gid);


--
-- Name: pg_trn_tsaleproduct pg_trn_tsaleproduct_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsaleproduct
    ADD CONSTRAINT pg_trn_tsaleproduct_pkey PRIMARY KEY (pg_id, inv_date, inv_no, rec_slno, prod_code, grade_code);


--
-- Name: pg_trn_tsaleproduct pg_trn_tsaleproduct_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsaleproduct
    ADD CONSTRAINT pg_trn_tsaleproduct_unique UNIQUE (pg_id, inv_date, inv_no, rec_slno, prod_code, grade_code);


--
-- Name: pg_trn_tsession pg_trn_tsession_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsession
    ADD CONSTRAINT pg_trn_tsession_pkey PRIMARY KEY (pg_id, session_id);


--
-- Name: pg_trn_tsession pg_trn_tsession_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsession
    ADD CONSTRAINT pg_trn_tsession_unique UNIQUE (pg_id, session_id);


--
-- Name: pg_trn_tsmstran pg_trn_tsmstran_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsmstran
    ADD CONSTRAINT pg_trn_tsmstran_pkey PRIMARY KEY (smstran_gid);


--
-- Name: pg_trn_tsqliteattachment pg_trn_tsqliteattachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pg_trn_tsqliteattachment
    ADD CONSTRAINT pg_trn_tsqliteattachment_pkey PRIMARY KEY (sqliteattachment_gid);


--
-- Name: core_mst_tmobilesync pkey_core_mst_tmobilesync; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_mst_tmobilesync
    ADD CONSTRAINT pkey_core_mst_tmobilesync PRIMARY KEY (pg_id, role_code, user_code, mobile_no, sync_type_code);


--
-- Name: shg_profile_consolidated shg_profile_consolidated_pkey_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shg_profile_consolidated
    ADD CONSTRAINT shg_profile_consolidated_pkey_1 PRIMARY KEY (local_id);


--
-- Name: shg_profile shg_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shg_profile
    ADD CONSTRAINT shg_profile_pkey PRIMARY KEY (shg_id, state_id);


--
-- Name: state_master state_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.state_master
    ADD CONSTRAINT state_master_pkey PRIMARY KEY (state_id);


--
-- Name: village_master village_master_copy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.village_master
    ADD CONSTRAINT village_master_copy_pkey PRIMARY KEY (village_id);


--
-- Name: cbo_mapping_details_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cbo_mapping_details_index ON public.cbo_mapping_details USING btree (cbo_id, is_active);


--
-- Name: dx_core_mst_tmobilesync_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dx_core_mst_tmobilesync_unique ON public.core_mst_tmobilesync USING btree (pg_id, role_code, user_code, mobile_no, sync_type_code);


--
-- Name: idx_bankbranch; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bankbranch ON public.bank_branch_master USING btree (bank_branch_id);


--
-- Name: idx_branch; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_branch ON public.bank_branch_master USING btree (bank_id, bank_branch_id);


--
-- Name: idx_mapping; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mapping ON public.cbo_mapping_details USING btree (cbo_id);


--
-- Name: idx_member_profile_consd_state_code_cbo_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_member_profile_consd_state_code_cbo_code ON public.federation_profile_consolidated USING btree (state_code, cbo_code);


--
-- Name: idx_member_profile_consd_state_code_member_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_member_profile_consd_state_code_member_code ON public.member_profile_consolidated USING btree (state_code, member_code);


--
-- Name: idx_mobilesynctable_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_mobilesynctable_unique ON public.core_mst_tmobilesynctable USING btree (db_schema_name, src_table_name, sync_group_name, role_code);


--
-- Name: idx_pg_mst_tproducergroup_pg_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_pg_mst_tproducergroup_pg_id ON public.pg_mst_tproducergroup USING btree (pg_id);


--
-- Name: idx_shg_profile_consd_state_code_shg_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shg_profile_consd_state_code_shg_code ON public.shg_profile_consolidated USING btree (state_code, shg_code);


--
-- Name: idx_unique_ifsc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_ifsc ON public.core_mst_tifsc USING btree (ifsc_code);


--
-- Name: idx_unique_language; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_language ON public.core_mst_tlanguage USING btree (lang_code);


--
-- Name: idx_unique_master; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_master ON public.core_mst_tmaster USING btree (parent_code, master_code);


--
-- Name: idx_unique_mastertranslate; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_mastertranslate ON public.core_mst_tmastertranslate USING btree (parent_code, master_code, lang_code);


--
-- Name: idx_unique_menu; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_menu ON public.core_mst_tmenu USING btree (menu_code);


--
-- Name: idx_unique_menutranslate; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_menutranslate ON public.core_mst_tmenutranslate USING btree (menu_code, lang_code);


--
-- Name: idx_unique_msg; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_msg ON public.core_mst_tmessage USING btree (msg_code);


--
-- Name: idx_unique_msgtranslate; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_unique_msgtranslate ON public.core_mst_tmessagetranslate USING btree (msg_code, lang_code);


--
-- Name: idx_unique_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_product ON public.core_mst_tproduct USING btree (prod_code);


--
-- Name: idx_unique_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_unique_role ON public.core_mst_trole USING btree (role_code);


--
-- Name: idx_unique_screen; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_unique_screen ON public.core_mst_tscreen USING btree (screen_code);


--
-- Name: idx_village; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_village ON public.village_master USING btree (state_id, district_id, block_id, panchayat_id, village_id);


--
-- Name: member_profile_consolidated_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_profile_consolidated_index ON public.member_profile_consolidated USING btree (state_code, member_code);


--
-- Name: member_profile_consolidated_shg_code_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_profile_consolidated_shg_code_index ON public.member_profile_consolidated USING btree (state_code, member_code, shg_code);


--
-- Name: shg_profile_consolidated_parent_cbo_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX shg_profile_consolidated_parent_cbo_code_idx ON public.shg_profile_consolidated USING btree (parent_cbo_code);


--
-- Name: pg_trn_tpgfundledger trg_aft_cxx_pg_trn_tpgfundledger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tpgfundledger AFTER INSERT ON public.pg_trn_tpgfundledger FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tpgfundledger();


--
-- Name: pg_trn_tpgmemberledger trg_aft_cxx_pg_trn_tpgmemberledger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tpgmemberledger AFTER INSERT ON public.pg_trn_tpgmemberledger FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tpgmemberledger();


--
-- Name: pg_trn_tprocure trg_aft_cxx_pg_trn_tprocure; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tprocure AFTER INSERT ON public.pg_trn_tprocure FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tprocure();


--
-- Name: pg_trn_tprocureproduct trg_aft_cxx_pg_trn_tprocureproduct; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tprocureproduct AFTER INSERT ON public.pg_trn_tprocureproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tprocureproduct();


--
-- Name: pg_trn_tprocureproduct trg_aft_cxx_pg_trn_tprocurestockbydate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tprocurestockbydate AFTER INSERT ON public.pg_trn_tprocureproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tprocurestockbydate();


--
-- Name: pg_trn_tsaleproduct trg_aft_cxx_pg_trn_tsaleproduct; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tsaleproduct AFTER INSERT ON public.pg_trn_tsaleproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tsaleproduct();


--
-- Name: pg_trn_tsaleproduct trg_aft_cxx_pg_trn_tsalestockbydate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tsalestockbydate AFTER INSERT ON public.pg_trn_tsaleproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tsalestockbydate();


--
-- Name: pg_trn_tsession trg_aft_cxx_pg_trn_tsession; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_cxx_pg_trn_tsession AFTER INSERT ON public.pg_trn_tsession FOR EACH ROW EXECUTE FUNCTION public.fn_aft_cxx_pg_trn_tsession();


--
-- Name: pg_trn_tpgfundledger trg_aft_dxx_pg_trn_tpgfundledger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_dxx_pg_trn_tpgfundledger AFTER DELETE ON public.pg_trn_tpgfundledger FOR EACH ROW EXECUTE FUNCTION public.fn_aft_dxx_pg_trn_tpgfundledger();


--
-- Name: pg_trn_tpgmemberledger trg_aft_dxx_pg_trn_tpgmemberledger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_dxx_pg_trn_tpgmemberledger AFTER DELETE ON public.pg_trn_tpgmemberledger FOR EACH ROW EXECUTE FUNCTION public.fn_aft_dxx_pg_trn_tpgmemberledger();


--
-- Name: pg_trn_tprocure trg_aft_dxx_pg_trn_tprocure; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_dxx_pg_trn_tprocure AFTER DELETE ON public.pg_trn_tprocure FOR EACH ROW EXECUTE FUNCTION public.fn_aft_dxx_pg_trn_tprocure();


--
-- Name: pg_trn_tprocureproduct trg_aft_dxx_pg_trn_tprocureproduct; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_dxx_pg_trn_tprocureproduct AFTER DELETE ON public.pg_trn_tprocureproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_dxx_pg_trn_tprocureproduct();


--
-- Name: pg_trn_tprocureproduct trg_aft_dxx_pg_trn_tprocurestockbydate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_dxx_pg_trn_tprocurestockbydate AFTER DELETE ON public.pg_trn_tprocureproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_dxx_pg_trn_tprocurestockbydate();


--
-- Name: pg_trn_tsaleproduct trg_aft_dxx_pg_trn_tsaleproduct; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_dxx_pg_trn_tsaleproduct AFTER DELETE ON public.pg_trn_tsaleproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_dxx_pg_trn_tsaleproduct();


--
-- Name: pg_trn_tsaleproduct trg_aft_dxx_pg_trn_tsalestockbydate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_dxx_pg_trn_tsalestockbydate AFTER DELETE ON public.pg_trn_tsaleproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_dxx_pg_trn_tsalestockbydate();


--
-- Name: pg_mst_tpgmember trg_aft_insupdt_pg_mst_tpgmember; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_insupdt_pg_mst_tpgmember AFTER INSERT OR UPDATE ON public.pg_mst_tpgmember FOR EACH ROW EXECUTE FUNCTION public.aft_insupdt_pg_mst_tpgmember();


--
-- Name: pg_trn_tpgfundledger trg_aft_uxx_pg_trn_tpgfundledger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_uxx_pg_trn_tpgfundledger AFTER UPDATE ON public.pg_trn_tpgfundledger FOR EACH ROW WHEN ((new.* IS DISTINCT FROM old.*)) EXECUTE FUNCTION public.fn_aft_uxx_pg_trn_tpgfundledger();


--
-- Name: pg_trn_tpgmemberledger trg_aft_uxx_pg_trn_tpgmemberledger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_uxx_pg_trn_tpgmemberledger AFTER UPDATE ON public.pg_trn_tpgmemberledger FOR EACH ROW WHEN ((new.* IS DISTINCT FROM old.*)) EXECUTE FUNCTION public.fn_aft_uxx_pg_trn_tpgmemberledger();


--
-- Name: pg_trn_tprocure trg_aft_uxx_pg_trn_tprocure; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_uxx_pg_trn_tprocure AFTER UPDATE ON public.pg_trn_tprocure FOR EACH ROW WHEN ((new.* IS DISTINCT FROM old.*)) EXECUTE FUNCTION public.fn_aft_uxx_pg_trn_tprocure();


--
-- Name: pg_trn_tprocureproduct trg_aft_uxx_pg_trn_tprocureproduct; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_uxx_pg_trn_tprocureproduct AFTER UPDATE ON public.pg_trn_tprocureproduct FOR EACH ROW WHEN ((new.* IS DISTINCT FROM old.*)) EXECUTE FUNCTION public.fn_aft_uxx_pg_trn_tprocureproduct();


--
-- Name: pg_trn_tprocureproduct trg_aft_uxx_pg_trn_tprocurestockbydate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_uxx_pg_trn_tprocurestockbydate AFTER UPDATE ON public.pg_trn_tprocureproduct FOR EACH ROW WHEN ((new.* IS DISTINCT FROM old.*)) EXECUTE FUNCTION public.fn_aft_uxx_pg_trn_tprocurestockbydate();


--
-- Name: pg_trn_tsaleproduct trg_aft_uxx_pg_trn_tsaleproduct; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_uxx_pg_trn_tsaleproduct AFTER UPDATE ON public.pg_trn_tsaleproduct FOR EACH ROW WHEN ((new.* IS DISTINCT FROM old.*)) EXECUTE FUNCTION public.fn_aft_uxx_pg_trn_tsaleproduct();


--
-- Name: pg_trn_tsaleproduct trg_aft_uxx_pg_trn_tsalestockbydate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_aft_uxx_pg_trn_tsalestockbydate AFTER UPDATE ON public.pg_trn_tsaleproduct FOR EACH ROW EXECUTE FUNCTION public.fn_aft_uxx_pg_trn_tsalestockbydate();


--
-- Name: pg_mst_tpgmember trg_bef_cxx_pg_mst_tpgmember; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_bef_cxx_pg_mst_tpgmember BEFORE INSERT ON public.pg_mst_tpgmember FOR EACH ROW EXECUTE FUNCTION public.fn_bef_cxx_pg_mst_tpgmember();


--
-- Name: pg_trn_tpgfundledger trg_bef_uxx_pg_trn_tpgfundledger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_bef_uxx_pg_trn_tpgfundledger BEFORE UPDATE ON public.pg_trn_tpgfundledger FOR EACH ROW WHEN ((new.* IS DISTINCT FROM old.*)) EXECUTE FUNCTION public.fn_bef_uxx_pg_trn_tpgfundledger();


--
-- Name: district_master fk5j4lfqocro3n0xh0bhd2ouxc5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.district_master
    ADD CONSTRAINT fk5j4lfqocro3n0xh0bhd2ouxc5 FOREIGN KEY (state_id) REFERENCES public.state_master(state_id);


--
-- PostgreSQL database dump complete
--

