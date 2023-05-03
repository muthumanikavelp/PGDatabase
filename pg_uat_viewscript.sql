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

--
-- Name: bussplanprocure_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.bussplanprocure_view AS
 SELECT DISTINCT 'Procurement'::text AS title,
    bp.pg_id,
    bpfin.bussplancalender_gid,
    bp.bussplan_id,
    bpprod.finyear_id,
    bpprod.prod_code,
    prod.uom_code,
    sum((bpprod.harvesting_qty)::numeric) AS qty,
    bpfin.prodprocure_rate AS rate,
    sum(((bpprod.harvesting_qty)::numeric * (bpfin.prodprocure_rate)::numeric)) AS amount
   FROM ((((public.pg_trn_tbussplan bp
     JOIN public.pg_trn_tbussplanfinyear bpfin ON ((((bp.pg_id)::text = (bpfin.pg_id)::text) AND ((bp.bussplan_id)::text = (bpfin.bussplan_id)::text))))
     JOIN public.pg_trn_tbussplanproduct prod ON ((((bp.pg_id)::text = (prod.pg_id)::text) AND ((bp.bussplan_id)::text = (prod.bussplan_id)::text) AND ((bpfin.prod_code)::text = (prod.prod_code)::text))))
     JOIN public.pg_trn_tbussplanproduce bpprod ON ((((bp.pg_id)::text = (bpprod.pg_id)::text) AND ((bp.bussplan_id)::text = (bpprod.bussplan_id)::text) AND ((bpfin.finyear_id)::text = (bpprod.finyear_id)::text) AND ((bpfin.prod_code)::text = (bpprod.prod_code)::text))))
     JOIN public.core_mst_tfinyear fin ON ((((bpfin.finyear_id)::text = (fin.finyear_id)::text) AND ((fin.status_code)::text = 'A'::text))))
  WHERE ((bp.status_code)::text <> 'I'::text)
  GROUP BY bpprod.finyear_id, bpfin.bussplancalender_gid, bpprod.prod_code, prod.uom_code, bpfin.prodprocure_rate, bp.pg_id, bp.bussplan_id;


ALTER TABLE public.bussplanprocure_view OWNER TO postgres;

--
-- Name: bussplanrevenue_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.bussplanrevenue_view AS
 SELECT 'Revenue'::text AS title,
    bp.pg_id,
    bpfin.bussplancalender_gid,
    bp.bussplan_id,
    bpprod.finyear_id,
    bpprod.prod_code,
    prod.uom_code,
    sum((bpprod.harvesting_qty)::numeric) AS qty,
    bpfin.prodrevenue_rate AS rate,
    sum(((bpprod.harvesting_qty)::numeric * (bpfin.prodrevenue_rate)::numeric)) AS amount
   FROM ((((public.pg_trn_tbussplan bp
     JOIN public.pg_trn_tbussplanfinyear bpfin ON ((((bp.pg_id)::text = (bpfin.pg_id)::text) AND ((bp.bussplan_id)::text = (bpfin.bussplan_id)::text))))
     JOIN public.pg_trn_tbussplanproduct prod ON ((((bp.pg_id)::text = (prod.pg_id)::text) AND ((bp.bussplan_id)::text = (prod.bussplan_id)::text) AND ((bpfin.prod_code)::text = (prod.prod_code)::text))))
     JOIN public.pg_trn_tbussplanproduce bpprod ON ((((bp.pg_id)::text = (bpprod.pg_id)::text) AND ((bp.bussplan_id)::text = (bpprod.bussplan_id)::text) AND ((bpfin.finyear_id)::text = (bpprod.finyear_id)::text) AND ((bpfin.prod_code)::text = (bpprod.prod_code)::text))))
     JOIN public.core_mst_tfinyear fin ON ((((bpfin.finyear_id)::text = (fin.finyear_id)::text) AND ((fin.status_code)::text = 'A'::text))))
  WHERE ((bp.status_code)::text <> 'I'::text)
  GROUP BY bpprod.finyear_id, bpfin.bussplancalender_gid, bpprod.prod_code, prod.uom_code, bpfin.prodrevenue_rate, bp.pg_id, bp.bussplan_id;


ALTER TABLE public.bussplanrevenue_view OWNER TO postgres;

--
-- Name: clf_profile_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.clf_profile_view AS
 SELECT pg.pg_id,
    fed.cbo_id AS clf_id,
    fed.federation_name AS clf_name,
    fed.federation_name_local AS clf_name_local,
    addr.state_id,
    addr.district_id,
    addr.block_id
   FROM ((public.pg_mst_taddress addr
     JOIN public.pg_mst_tproducergroup pg ON (((pg.pg_id)::text = (addr.pg_id)::text)))
     JOIN public.federation_profile_consolidated fed ON ((((addr.block_id)::integer = fed.block_id) AND (fed.cbo_type = 2) AND (fed.is_active = true))))
  WHERE ((addr.addr_type_code)::text = 'QCD_ADDRTYPE_REG'::text);


ALTER TABLE public.clf_profile_view OWNER TO postgres;

--
-- Name: clf_profiledesc_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.clf_profiledesc_view AS
 SELECT pg.pg_id,
    fed.cbo_id AS clf_id,
    fed.federation_name AS clf_name,
    fed.federation_name_local AS clf_name_local,
    addr.state_id,
    addr.district_id,
    addr.block_id,
    s.state_code,
    s.state_name_en AS state_name,
    d.district_code,
    d.district_name_en AS district_name,
    b.block_code,
    b.block_name_en AS block_name,
    fed.created_date,
    fed.last_updated_date AS updated_date
   FROM (((((public.pg_mst_tpanchayatmapping addr
     JOIN public.pg_mst_tproducergroup pg ON (((pg.pg_id)::text = (addr.pg_id)::text)))
     JOIN public.federation_profile_consolidated fed ON ((((addr.block_id)::integer = fed.block_id) AND (fed.cbo_type = 2) AND (fed.is_active = true))))
     LEFT JOIN public.state_master s ON (((addr.state_id)::integer = s.state_id)))
     LEFT JOIN public.district_master d ON (((addr.district_id)::integer = d.district_id)))
     LEFT JOIN public.block_master b ON (((addr.block_id)::integer = b.block_id)));


ALTER TABLE public.clf_profiledesc_view OWNER TO postgres;

--
-- Name: clf_vprp_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.clf_vprp_view AS
 SELECT pg.pg_id,
    fed.federation_id AS clf_id,
    fed.federation_name AS clf_name,
    fed.federation_name_local AS clf_name_local,
    addr.state_id,
    addr.district_id,
    addr.block_id,
    s.state_code,
    s.state_name_en AS state_name,
    d.district_code,
    d.district_name_en AS district_name,
    b.block_code,
    b.block_name_en AS block_name,
    fed.created_date,
    ''::text AS created_by,
    fed.updated_date,
    ''::text AS updated_by
   FROM (((((public.pg_mst_tpanchayatmapping addr
     JOIN public.pg_mst_tproducergroup pg ON (((pg.pg_id)::text = (addr.pg_id)::text)))
     JOIN public.federation_profile fed ON ((((addr.block_id)::integer = fed.block_id) AND (fed.cbo_type = 2) AND (fed.is_active = true))))
     LEFT JOIN public.state_master s ON (((addr.state_id)::integer = s.state_id)))
     LEFT JOIN public.district_master d ON (((addr.district_id)::integer = d.district_id)))
     LEFT JOIN public.block_master b ON (((addr.block_id)::integer = b.block_id)));


ALTER TABLE public.clf_vprp_view OWNER TO postgres;

--
-- Name: clfmember_profile_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.clfmember_profile_view AS
 SELECT pg.pg_id,
    fed.cbo_id AS clf_id,
    fed.federation_name AS clf_name,
    fed.federation_name_local AS clf_name_local,
    m.member_id AS clf_member_id,
    m.member_name AS clf_member_name,
    m.member_name_local AS clf_member_name_local,
    addr.state_id,
    addr.district_id,
    addr.block_id
   FROM (((((public.pg_mst_taddress addr
     JOIN public.pg_mst_tproducergroup pg ON (((pg.pg_id)::text = (addr.pg_id)::text)))
     JOIN public.federation_profile_consolidated fed ON ((((addr.block_id)::integer = fed.block_id) AND (fed.cbo_type = 2) AND (fed.is_active = true))))
     JOIN public.federation_profile_consolidated vo ON (((vo.parent_cbo_id = fed.cbo_id) AND (vo.cbo_type = 1) AND (vo.is_active = true))))
     JOIN public.shg_profile_consolidated shg ON ((((shg.parent_cbo_code)::text = (vo.cbo_code)::text) AND (fed.is_active = true))))
     JOIN public.member_profile_consolidated m ON ((m.shg_id = shg.shg_id)))
  WHERE ((addr.addr_type_code)::text = 'QCD_ADDRTYPE_REG'::text);


ALTER TABLE public.clfmember_profile_view OWNER TO postgres;

--
-- Name: clfmember_profiledesc_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.clfmember_profiledesc_view AS
 SELECT pg.pg_id,
    fed.cbo_id AS clf_id,
    fed.federation_name AS clf_name,
    fed.federation_name_local AS clf_name_local,
    m.member_id AS clf_member_id,
    m.member_name AS clf_member_name,
    m.member_name_local AS clf_member_name_local,
    addr.state_id,
    addr.district_id,
    addr.block_id,
    public.fn_get_statedesc(addr.state_id) AS state_name,
    public.fn_get_districtdesc(addr.district_id) AS district_name,
    public.fn_get_blockdesc(addr.block_id) AS block_name
   FROM (((((public.pg_mst_taddress addr
     JOIN public.pg_mst_tproducergroup pg ON (((pg.pg_id)::text = (addr.pg_id)::text)))
     JOIN public.federation_profile_consolidated fed ON ((((addr.block_id)::integer = fed.block_id) AND (fed.cbo_type = 2) AND (fed.is_active = true))))
     JOIN public.federation_profile_consolidated vo ON (((vo.parent_cbo_id = fed.cbo_id) AND (vo.cbo_type = 1) AND (vo.is_active = true))))
     JOIN public.shg_profile_consolidated shg ON ((((shg.parent_cbo_code)::text = (vo.cbo_code)::text) AND (fed.is_active = true))))
     JOIN public.member_profile_consolidated m ON ((m.shg_id = shg.shg_id)))
  WHERE ((addr.addr_type_code)::text = 'QCD_ADDRTYPE_REG'::text);


ALTER TABLE public.clfmember_profiledesc_view OWNER TO postgres;

--
-- Name: commprodsurp_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.commprodsurp_view AS
 SELECT pg.pg_id,
    bpf.finyear_id,
    bpprod.prod_type_code,
    bpprod.prod_code,
    bpprod.uom_code AS bp_uom_code,
    prod.uom_code AS prod_uom_code,
    count(DISTINCT pg.pg_id) AS no_of_pgs,
    public.fn_get_pgmahilakisancount(pg.pg_id) AS no_of_mahila_kisan
   FROM ((((public.pg_mst_tproducergroup pg
     JOIN public.pg_trn_tbussplan bp ON ((((pg.pg_id)::text = (bp.pg_id)::text) AND ((bp.status_code)::text = 'A'::text))))
     JOIN public.pg_trn_tbussplanproduct bpprod ON ((((bp.pg_id)::text = (bpprod.pg_id)::text) AND ((bp.bussplan_id)::text = (bpprod.bussplan_id)::text))))
     JOIN public.pg_trn_tbussplanfinyear bpf ON ((((bp.pg_id)::text = (bpf.pg_id)::text) AND ((bp.bussplan_id)::text = (bpf.bussplan_id)::text))))
     JOIN public.core_mst_tproduct prod ON ((((bpprod.prod_code)::text = (prod.prod_code)::text) AND ((prod.status_code)::text = 'A'::text))))
  GROUP BY pg.pg_id, bpf.finyear_id, bpprod.prod_type_code, bpprod.prod_code, bpprod.uom_code, prod.uom_code;


ALTER TABLE public.commprodsurp_view OWNER TO postgres;

--
-- Name: core_mst_tproduct_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.core_mst_tproduct_view AS
 SELECT b.pg_id,
    a.prod_gid,
    a.prod_code,
    a.farm_prod_flag,
    a.prod_type_code,
    a.category_code,
    a.subcategory_code,
    a.uom_code,
    (replace((substr((a.prod_image)::text, "position"(((a.prod_image)::text COLLATE "default"), ';base64,'::text)) COLLATE "default"), ';base64,'::text, ''::text))::public.udd_text AS prod_image,
    a.status_code,
    a.created_date,
    a.created_by,
    a.updated_date,
    a.updated_by,
    a.row_timestamp
   FROM (public.core_mst_tproduct a
     JOIN public.pg_mst_tproductmapping b ON (((a.prod_code)::text = (b.prod_code)::text)))
  WHERE ((a.status_code)::text = 'A'::text);


ALTER TABLE public.core_mst_tproduct_view OWNER TO postgres;

--
-- Name: core_mst_tproductprice_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.core_mst_tproductprice_view AS
 SELECT b.pg_id,
    a.prodprice_gid,
    a.prod_code,
    a.state_id,
    a.grade_code,
    a.msp_price,
    a.procurement_price,
    a.last_modified_date,
    a.created_date,
    a.created_by,
    a.updated_date,
    a.updated_by
   FROM (public.core_mst_tproductprice a
     JOIN public.core_mst_tproduct_view b ON (((a.prod_code)::text = (b.prod_code)::text)));


ALTER TABLE public.core_mst_tproductprice_view OWNER TO postgres;

--
-- Name: core_mst_tproductquality_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.core_mst_tproductquality_view AS
 SELECT b.pg_id,
    a.prodqlty_gid,
    a.prod_code,
    a.qltyparam_code,
    a.range_from,
    a.range_to,
    a.range_flag,
    a.qltyuom_code,
    a.threshold_value,
    a.created_date,
    a.created_by,
    a.updated_date,
    a.updated_by
   FROM (public.core_mst_tproductquality a
     JOIN public.core_mst_tproduct_view b ON (((a.prod_code)::text = (b.prod_code)::text)));


ALTER TABLE public.core_mst_tproductquality_view OWNER TO postgres;

--
-- Name: core_mst_tproducttranslate_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.core_mst_tproducttranslate_view AS
 SELECT b.pg_id,
    b.created_date,
    b.updated_date,
    a.prodtranslate_gid,
    a.prod_code,
    a.lang_code,
    a.prod_desc
   FROM (public.core_mst_tproducttranslate a
     JOIN public.core_mst_tproduct_view b ON (((a.prod_code)::text = (b.prod_code)::text)))
  WHERE ((b.status_code)::text = 'A'::text);


ALTER TABLE public.core_mst_tproducttranslate_view OWNER TO postgres;

--
-- Name: pg_bank_branch_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_bank_branch_view AS
 SELECT pm.pg_id,
    pm.state_id,
    pm.district_id,
    bm.bank_code,
    bm.bank_name,
    br.bank_branch_id,
    br.bank_branch_code,
    br.bank_branch_name,
    br.ifsc_code,
    br.created_date,
    br.updated_date,
    bm.bank_account_len
   FROM ((public.pg_mst_tpanchayatmapping pm
     JOIN public.bank_branch_master br ON (((pm.district_id)::integer = br.district_id)))
     JOIN public.bank_master bm ON ((br.bank_id = bm.bank_id)))
  GROUP BY pm.pg_id, pm.state_id, pm.district_id, bm.bank_code, bm.bank_name, br.bank_branch_id, br.bank_branch_code, br.bank_branch_name, br.ifsc_code, br.created_date, br.updated_date, bm.bank_account_len;


ALTER TABLE public.pg_bank_branch_view OWNER TO postgres;

--
-- Name: pg_fundrepymttotal_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_fundrepymttotal_view AS
 SELECT pg_trn_tfundrepymt.pg_id,
    pg_trn_tfundrepymt.loan_acc_no,
    sum((pg_trn_tfundrepymt.paid_amount)::numeric) AS tot_paid_amount,
    sum((pg_trn_tfundrepymt.principal_amount)::numeric) AS tot_principal_amount,
    sum((pg_trn_tfundrepymt.interest_amount)::numeric) AS tot_interest_amount,
    sum((pg_trn_tfundrepymt.other_amount)::numeric) AS tot_other_amount
   FROM public.pg_trn_tfundrepymt
  WHERE ((pg_trn_tfundrepymt.status_code)::text = 'A'::text)
  GROUP BY pg_trn_tfundrepymt.pg_id, pg_trn_tfundrepymt.loan_acc_no;


ALTER TABLE public.pg_fundrepymttotal_view OWNER TO postgres;

--
-- Name: pg_location_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_location_view AS
 SELECT a.pg_id,
    c.state_id,
    c.state_name_en,
    c.state_name_local,
    c.is_active AS state_is_active,
    d.district_id,
    d.district_name_en,
    d.district_name_local,
    d.is_active AS district_is_active,
    f.block_id,
    f.block_name_en,
    f.block_name_local,
    f.is_active AS block_is_active,
    g.panchayat_id,
    g.panchayat_name_en,
    g.panchayat_name_local,
    g.is_active AS panchayat_is_active,
    h.village_id,
    h.village_name_en,
    h.village_name_local,
    h.is_active AS village_is_active,
    h.created_date,
    h.updated_date
   FROM (((((public.pg_mst_tpanchayatmapping a
     JOIN public.state_master c ON (((a.state_id)::integer = c.state_id)))
     JOIN public.district_master d ON (((a.district_id)::integer = d.district_id)))
     JOIN public.block_master f ON (((a.block_id)::integer = f.block_id)))
     JOIN public.panchayat_master g ON (((a.panchayat_id)::integer = g.panchayat_id)))
     JOIN public.village_master h ON ((g.panchayat_id = h.panchayat_id)));


ALTER TABLE public.pg_location_view OWNER TO postgres;

--
-- Name: pg_locationcode_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_locationcode_view AS
 SELECT a.pg_id,
    c.state_id,
    c.state_code,
    c.state_name_en,
    c.state_name_local,
    c.is_active AS state_is_active,
    d.district_id,
    d.district_code,
    d.district_name_en,
    d.district_name_local,
    d.is_active AS district_is_active,
    f.block_id,
    f.block_code,
    f.block_name_en,
    f.block_name_local,
    f.is_active AS block_is_active,
    g.panchayat_id,
    g.panchayat_code,
    g.panchayat_name_en,
    g.panchayat_name_local,
    g.is_active AS panchayat_is_active,
    h.village_id,
    h.village_code,
    h.village_name_en,
    h.village_name_local,
    h.is_active AS village_is_active,
    h.created_date,
    h.updated_date
   FROM (((((public.pg_mst_tpanchayatmapping a
     JOIN public.state_master c ON (((a.state_id)::integer = c.state_id)))
     JOIN public.district_master d ON (((a.district_id)::integer = d.district_id)))
     JOIN public.block_master f ON (((a.block_id)::integer = f.block_id)))
     JOIN public.panchayat_master g ON (((a.panchayat_id)::integer = g.panchayat_id)))
     JOIN public.village_master h ON ((g.panchayat_id = h.panchayat_id)));


ALTER TABLE public.pg_locationcode_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberaddress_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmemberaddress_view AS
 SELECT m.pg_id,
    ma.pgmemberaddress_gid,
    ma.pgmember_id,
    ma.addr_type_code,
    ma.addr_line,
    ma.pin_code,
    ma.village_id,
    ma.panchayat_id,
    ma.block_id,
    ma.district_id,
    ma.state_id,
    ma.created_date,
    ma.created_by,
    ma.updated_date,
    ma.updated_by
   FROM (public.pg_mst_tpgmemberaddress ma
     JOIN public.pg_mst_tpgmember m ON (((ma.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmemberaddress_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberasset_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmemberasset_view AS
 SELECT m.pg_id,
    memas.pgmemberasset_gid,
    memas.pgmember_id,
    memas.asset_type_code,
    memas.asset_code,
    memas.ownership_type_code,
    memas.asset_count,
    memas.asset_desc,
    memas.hirer_mfg_name,
    memas.hirer_mfg_date,
    memas.created_date,
    memas.created_by,
    memas.updated_date,
    memas.updated_by
   FROM (public.pg_mst_tpgmemberasset memas
     JOIN public.pg_mst_tpgmember m ON (((memas.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmemberasset_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberattachment_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmemberattachment_view AS
 SELECT m.pg_id,
    mematm.pgmemberattachment_gid,
    mematm.pgmember_id,
    mematm.doc_type_code,
    mematm.doc_subtype_code,
    mematm.file_name,
    mematm.attachment_remark,
    mematm.created_date,
    mematm.created_by,
    mematm.updated_date,
    mematm.updated_by,
    mematm.file_path
   FROM (public.pg_mst_tpgmemberattachment mematm
     JOIN public.pg_mst_tpgmember m ON (((mematm.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmemberattachment_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberbank_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmemberbank_view AS
 SELECT m.pg_id,
    membank.pgmemberbank_gid,
    membank.pgmember_id,
    membank.bankacc_type_code,
    membank.ifsc_code,
    membank.bank_code,
    membank.bank_name,
    membank.branch_name,
    membank.bankacc_no,
    membank.primary_flag,
    membank.created_date,
    membank.created_by,
    membank.updated_date,
    membank.updated_by
   FROM (public.pg_mst_tpgmemberbank membank
     JOIN public.pg_mst_tpgmember m ON (((membank.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmemberbank_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmembercrop_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmembercrop_view AS
 SELECT m.pg_id,
    memcrop.pgmembercrop_gid,
    memcrop.pgmember_id,
    memcrop.season_type_code,
    memcrop.crop_type_code,
    memcrop.crop_code,
    memcrop.crop_name,
    memcrop.sowing_area,
    memcrop.pgmemberland_id,
    memcrop.created_date,
    memcrop.created_by,
    memcrop.updated_date,
    memcrop.updated_by
   FROM (public.pg_mst_tpgmembercrop memcrop
     JOIN public.pg_mst_tpgmember m ON (((memcrop.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmembercrop_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberland_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmemberland_view AS
 SELECT m.pg_id,
    memland.pgmemberland_gid,
    memland.pgmember_id,
    memland.pgmemberland_id,
    memland.land_type_code,
    memland.ownership_type_code,
    memland.land_size,
    memland.cropping_area,
    memland.soil_type_code,
    memland.irrigation_source_code,
    memland.latitude_value,
    memland.longitude_value,
    memland.created_date,
    memland.created_by,
    memland.updated_date,
    memland.updated_by
   FROM (public.pg_mst_tpgmemberland memland
     JOIN public.pg_mst_tpgmember m ON (((memland.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmemberland_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmemberlivestock_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmemberlivestock_view AS
 SELECT m.pg_id,
    memlive.pgmemberlivestock_gid,
    memlive.pgmember_id,
    memlive.livestock_type_code,
    memlive.livestock_code,
    memlive.ownership_type_code,
    memlive.livestock_qty,
    memlive.livestock_remark,
    memlive.created_date,
    memlive.created_by,
    memlive.updated_date,
    memlive.updated_by
   FROM (public.pg_mst_tpgmemberlivestock memlive
     JOIN public.pg_mst_tpgmember m ON (((memlive.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmemberlivestock_view OWNER TO postgres;

--
-- Name: pg_mst_tpgmembership_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_mst_tpgmembership_view AS
 SELECT m.pg_id,
    memship.pgmembership_gid,
    memship.pgmember_id,
    memship.membership_type_code,
    memship.membership_amount,
    memship.effective_from,
    memship.membership_status_code,
    memship.created_date,
    memship.created_by,
    memship.updated_date,
    memship.updated_by
   FROM (public.pg_mst_tpgmembership memship
     JOIN public.pg_mst_tpgmember m ON (((memship.pgmember_id)::text = (m.pgmember_id)::text)));


ALTER TABLE public.pg_mst_tpgmembership_view OWNER TO postgres;

--
-- Name: pg_mst_tproductmapping_view; Type: VIEW; Schema: public; Owner: flexi
--

CREATE VIEW public.pg_mst_tproductmapping_view AS
 SELECT p.category_code,
    p.subcategory_code,
    p.prod_code,
    pm.frequent_flag,
    pm.stock_reset_flag,
    pm.pg_id
   FROM (public.core_mst_tproduct p
     JOIN public.pg_mst_tproductmapping pm ON (((p.prod_code)::text = (pm.prod_code)::text)))
  WHERE ((p.status_code)::text = 'A'::text);


ALTER TABLE public.pg_mst_tproductmapping_view OWNER TO flexi;

--
-- Name: pg_trn_tcashflow_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_trn_tcashflow_view AS
 SELECT pg_trn_tfundrepymt.pg_id,
    'QCD_REPYMT'::text AS acchead_code,
    pg_trn_tfundrepymt.pymt_date AS tran_date,
    pg_trn_tfundrepymt.pay_mode_code,
    pg_trn_tfundrepymt.loan_acc_no AS tran_narration,
    (((pg_trn_tfundrepymt.principal_amount)::numeric + (pg_trn_tfundrepymt.interest_amount)::numeric) + (pg_trn_tfundrepymt.other_amount)::numeric) AS dr_amount,
    0 AS cr_amount,
    pg_trn_tfundrepymt.pymt_ref_no AS tran_ref_no,
    concat(pg_trn_tfundrepymt.loan_acc_no, '/', pg_trn_tfundrepymt.pymt_ref_no, '/', pg_trn_tfundrepymt.pymt_remarks) AS tran_remark,
    pg_trn_tfundrepymt.status_code,
    pg_trn_tfundrepymt.created_date,
    pg_trn_tfundrepymt.created_by,
    pg_trn_tfundrepymt.updated_date,
    pg_trn_tfundrepymt.updated_by,
    'FUND_REPYMT'::text AS source
   FROM public.pg_trn_tfundrepymt
  WHERE ((pg_trn_tfundrepymt.status_code)::text = 'A'::text)
UNION ALL
 SELECT pg_trn_tfunddisbtranche.pg_id,
    'QCD_FUNDTRANCHE'::text AS acchead_code,
    pg_trn_tfunddisbtranche.tranche_date AS tran_date,
    'B'::character varying AS pay_mode_code,
    (((pg_trn_tfunddisbtranche.funddisb_id)::text || ' - Tranche #'::text) || ((pg_trn_tfunddisbtranche.tranche_no)::public.udd_text)::text) AS tran_narration,
    0 AS dr_amount,
    pg_trn_tfunddisbtranche.tranche_amount AS cr_amount,
    pg_trn_tfunddisbtranche.received_ref_no AS tran_ref_no,
    concat('Fund Disbursement Tranche #', (pg_trn_tfunddisbtranche.tranche_no)::public.udd_text, '/', pg_trn_tfunddisbtranche.received_ref_no) AS tran_remark,
    'A'::character varying AS status_code,
    pg_trn_tfunddisbtranche.created_date,
    pg_trn_tfunddisbtranche.created_by,
    pg_trn_tfunddisbtranche.updated_date,
    pg_trn_tfunddisbtranche.updated_by,
    'FUND_DISB'::text AS source
   FROM public.pg_trn_tfunddisbtranche
UNION ALL
 SELECT pg_trn_tincomeexpense.pg_id,
    pg_trn_tincomeexpense.acchead_code,
    pg_trn_tincomeexpense.tran_date,
    pg_trn_tincomeexpense.pay_mode_code,
    pg_trn_tincomeexpense.narration_code AS tran_narration,
    pg_trn_tincomeexpense.dr_amount,
    pg_trn_tincomeexpense.cr_amount,
    pg_trn_tincomeexpense.tran_ref_no,
    concat(public.fn_get_masterdesc(('QCD_ACC_NARRATION'::character varying)::public.udd_code, pg_trn_tincomeexpense.narration_code, ('en_US'::character varying)::public.udd_code), '/', pg_trn_tincomeexpense.tran_ref_no, '/', pg_trn_tincomeexpense.tran_remark) AS tran_remark,
    pg_trn_tincomeexpense.status_code,
    pg_trn_tincomeexpense.created_date,
    pg_trn_tincomeexpense.created_by,
    pg_trn_tincomeexpense.updated_date,
    pg_trn_tincomeexpense.updated_by,
    'INCOME_EXPENSE'::text AS source
   FROM public.pg_trn_tincomeexpense
  WHERE ((pg_trn_tincomeexpense.status_code)::text = 'A'::text)
UNION ALL
 SELECT pg_trn_tprocurecost.pg_id,
    'QCD_PROCCOST'::text AS acchead_code,
    pg_trn_tprocurecost.proc_date AS tran_date,
    'C'::character varying AS pay_mode_code,
    'Proc.Cost'::character varying AS tran_narration,
    ((((pg_trn_tprocurecost.package_cost)::numeric + (pg_trn_tprocurecost.loading_unloading_cost)::numeric) + (pg_trn_tprocurecost.transport_cost)::numeric) + (pg_trn_tprocurecost.other_cost)::numeric) AS dr_amount,
    0 AS cr_amount,
    (pg_trn_tprocurecost.tran_datetime)::public.udd_text AS tran_ref_no,
    concat('Proc.Cost/', (pg_trn_tprocurecost.tran_datetime)::public.udd_text, '/', pg_trn_tprocurecost.proccost_remark) AS tran_remark,
    pg_trn_tprocurecost.status_code,
    pg_trn_tprocurecost.created_date,
    pg_trn_tprocurecost.created_by,
    pg_trn_tprocurecost.updated_date,
    pg_trn_tprocurecost.updated_by,
    'PROC_COST'::text AS source
   FROM public.pg_trn_tprocurecost
  WHERE ((pg_trn_tprocurecost.status_code)::text = 'A'::text)
UNION ALL
 SELECT pg_trn_tpgmemberledger.pg_id,
    pg_trn_tpgmemberledger.acchead_code,
    (pg_trn_tpgmemberledger.tran_date)::public.udd_date AS tran_date,
    'C'::character varying AS pay_mode_code,
    pg_trn_tpgmemberledger.tran_narration,
    pg_trn_tpgmemberledger.cr_amount AS dr_amount,
    pg_trn_tpgmemberledger.dr_amount AS cr_amount,
    pg_trn_tpgmemberledger.tran_ref_no,
    concat(pg_trn_tpgmemberledger.pgmember_id, '-', public.fn_get_pgmembername(pg_trn_tpgmemberledger.pg_id, pg_trn_tpgmemberledger.pgmember_id), '/', pg_trn_tpgmemberledger.tran_narration, '/', pg_trn_tpgmemberledger.tran_ref_no, '/', pg_trn_tpgmemberledger.tran_remark) AS tran_remark,
    pg_trn_tpgmemberledger.status_code,
    pg_trn_tpgmemberledger.created_date,
    pg_trn_tpgmemberledger.created_by,
    pg_trn_tpgmemberledger.updated_date,
    pg_trn_tpgmemberledger.updated_by,
    'MEMBER_LEDGER'::text AS source
   FROM public.pg_trn_tpgmemberledger
  WHERE (((pg_trn_tpgmemberledger.acchead_code)::text = ANY (ARRAY[('QCD_MEM_PAYMENT'::character varying)::text, ('QCD_MEM_ADVANCE'::character varying)::text])) AND ((pg_trn_tpgmemberledger.status_code)::text = 'A'::text))
UNION ALL
 SELECT p.pg_id,
    'QCD_SALES'::text AS acchead_code,
    p.inv_date AS tran_date,
    'C'::character varying AS pay_mode_code,
    concat(s.buyer_name, '/', s.inv_no, '/', public.fn_get_productdesc(p.prod_code, ('en_US'::character varying)::public.udd_code), '/', p.grade_code, '/', (p.sale_qty)::public.udd_text) AS tran_narration,
    0 AS dr_amount,
    ((p.sale_qty)::numeric * (p.sale_rate)::numeric) AS cr_amount,
    s.inv_no AS tran_ref_no,
    concat(s.buyer_name, '/', s.inv_no, '/', public.fn_get_productdesc(p.prod_code, ('en_US'::character varying)::public.udd_code), '/', p.grade_code, '/', pr.uom_code, '/', (p.sale_qty)::public.udd_text) AS tran_remark,
    p.status_code,
    p.created_date,
    p.created_by,
    p.updated_date,
    p.updated_by,
    'PG_SALES'::text AS source
   FROM ((public.pg_trn_tsale s
     JOIN public.pg_trn_tsaleproduct p ON ((((s.pg_id)::text = (p.pg_id)::text) AND ((s.inv_date)::date = (p.inv_date)::date) AND ((s.inv_no)::text = (p.inv_no)::text))))
     LEFT JOIN public.core_mst_tproduct pr ON (((p.prod_code)::text = (pr.prod_code)::text)))
  WHERE ((s.status_code)::text = 'A'::text);


ALTER TABLE public.pg_trn_tcashflow_view OWNER TO postgres;

--
-- Name: pg_trn_tsale_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_trn_tsale_view AS
 SELECT a.pg_id,
    a.inv_no,
    a.inv_date,
    a.buyer_name,
    a.buyer_regular_flag,
    a.buyer_mobile_no,
    a.collected_amount,
    a.status_code,
    sum(((((b.sale_qty)::numeric * (b.sale_rate)::numeric) + (b.cgst_amount)::numeric) + (b.sgst_amount)::numeric)) AS tot_sale_amount,
    sum(((b.cgst_amount)::numeric + (b.sgst_amount)::numeric)) AS tot_gst_amount,
    sum(((b.sale_qty)::numeric * (b.sale_rate)::numeric)) AS tot_sale_base_amount
   FROM (public.pg_trn_tsale a
     JOIN public.pg_trn_tsaleproduct b ON ((((a.pg_id)::text = (b.pg_id)::text) AND ((a.inv_no)::text = (b.inv_no)::text) AND ((a.inv_date)::date = (b.inv_date)::date))))
  GROUP BY a.pg_id, a.inv_no, a.inv_date, a.buyer_name, a.collected_amount, a.status_code, a.buyer_regular_flag, a.buyer_mobile_no;


ALTER TABLE public.pg_trn_tsale_view OWNER TO postgres;

--
-- Name: pg_vprp_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pg_vprp_view AS
 SELECT pg.pg_gid,
    pg.pg_id AS pg_code,
    pg.pg_name,
    addr.state_id,
    addr.district_id,
    addr.block_id,
    s.state_code,
    s.state_name_en AS state_name,
    d.district_code,
    d.district_name_en AS district_name,
    b.block_code,
    b.block_name_en AS block_name,
    gp.panchayat_code,
    gp.panchayat_name_en AS panchayat_name,
    v.village_code,
    v.village_name_en AS village_name,
    'PG'::text AS data_source,
    pg.created_date,
    pg.created_by,
    pg.updated_date,
    pg.updated_by
   FROM (((((((public.pg_mst_tproducergroup pg
     JOIN public.pg_mst_tpanchayatmapping pm ON (((pg.pg_id)::text = (pm.pg_id)::text)))
     LEFT JOIN public.pg_mst_taddress addr ON ((((pg.pg_id)::text = (addr.pg_id)::text) AND ((addr.addr_type_code)::text = 'QCD_ADDRTYPE_REG'::text))))
     LEFT JOIN public.state_master s ON (((pm.state_id)::integer = s.state_id)))
     LEFT JOIN public.district_master d ON (((pm.district_id)::integer = d.district_id)))
     LEFT JOIN public.block_master b ON (((pm.block_id)::integer = b.block_id)))
     LEFT JOIN public.panchayat_master gp ON (((addr.panchayat_id)::integer = gp.panchayat_id)))
     LEFT JOIN public.village_master v ON (((addr.village_id)::integer = v.village_id)))
  GROUP BY pg.pg_gid, pg.pg_id, pg.pg_name, addr.state_id, addr.district_id, addr.block_id, s.state_code, s.state_name_en, d.district_code, d.district_name_en, b.block_code, b.block_name_en, gp.panchayat_code, gp.panchayat_name_en, v.village_code, v.village_name_en, pg.created_date, pg.created_by, pg.updated_date, pg.updated_by;


ALTER TABLE public.pg_vprp_view OWNER TO postgres;

--
-- Name: procurementcosttotal_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.procurementcosttotal_view AS
 SELECT 'Procurement Cost Total'::text AS title,
    brv.pg_id,
    brv.bussplan_id,
    0 AS gid,
    brv.finyear_id,
    '-'::text AS prod_code,
    'Operating Profit'::text AS prod_desc,
    '-'::text AS uom_code,
    '-'::text AS uom_desc,
    0 AS qty,
    0 AS rate,
    sum((((brv.rate)::numeric - (ppv.rate)::numeric) * brv.qty)) AS amt
   FROM (public.bussplanrevenue_view brv
     JOIN public.bussplanprocure_view ppv ON ((((brv.finyear_id)::text = (ppv.finyear_id)::text) AND ((brv.prod_code)::text = (ppv.prod_code)::text) AND ((brv.uom_code)::text = (ppv.uom_code)::text) AND (brv.bussplancalender_gid = ppv.bussplancalender_gid))))
  GROUP BY brv.pg_id, brv.bussplan_id, brv.finyear_id;


ALTER TABLE public.procurementcosttotal_view OWNER TO postgres;

--
-- Name: procureproduct_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.procureproduct_view AS
 SELECT 'Procure'::text AS title,
    bp.pg_id,
    bpfin.bussplancalender_gid,
    bp.bussplan_id,
    bpfin.finyear_id,
    pp.prod_code,
    pp.uom_code,
    sum((pp.proc_qty)::numeric) AS qty,
    pp.proc_rate AS rate,
    sum(((pp.proc_qty)::numeric * (pp.proc_rate)::numeric)) AS amount
   FROM ((((public.pg_trn_tbussplan bp
     JOIN public.pg_trn_tbussplanfinyear bpfin ON ((((bp.bussplan_id)::text = (bpfin.bussplan_id)::text) AND ((bp.pg_id)::text = (bpfin.pg_id)::text))))
     JOIN public.pg_trn_tbussplanproduce bpprod ON ((((bp.pg_id)::text = (bpprod.pg_id)::text) AND ((bp.bussplan_id)::text = (bpprod.bussplan_id)::text) AND ((bpfin.finyear_id)::text = (bpprod.finyear_id)::text) AND ((bpfin.prod_code)::text = (bpprod.prod_code)::text))))
     JOIN public.pg_trn_tprocureproduct pp ON ((((bpprod.pg_id)::text = (pp.pg_id)::text) AND ((bpprod.prod_code)::text = (pp.prod_code)::text))))
     JOIN public.core_mst_tfinyear fin ON ((((bpfin.finyear_id)::text = (fin.finyear_id)::text) AND ((fin.status_code)::text = 'A'::text))))
  WHERE ((bp.status_code)::text <> 'I'::text)
  GROUP BY bpfin.finyear_id, bpfin.bussplancalender_gid, pp.prod_code, pp.uom_code, pp.proc_rate, bp.pg_id, bp.bussplan_id;


ALTER TABLE public.procureproduct_view OWNER TO postgres;

--
-- Name: screendata_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.screendata_view AS
 SELECT concat((core_mst_tscreendata.screen_code COLLATE "default"), ',', regexp_replace(((core_mst_tscreendata.ctrl_id)::text COLLATE "default"), '[ ]'::text, ''::text, 'g'::text), ',', replace(((core_mst_tscreendata.data_field)::text COLLATE "default"), 'null'::text, ''::text)) AS concat_field,
    core_mst_tscreendata.screendata_gid,
    core_mst_tscreendata.screen_code,
    core_mst_tscreendata.lang_code,
    core_mst_tscreendata.ctrl_type_code,
    core_mst_tscreendata.ctrl_id,
    core_mst_tscreendata.data_field,
    core_mst_tscreendata.label_desc,
    core_mst_tscreendata.tooltip_desc,
    core_mst_tscreendata.default_label_desc,
    core_mst_tscreendata.default_tooltip_desc,
    core_mst_tscreendata.ctrl_slno,
    core_mst_tscreendata.created_date,
    core_mst_tscreendata.created_by,
    core_mst_tscreendata.updated_date,
    core_mst_tscreendata.updated_by
   FROM public.core_mst_tscreendata;


ALTER TABLE public.screendata_view OWNER TO postgres;

--
-- Name: shgmember_profile_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.shgmember_profile_view AS
 SELECT pm.pg_id,
    shg.state_id,
    shg.district_id,
    shg.block_id,
    shg.gp_id AS panchayat_id,
    shg.village_id,
    shg.shg_code AS shg_id,
    shg.shg_name,
    shg.shg_name_local,
    m.member_code AS shg_member_id,
    m.member_name AS shg_member_name,
    m.member_name_local AS shg_member_name_local,
    m.relation_type AS relation_code,
    m.relation_name,
    m.relation_name_local,
    m.gender,
    m.social_category,
        CASE
            WHEN (m.dob IS NOT NULL) THEN 'Y'::text
            ELSE 'N'::text
        END AS dob_flag,
    m.dob,
    m.age,
    m.age_as_on,
        CASE
            WHEN (m.phone1_mobile_no = 0) THEN NULL::bigint
            ELSE m.phone1_mobile_no
        END AS member_phone,
    m.created_date,
    m.last_updated_date AS updated_date
   FROM ((public.pg_mst_tpanchayatmapping pm
     JOIN public.shg_profile_consolidated shg ON ((((pm.panchayat_id)::integer = shg.gp_id) AND (shg.is_active = true))))
     JOIN public.member_profile_consolidated m ON ((((shg.shg_code)::text = (m.shg_code)::text) AND (shg.is_active = true))));


ALTER TABLE public.shgmember_profile_view OWNER TO postgres;

--
-- Name: shgmember_addressdesc_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.shgmember_addressdesc_view AS
 SELECT mem.pg_id,
    addr.member_id AS member_address_id,
    mem.shg_member_id,
    mem.shg_member_name,
    mem.shg_member_name_local,
    1 AS address_type,
    public.fn_get_masterdesc(('LOKOS_MEM_ADDRTYPE'::character varying)::public.udd_code, ('1'::character varying)::public.udd_code, ('en_US'::character varying)::public.udd_code) AS address_type_desc,
    ((COALESCE(addr.add1_line1, ''::character varying))::text ||
        CASE
            WHEN (addr.add1_line2 IS NOT NULL) THEN ((chr(13) || chr(10)) || (addr.add1_line2)::text)
            ELSE ''::text
        END) AS member_addr,
    addr.add1_postal_code AS postal_code,
    addr.state_id,
    addr.district_id,
    addr.block_id,
    addr.gp_id AS panchayat_id,
    addr.village_id,
    public.fn_get_statedesc((addr.state_id)::public.udd_int) AS state_name,
    public.fn_get_districtdesc((addr.district_id)::public.udd_int) AS district_name,
    public.fn_get_blockdesc((addr.block_id)::public.udd_int) AS block_name,
    public.fn_get_panchayatdesc((addr.gp_id)::public.udd_int) AS panchayat_name,
    public.fn_get_villagedesc((addr.village_id)::public.udd_int) AS village_name,
    addr.created_date,
    addr.last_updated_date AS updated_date
   FROM (public.shgmember_profile_view mem
     JOIN public.member_profile_consolidated addr ON (((mem.shg_member_id = addr.member_id) AND (mem.state_id = addr.state_id))));


ALTER TABLE public.shgmember_addressdesc_view OWNER TO postgres;

--
-- Name: shgmember_bank_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.shgmember_bank_view AS
 SELECT mem.pg_id,
    mem.shg_member_id,
    mem.shg_member_name,
    membank.bank1_account_no AS account_no,
    bank.bank_id,
    bank.bank_code,
    bank.bank_name,
    branch.bank_branch_code,
    branch.bank_branch_name,
    membank.bank1_account_type AS account_type,
    membank.bank1_branch_code AS mem_branch_code,
    membank.bank1_ifsc_code AS ifsc_code,
    1 AS is_default_account,
    public.fn_get_masterdesc(('LOKOS_ISDEFAULT'::character varying)::public.udd_code, ('1'::character varying)::public.udd_code, ('en_US'::character varying)::public.udd_code) AS is_default_account_desc,
    branch.created_date,
    branch.updated_date
   FROM (((public.shgmember_profile_view mem
     JOIN public.member_profile_consolidated membank ON (((mem.shg_member_id = membank.member_id) AND (mem.state_id = membank.state_id))))
     LEFT JOIN public.bank_branch_master branch ON ((((membank.bank1_ifsc_code)::text = (branch.ifsc_code)::text) AND (((branch.bank_branch_code)::public.udd_code)::text = (membank.bank1_branch_code)::text))))
     LEFT JOIN public.bank_master bank ON (((branch.bank_code)::text = (bank.bank_code)::text)));


ALTER TABLE public.shgmember_bank_view OWNER TO postgres;

--
-- Name: shgmember_bankdesc_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.shgmember_bankdesc_view AS
 SELECT mem.pg_id,
    mem.shg_member_id,
    mem.shg_member_name,
    membank.bank1_account_no AS account_no,
    bank.bank_id,
    bank.bank_code,
    bank.bank_name,
    branch.bank_branch_code,
    branch.bank_branch_name,
    membank.bank1_account_type AS account_type,
    membank.bank1_branch_code AS mem_branch_code,
    membank.bank1_ifsc_code AS ifsc_code,
    1 AS is_default_account,
    public.fn_get_masterdesc(('LOKOS_ISDEFAULT'::character varying)::public.udd_code, ('1'::character varying)::public.udd_code, ('en_US'::character varying)::public.udd_code) AS is_default_account_desc,
    branch.created_date,
    branch.updated_date
   FROM (((public.shgmember_profile_view mem
     JOIN public.member_profile_consolidated membank ON (((mem.shg_member_id = membank.member_id) AND (mem.state_id = membank.state_id))))
     LEFT JOIN public.bank_branch_master branch ON ((((membank.bank1_ifsc_code)::text = (branch.ifsc_code)::text) AND (((branch.bank_branch_code)::public.udd_code)::text = (membank.bank1_branch_code)::text))))
     LEFT JOIN public.bank_master bank ON (((branch.bank_code)::text = (bank.bank_code)::text)));


ALTER TABLE public.shgmember_bankdesc_view OWNER TO postgres;

--
-- Name: shgmember_profiledesc_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.shgmember_profiledesc_view AS
 SELECT pm.pg_id,
    shg.shg_code AS shg_id,
    shg.shg_name,
    shg.shg_name_local,
    m.member_code AS shg_member_id,
    m.member_name AS shg_member_name,
    m.member_name_local AS shg_member_name_local,
    m.relation_type AS relation_code,
    public.fn_get_masterdesc(('LOKOS_MEM_RELATION'::character varying)::public.udd_code, (m.relation_type)::public.udd_code, ('en_US'::character varying)::public.udd_code) AS relation_desc,
    m.relation_name,
    m.relation_name_local,
    m.gender,
    public.fn_get_masterdesc(('LOKOS_GENDER'::character varying)::public.udd_code, (m.gender)::public.udd_code, ('en_US'::character varying)::public.udd_code) AS gender_desc,
    m.social_category,
    public.fn_get_masterdesc(('LOKOS_SOCIAL_CAT'::character varying)::public.udd_code, (m.social_category)::public.udd_code, ('en_US'::character varying)::public.udd_code) AS social_category_desc,
        CASE
            WHEN (m.dob IS NOT NULL) THEN 'Y'::text
            ELSE 'N'::text
        END AS dob_flag,
    m.dob,
    m.age,
    m.age_as_on,
    m.phone1_mobile_no AS member_phone,
    shg.state_id,
    shg.district_id,
    shg.block_id,
    shg.gp_id AS panchayat_id,
    shg.village_id,
    public.fn_get_statedesc((shg.state_id)::public.udd_int) AS state_name,
    public.fn_get_districtdesc((shg.district_id)::public.udd_int) AS district_name,
    public.fn_get_blockdesc((shg.block_id)::public.udd_int) AS block_name,
    public.fn_get_panchayatdesc((shg.gp_id)::public.udd_int) AS panchayat_name,
    public.fn_get_villagedesc((shg.village_id)::public.udd_int) AS village_name,
    m.created_date,
    m.last_updated_date AS updated_date
   FROM ((public.pg_mst_tpanchayatmapping pm
     JOIN public.shg_profile_consolidated shg ON ((((pm.panchayat_id)::integer = shg.gp_id) AND (shg.is_active = true))))
     JOIN public.member_profile_consolidated m ON ((((shg.shg_code)::text = (m.shg_code)::text) AND (shg.is_active = true))));


ALTER TABLE public.shgmember_profiledesc_view OWNER TO postgres;

--
-- Name: village_master_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.village_master_view AS
 SELECT village_master.village_id,
    village_master.state_id,
    village_master.district_id,
    village_master.block_id,
    village_master.panchayat_id,
    village_master.village_code,
    village_master.village_name_en,
    village_master.village_name_local,
    village_master.is_active,
    village_master.created_date,
    village_master.created_by,
    village_master.updated_date,
    village_master.updated_by
   FROM public.village_master
 LIMIT 1;


ALTER TABLE public.village_master_view OWNER TO postgres;

--
-- PostgreSQL database dump complete
--

