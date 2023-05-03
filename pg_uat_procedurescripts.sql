"pg_get_functiondef"
"CREATE OR REPLACE PROCEDURE public.empty_resultset(INOUT _result_set refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	open _result_set for select 
							'0' as ""error_code"",
							'Error' as ""error_desc"";
end ;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_dbd_commprodsurplus(_prod_code udd_code, _finyear_name udd_desc, _block_code udd_code, _role_code udd_code, _user_code udd_user, _lang_code udd_code, INOUT _result_commoditydtl refcursor DEFAULT 'rs.commoditydtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$

Declare
	/*
		Created by   : Mangai
		Created date : 08-03-2022

		Updated by   : Vijayavel
		Updated date : 06-04-2022

		SP Code		 : B01CPSG01
	*/

begin
	if _prod_code = '' then
		_prod_code := null;
	end if;
	
	open _result_commoditydtl for select 
									a.*,
									-- formula is told by charles on 07-04-2022
									round(a.""Est_Production"" - a.""Act_Production"",4) as surplus
								from 
								(
									select 
										 pg_id,
										 prod_type_code,
										 fn_get_masterdesc('QCD_PROD_TYPE',prod_type_code,_lang_code)as ""Commodity_Type"",
										 prod_code,
										 fn_get_productdesc(prod_code, _lang_code) as ""Commodity_Name"",
										 no_of_pgs as ""No_Of_PGS"",
										 no_of_mahila_kisan as ""No_of_Mahila_Kisan"",
										 bp_uom_code as uom_code,
										 fn_get_masterdesc('QCD_UOM',bp_uom_code,_lang_code)as ""uom"",
										 fn_get_bpprodharvestqty(pg_id,finyear_id,prod_code) as ""Est_Production"",
										 fn_get_uomconv(prod_uom_code,bp_uom_code,fn_get_finyear_procprodqty(pg_id,finyear_id,prod_code)) as ""Act_Production""	
									from 		 commprodsurp_view
									where 	pg_id in (select fn_get_pgid(_block_code, _role_code, _user_code))
									and  	finyear_id  = _finyear_name
									and 	prod_code = coalesce(_prod_code,prod_code)
								) as a;
	/*
	open _result_commoditydtl for select 
									 pg_id,
									 prod_type_code,
									 fn_get_masterdesc('QCD_PROD_TYPE',prod_type_code,_lang_code)as ""Commodity_Type"",
									 prod_code,
									 fn_get_productdesc(prod_code, _lang_code) as ""Commodity_Name"",
									 No_Of_PGS as ""No_Of_PGS"",
									 No_of_Mahila_Kisan as ""No_of_Mahila_Kisan"",
									 uom_code,
									 fn_get_masterdesc('QCD_UOM',uom_code,_lang_code)as ""uom"",
									 Est_Production as ""Est_Production"",
									 Act_Production as ""Act_Production"",
									 surplus
						from 		 commprodsurp_view
						where        prod_code = coalesce(_prod_code,prod_code)
						and 		 pg_id in (select fn_get_pgid(_block_code, _role_code, _user_code))
						and          finyear_name  = _finyear_name;
	*/					
	END;
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_dbd_overview(_block_code udd_code, _role_code udd_code, _user_code udd_code, _lang_code udd_code, INOUT _result_overviewtop refcursor DEFAULT 'rs.overviewtop'::refcursor, INOUT _result_pgformation refcursor DEFAULT 'rs.pgformation'::refcursor, INOUT _result_totalproduct refcursor DEFAULT 'rs.totalproduct'::refcursor, INOUT _result_bankacc refcursor DEFAULT 'rs.bankacc'::refcursor, INOUT _result_workingcapital refcursor DEFAULT 'rs.workingcapital'::refcursor)
 LANGUAGE plpgsql
AS $procedure$

Declare
	/*
		Created by   : Mangai
		Created date : 14-03-2022
		SP Code		 : B01OVVG01
		
		Updated by   : Mohan
		Updated date : 11-04-2022
		
	*/
	v_block_id udd_int := 0;

begin
	-- $ to ₹ Symbol -- 
-- 	set LC_MONETARY='en_IN';
	
    select 	fn_get_blockid(_block_code)::udd_int 
	into	 v_block_id ;
	-- overview top
	open _result_overviewtop for select
	                               fn_get_pgcount(_block_code,_role_code,_user_code) as Producer_Groups,
								   fn_get_villagecount(_block_code,_role_code,_user_code) as Villages,
								   fn_get_pgmemberid(_block_code,_role_code,_user_code) as Members,
-- 								   cast (fn_get_sanctionedamount(_block_code,_role_code,_user_code)as money)::udd_text as Capital_Disbursement;
								   '₹ ' || fn_get_sanctionedamount(_block_code,_role_code,_user_code) as Capital_Disbursement;
								  

	-- PG Formation
	open _result_pgformation for select
											   to_char(formation_date::udd_date,'YYYY'),
											   count(pg_id)
								 from          pg_mst_tproducergroup
								 where         pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
								 and           status_code = 'A'
								 and 		   formation_date >= now()::udd_date - interval '10 years'
								 group by      to_char(formation_date::udd_date,'YYYY')
								 order by      to_char(formation_date::udd_date,'YYYY') asc;
														 
	-- Total Product 
	open _result_totalproduct for select 
										   pp.prod_code,
										   fn_get_productdesc(pp.prod_code, _lang_code) || '(' ||
										   pp.uom_code || ')' as prod_desc,
-- 										   fn_get_masterdesc('QCD_UOM',pp.uom_code,_lang_code) as prod_desc,
										   sum(pp.proc_qty) as totalquantity
							  from         pg_trn_tprocureproduct  as pp
							  inner join   core_mst_tproduct as pro
							  on 	       pro.prod_code = pp.prod_code 
							  and 		   pro.status_code = 'A'
							  inner join   pg_mst_tproducergroup as pg
							  on           pg.pg_id       = pp.pg_id
							  and 		   pg.status_code = 'A'
							  inner join   pg_mst_tproductmapping as promap
							  on           pro.prod_code   = promap.prod_code
							  and		   pg.pg_id 	   = promap.pg_id
							  inner join   core_mst_tfinyear as fy
							  on 		   now()::udd_date between fy.finyear_start_date
							  and 		   fy.finyear_end_date 
							  and 		   fy.status_code = 'A'
							  and		   pp.proc_date between fy.finyear_start_date
							  and 		   fy.finyear_end_date 
							  where 	   pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
							  and 		   pp.status_code = 'A'
							  group by     pp.prod_code, pp.uom_code
							  order by     totalquantity desc
							  limit        6;
								  
	-- With Bank
	open _result_bankacc for   select 
										fn_get_masterdesc('QCD_DBD_BANKSTS','QCD_DBD_WITHBANK',_lang_code) as title,
									  	fn_get_withbankcount(_block_code,_role_code,_user_code) as count
							   union all
							   select
										fn_get_masterdesc('QCD_DBD_BANKSTS','QCD_DBD_WITHOUTBANK',_lang_code) as title,
	                                  	fn_get_withoutbankcount(_block_code,_role_code,_user_code) as count ;
						   					   
	-- Amount with working capital
	open _result_workingcapital for select 
											fn_get_masterdesc('QCD_DBD_CAPDISBSUMM','QCD_DBD_CAPITAL',_lang_code) as Title,
											fn_get_workingcapital(_block_code,_role_code,_user_code) as coalesce,
-- 											cast(fn_get_workingcapital(_block_code,_role_code,_user_code)as money)::udd_text as coalesce_withsymbol
											'₹' || fn_get_workingcapital(_block_code,_role_code,_user_code) as coalesce_withsymbol
											
									union all
									select
											fn_get_masterdesc('QCD_DBD_CAPDISBSUMM','QCD_DBD_INFRA',_lang_code) as Title,
										    fn_get_infrastructure(_block_code,_role_code,_user_code) as coalesce,
-- 										    cast(fn_get_infrastructure(_block_code,_role_code,_user_code)as money)::udd_text as coalesce_withsymbol;
										    '₹' || fn_get_infrastructure(_block_code,_role_code,_user_code) as coalesce_withsymbol;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_dbd_summary(_block_code udd_code, _role_code udd_code, _user_code udd_code, _lang_code udd_code, INOUT _result_summary refcursor DEFAULT 'rs.summary'::refcursor)
 LANGUAGE plpgsql
AS $procedure$

Declare
	/*
		Created by   : Mangai
		Created date : 17-03-2022
		SP Code		 : B01SUMG01
		
		Updated by   : Mohan
		Updated date : 11-04-2022
	*/
	
begin
	-- $ to ₹ Symbol -- 
-- 	set LC_MONETARY='en_IN';
	
	-- Summary
	open _result_summary for select   
							   1 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_PGFORMED',_lang_code) as indicators,
							   fn_get_pgcount(_block_code,_role_code,_user_code) as ""Achievement_value""
											  
						union all 
							select   
							   2 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_MAHKIS_PG',_lang_code) as indicators,
							   fn_get_mahilakisancount(_block_code,_role_code,_user_code)as ""Achievement_value""
						union all
						
							select
							   3 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_VLGPGFORMED',_lang_code) as indicators,
							   fn_get_villagecount(_block_code,_role_code,_user_code) as ""Achievement_value""

						union all
							select
							   4 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_PGWBAC',_lang_code) as indicators,
							   fn_get_withbankcount(_block_code,_role_code,_user_code) as ""Achievement_value""
							   
						union all
							select
							   5 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_UDYMIT',_lang_code) as indicators,  
							   fn_get_umdeployedcount(_block_code,_role_code,_user_code) as ""Achievement_value""
											  
						         
						union all
							select
							   6 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_ACTIVI',_lang_code) as indicators,
							   fn_get_activitycount(_block_code,_role_code,_user_code) as ""Achievement_value""
						
						union all
							select
							   7 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_PGSBUP',_lang_code) as indicators,
							   fn_get_bpsubmitedcount(_block_code,_role_code,_user_code) as ""Achievement_value""
							   
   					    union all
							select
							   8 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_BPA',_lang_code) as indicators,
							   fn_get_bpapprovedcount(_block_code,_role_code,_user_code) as ""Achievement_value""
											  
						union all
							select
							   9 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_LAA',_lang_code) as indicators, 
-- 							   cast(fn_get_loanamntapplied(_block_code,_role_code,_user_code)as money)::udd_text as ""Achievement_value""
							   fn_get_loanamntapplied(_block_code,_role_code,_user_code) as ""Achievement_value""
						         
						union all
							select
							   10 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_TLAA',_lang_code) as indicators, 
-- 							   cast(fn_get_loanamntapproved(_block_code,_role_code,_user_code)as money)::udd_text as ""Achievement_value""
							   fn_get_loanamntapproved(_block_code,_role_code,_user_code) as ""Achievement_value""
											  
						union all
							select
							   11 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_TGR',_lang_code) as indicators, 
-- 								cast(fn_get_grantreceivedcount(_block_code,_role_code,_user_code)as money)::udd_text as ""Achievement_value""												  
								fn_get_grantreceivedcount(_block_code,_role_code,_user_code) as ""Achievement_value""												  
						         
						union all
							select
							   12 as slno,
							   fn_get_masterdesc('QCD_DBD_SUMM','QCD_TLB',_lang_code) as indicators, 
-- 							   cast(fn_get_loanborrowed(_block_code,_role_code,_user_code)as money)::udd_text as ""Achievement_value"";
							   fn_get_loanborrowed(_block_code,_role_code,_user_code) as ""Achievement_value"";
								 
	end ;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_bussplan(_pg_id udd_code, _bussplan_id udd_code, _lang_code udd_code, INOUT _result_bussplan refcursor DEFAULT 'rs_bussplan'::refcursor, INOUT _result_product refcursor DEFAULT 'rs_product'::refcursor, INOUT _result_calendar refcursor DEFAULT 'rs_calendar'::refcursor, INOUT _result_revenue refcursor DEFAULT 'rs_revenue'::refcursor, INOUT _result_procurement refcursor DEFAULT 'rs_procurement'::refcursor, INOUT _result_procurementcost refcursor DEFAULT 'rs_procurementcost'::refcursor, INOUT _result_attachment refcursor DEFAULT 'rs_attach'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
/*
	Created By : Mohan S
	Created Date : 16-12-2021
	SP Code : B04BPSG01
*/
	config_path udd_text := '';
begin
	select  fn_get_configvalue('server_atm_path')
	into 	config_path;
	-- stored procedure body 
	-- BUSINESS PLAN
	open _result_bussplan for select 	
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 bp.bussplan_gid as bussplan_gid,
								 bp.bussplan_id as bussplan_id,
								 bp.blockofficer_id as blockofficer_id,
								 bp.reviewer_type_code as reviewer_type_code,
								 fn_get_masterdesc('QCD_REVIEWER_TYPE',bp.reviewer_type_code,_lang_code) as reviewer_type_desc,
								 bom.bomanager_id as clf_block_id,
								 bp.reviewer_code as reviewer_code,
								 bp.reviewer_name as reviewer_name,
								 bp.bussplan_review_flag as bussplan_review_flag,
								 fn_get_masterdesc('QCD_YES_NO',bp.bussplan_review_flag,_lang_code) as review_flag_desc,
								 bp.ops_exp_amount as ops_exp_amount,
								 bp.net_pl_amount as net_pl_amount,
								 bp.bussplan_remark as bussplan_remark,
								 bp.status_code as status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as status_desc,
								 um.udyogmitra_name as ""udyog mitra"",
								 fn_get_villagedesc(pgadd.village_id) as village_desc,
								 fn_get_villagedesc(pgadd.village_id) as Village,
								 fn_get_panchayatdesc(pgadd.panchayat_id) as panchayat_desc,
							     fn_get_blockdesc(pgadd.block_id) as block_desc,
								 coalesce(count(bpl.*),0) as download_count,
								 bp.period_from as period_from,
								 bp.period_to as period_to,
 								 case 
 								 when bom.bomanager_name <> '' or bom.bomanager_name <> null then
 									 'Y' 
 									 else 
 									 'N' 
 								 end as ""CLF Available"",
-- 								 '' as ""CLF Available"",
								 bom.bomanager_name as ""clf/bo"",
								 coalesce(bom.bomanager_id,bp.reviewer_code) as ""clf/bo Reviwer id"",
								 coalesce(bom.bomanager_name,bp.reviewer_name) as ""clf/bo reviwer name"",
								 fn_get_lokoscaste(pg.pg_id,'1') as SC,
								 fn_get_lokoscaste(pg.pg_id,'2') as ST,
								 fn_get_lokoscaste(pg.pg_id,'3') as OBC,
								 fn_get_lokoscaste(pg.pg_id,'4') as General,
								 fn_get_lokoscaste(pg.pg_id,'99') as ""Others"",
								 sum(fn_get_lokoscaste(pg.pg_id,'1')::udd_int + 
									 fn_get_lokoscaste(pg.pg_id,'2')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'3')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'4')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'99')::udd_int ) as Total,
								 to_char(bp.row_timestamp,'DD-MM-YYYY HH:MI:SS:MS')  as row_timestamp
				  from 			 pg_mst_tproducergroup as pg
				  inner join 	 pg_mst_taddress as pgadd on pg.pg_id = pgadd.pg_id
				  and 			 pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
				  inner join     pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 			 um.tran_status_code in ('A','P')
				  left join 	 pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and 		     bp.bussplan_id = _bussplan_id
				  left join      pg_mst_tbomanager as bom on pg.pg_id = bom.pg_id 
				  left join      pg_trn_tbussplandownloadlog as bpl on bp.pg_id = bpl.pg_id
				  and 			 bp.bussplan_id = bpl.bussplan_id
				  where 		 pg.pg_id = _pg_id
				  group by 		 pg.pg_id,pg.pg_name,bp.bussplan_gid,bp.bussplan_id,bp.blockofficer_id,
				  bp.reviewer_type_code,bom.bomanager_id,bp.reviewer_code,bp.bussplan_review_flag,bp.ops_exp_amount,
				  bp.net_pl_amount,bp.bussplan_remark,bp.status_code,um.udyogmitra_name,pgadd.village_id,
				  pgadd.panchayat_id,pgadd.block_id,bp.period_from,bp.period_to,bom.bomanager_name,bp.row_timestamp;
				  
	-- PRODUCT
	open _result_product for select 
							 bpp.bussplanprod_gid,
							 bpp.pg_id,
							 bpp.bussplan_id,
							 pm.prod_code,
							 fn_get_productdesc(pm.prod_code, _lang_code) as prod_desc,
							 protran.prod_desc,
							 bpp.prod_type_code,
							 bpp.uom_code,
							 fn_get_masterdesc('QCD_UOM',bpp.uom_code,_lang_code) as uom_desc,
							 coalesce(bpp.selection_flag,null) as selection_flag,
							 fn_get_masterdesc('QCD_YES_NO',bpp.selection_flag,_lang_code) as selection_flag_desc
				  from 		 pg_mst_tproductmapping as pm  
				  left join  pg_trn_tbussplanproduct as bpp on pm.prod_code = bpp.prod_code 
				  and 	 	 bpp.bussplan_id = _bussplan_id
				  inner join core_mst_tproducttranslate as protran on pm.prod_code = protran.prod_code 
				  and 		 protran.lang_code = _lang_code 
				  inner join core_mst_tproduct as prod on pm.prod_code = prod.prod_code
				  and 		 prod.status_code = 'A'
				  where 	 pm.pg_id = _pg_id;
				  
							 
	-- CALENDAR
	open _result_calendar for select distinct
									bpp.bussplanproduce_gid,
									bpp.finyear_id,
									bpp.bussplan_id,
									bpp.pg_id,
									bppr.bussplanprod_gid,
									fn_get_lldate(bpp.produce_month::udd_date,_lang_code) as produce_month,
-- 									to_char(bpp.produce_month::udd_date,'Mon-YY') as produce_month,
									bpp.produce_month as produce_month_desc,
									bpp.prod_type_code,
									bpp.prod_code,
							 		concat(fn_get_productdesc(bpp.prod_code, _lang_code),'(',
										   fn_get_masterdesc('QCD_UOM',bppr.uom_code,_lang_code) ,
										   ')')as prod_desc,
									bppr.uom_code,
							 		fn_get_masterdesc('QCD_UOM',bppr.uom_code,_lang_code) as uom_desc,
									bpp.sowing_flag,
									bpp.harvesting_qty
							from 	pg_trn_tbussplanproduce as bpp
							inner join pg_trn_tbussplanproduct as bppr on bpp.bussplan_id = bppr.bussplan_id
							and 	   bpp.pg_id = bppr.pg_id and bpp.prod_code = bppr.prod_code 
							left join  pg_trn_tbussplanfinyear as bpf on bpp.bussplan_id = bpf.bussplan_id
							and 	bpp.prod_code = bpf.prod_code
							where 	bpp.bussplan_id = _bussplan_id;
							
	-- REVENUE
	
	DROP TABLE IF EXISTS temptable_bussplanprocure ;

	CREATE TEMP TABLE temptable_bussplanprocure AS
		SELECT DISTINCT 'Procurement'::text AS title,
		bpfin.pg_id,
		bpfin.bussplancalender_gid,
		bpfin.bussplan_id,
		bpprod.finyear_id,
		bpprod.prod_code,
		prod.uom_code,
		sum(bpprod.harvesting_qty::numeric) AS qty,
		bpfin.prodprocure_rate AS rate,
		sum(bpprod.harvesting_qty::numeric * bpfin.prodprocure_rate::numeric) AS amount
	   FROM pg_trn_tbussplanfinyear bpfin
		 JOIN pg_trn_tbussplanproduct prod ON bpfin.pg_id::text = prod.pg_id::text AND bpfin.bussplan_id::text = prod.bussplan_id::text AND bpfin.prod_code::text = prod.prod_code::text
		 JOIN pg_trn_tbussplanproduce bpprod ON bpfin.pg_id::text = bpprod.pg_id::text AND bpfin.bussplan_id::text = bpprod.bussplan_id::text AND bpfin.finyear_id::text = bpprod.finyear_id::text AND bpfin.prod_code::text = bpprod.prod_code::text
	  where bpfin.pg_id = _pg_id
	  and   bpfin.bussplan_id = _bussplan_id
	  GROUP BY bpprod.finyear_id, bpfin.bussplancalender_gid, bpprod.prod_code, prod.uom_code, bpfin.prodprocure_rate, bpfin.pg_id, bpfin.bussplan_id;
	
	DROP TABLE IF EXISTS temptable_bussplanrevenue ;

	CREATE TEMP TABLE temptable_bussplanrevenue AS
		 SELECT 'Revenue'::text AS title,
				bpfin.pg_id,
				bpfin.bussplancalender_gid,
				bpfin.bussplan_id,
				bpprod.finyear_id,
				bpprod.prod_code,
				prod.uom_code,
				sum(bpprod.harvesting_qty::numeric) AS qty,
				bpfin.prodrevenue_rate AS rate,
				sum(bpprod.harvesting_qty::numeric * bpfin.prodrevenue_rate::numeric) AS amount
			   FROM pg_trn_tbussplanfinyear bpfin
				 JOIN pg_trn_tbussplanproduct prod ON bpfin.pg_id::text = prod.pg_id::text AND bpfin.bussplan_id::text = prod.bussplan_id::text AND bpfin.prod_code::text = prod.prod_code::text
				 JOIN pg_trn_tbussplanproduce bpprod ON bpfin.pg_id::text = bpprod.pg_id::text AND bpfin.bussplan_id::text = bpprod.bussplan_id::text AND bpfin.finyear_id::text = bpprod.finyear_id::text AND bpfin.prod_code::text = bpprod.prod_code::text
				 JOIN core_mst_tfinyear fin ON bpfin.finyear_id::text = fin.finyear_id::text AND fin.status_code::text = 'A'::text
			  where bpfin.pg_id = _pg_id
	  		  and   bpfin.bussplan_id = _bussplan_id
			  GROUP BY bpprod.finyear_id, bpfin.bussplancalender_gid, bpprod.prod_code, prod.uom_code, bpfin.prodrevenue_rate, bpfin.pg_id, bpfin.bussplan_id;

	DROP TABLE IF EXISTS temptable_procurementcosttotal ;

	CREATE TEMP TABLE temptable_procurementcosttotal AS
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
			sum(ppv.amount::numeric - brv.amount::numeric ) AS amt
		   FROM temptable_bussplanprocure brv
			 JOIN temptable_bussplanrevenue ppv ON brv.finyear_id::text = ppv.finyear_id::text AND brv.prod_code::text = ppv.prod_code::text AND brv.uom_code::text = ppv.uom_code::text AND brv.bussplancalender_gid = ppv.bussplancalender_gid
		  where brv.pg_id = _pg_id
		  and	brv.bussplan_id = _bussplan_id
		  GROUP BY brv.pg_id, brv.bussplan_id, brv.finyear_id;

	open _result_revenue for select 
								title,
								'' as title_code,
								'N' as disable_flag,
								bussplancalender_gid as gid,
								finyear_id,
								prod_code,
							 	fn_get_productdesc(prod_code, _lang_code) as prod_desc,
							 	'' as code,
								uom_code,
							 	fn_get_masterdesc('QCD_UOM',uom_code,_lang_code) as uom_desc,
								qty,
								rate,
								amount
					from 		temptable_bussplanrevenue
		union all
								select 
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_REVTOTAL',_lang_code) as title,
									'QCD_REVTOTAL' as title_code,
									'B' as disable_flag,
									0 as gid,
									finyear_id,
									'-' as prod_code,
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_REV',_lang_code) as prod_desc,
									'QCD_REV' as revenue_code,
									'-' as uom_code,
									'-' as uom_desc,
									0 as qty,
									0 as rate,
									sum(amount)
						from 		temptable_bussplanrevenue
						group by 	title,finyear_id
		union all
								select 
									title,
									'' as title_code,
									'N' as disable_flag,
									bussplancalender_gid as gid,
									finyear_id,
									prod_code,
									fn_get_productdesc(prod_code, _lang_code) as prod_desc,
									'' as code,
									uom_code,
									fn_get_masterdesc('QCD_UOM',uom_code,_lang_code) as uom_desc,
									qty,
									rate,
									amount
						from 		temptable_bussplanprocure
	  	 union all
								select 
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_PROCTOTAL',_lang_code) as title,
									'QCD_PROCTOTAL' as title_code,
									'B' as disable_flag,
									0 as gid,
									finyear_id,
									'-' as prod_code,
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_PROC',_lang_code) as prod_desc,
									'QCD_PROC' as procure_code,
									'-' as uom_code,
									'-' as uom_desc,
									0 as qty,
									0 as rate,
									sum(amount)
						from 		temptable_bussplanprocure
						group by 	title,finyear_id
	   union all 
	   							select 
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_PROC',_lang_code) as title,
									'QCD_PROC' as title_code,
									'Y' as disable_flag,
									brv.bussplancalender_gid as gid,
									brv.finyear_id,
									brv.prod_code,
							 		fn_get_productdesc(brv.prod_code, _lang_code) as prod_desc,
							 		'' as code,
									brv.uom_code,
									fn_get_masterdesc('QCD_UOM',brv.uom_code,_lang_code) as uom_desc,
									brv.qty as qty,
									sum(brv.rate - ppv.rate) as rate,
									sum((brv.qty) * (brv.rate - ppv.rate)) as amt
							from    temptable_bussplanrevenue as brv
							inner join temptable_bussplanprocure as ppv on brv.finyear_id = ppv.finyear_id
							and 	brv.prod_code = ppv.prod_code 
							and 	brv.uom_code = ppv.uom_code
							and 	brv.bussplancalender_gid = ppv.bussplancalender_gid
							where 	brv.pg_id = _pg_id
							and 	brv.bussplan_id = _bussplan_id
							group by brv.prod_code,brv.bussplancalender_gid,
							brv.uom_code,brv.finyear_id,brv.qty
		union all 
	   							select 
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_PROCCOSTOTAL',_lang_code) as title,
									'QCD_PROCCOSTOTAL' as title_code,
									'B' as disable_flag,
									0 as gid,
									finyear_id,
									'-' as prod_code,
							 		fn_get_masterdesc('QCD_FINPROJDESC','QCD_OPERPROF',_lang_code) as prod_desc,
							 		'QCD_OPERPROF' as operprof_code,
									'-' as uom_code,
									'-' as uom_desc,
									0 as qty,
									0 as rate,
									amt
							from    temptable_procurementcosttotal 
							
		union all
	   							select 
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_OPEREXP',_lang_code) as title,
									'QCD_OPEREXP' as title_code,
									'Y' as disable_flag,
									bussplanexpenses_gid,
									finyear_id,
									'-' as prod_code,
							 		fn_get_masterdesc('QCD_FINPROJDESC','QCD_OPEREXP',_lang_code) as prod_desc,
							 		'QCD_OPEREXP' as operexp_code,
									'-' as uom_code,
									'-' as uom_desc,
									0 as qty,
									0 as rate,
									operating_expenses as amt
							from    pg_trn_tbussplanexpenses
							where 	pg_id = _pg_id
							and 	bussplan_id = _bussplan_id
							
		union all 
								
								select 
									fn_get_masterdesc('QCD_FINPROJDESC','QCD_NETPROF',_lang_code) as title,
									'QCD_NETPROF' as title_code,
									'B' as disable_flag,
									0 as gid,
									pctv.finyear_id,
									'-' as prod_code,
							 		fn_get_masterdesc('QCD_FINPROJDESC','QCD_NETPROF',_lang_code) as prod_desc,
							 		'QCD_NETPROF' as netprof_code,
									'-' as uom_code,
									'-' as uom_desc,
									0 as qty,
									0 as rate,
									sum(pctv.amt - bpe.operating_expenses) as amt
							from    temptable_procurementcosttotal as pctv
							inner join pg_trn_tbussplanexpenses as bpe 
							on 		pctv.bussplan_id = bpe.bussplan_id 
							and 	pctv.finyear_id = bpe.finyear_id
							where 	pctv.pg_id = _pg_id
							and 	pctv.bussplan_id = _bussplan_id
							group by pctv.finyear_id;
							
	 DROP TABLE IF EXISTS temptable_procureproduct ;

	CREATE TEMP TABLE temptable_procureproduct AS
	SELECT 'Procure'::text AS title,
			bpfin.pg_id,
			bpfin.bussplancalender_gid,
			bpfin.bussplan_id,
			bpfin.finyear_id,
			pp.prod_code,
			pp.uom_code,
			sum(pp.proc_qty::numeric) AS qty,
			pp.proc_rate AS rate,
			sum(pp.proc_qty::numeric * pp.proc_rate::numeric) AS amount
		   FROM pg_trn_tbussplanfinyear bpfin
			 JOIN pg_trn_tbussplanproduce bpprod ON bpfin.pg_id::text = bpprod.pg_id::text AND bpfin.bussplan_id::text = bpprod.bussplan_id::text AND bpfin.finyear_id::text = bpprod.finyear_id::text AND bpfin.prod_code::text = bpprod.prod_code::text
			 JOIN pg_trn_tprocureproduct pp ON bpprod.pg_id::text = pp.pg_id::text AND bpprod.prod_code::text = pp.prod_code::text
		   where  bpfin.pg_id = _pg_id
		   and    bpfin.bussplan_id = _bussplan_id
		   GROUP BY bpfin.finyear_id, bpfin.bussplancalender_gid, pp.prod_code, pp.uom_code, pp.proc_rate, bpfin.pg_id, bpfin.bussplan_id;

							
	-- PROCUREMENT
	open _result_procurement for select 
								title,
								finyear_id,
								prod_code,
								fn_get_masterdesc('QCD_UOM',uom_code,_lang_code) as uom_desc,
								qty,
								rate,
								amount
					from 		temptable_procureproduct;
					
	-- PROCUREMNET COST
	open _result_procurementcost for select '1';
									/*'Procurement Cost' as title,
									brv.prod_code,
									fn_get_masterdesc('QCD_UOM',brv.uom_code,_lang_code) as uom_desc,
									sum(brv.qty - ppv.qty) as qty,
									sum(brv.rate - ppv.rate) as rate,
									sum((brv.qty - ppv.qty) * (brv.rate - ppv.rate)) as amt
							from    bussplanrevenue_view as brv
							inner join procureproduct_view as ppv on brv.finyear_id = ppv.finyear_id
							and 	brv.prod_code = ppv.prod_code 
							and 	brv.uom_code = ppv.uom_code
							where 	brv.pg_id = _pg_id
							and 	brv.bussplan_id = _bussplan_id
							group by brv.prod_code,brv.uom_code;*/
				  
	-- ATTACHMENT
	open _result_attachment for select 
								   bussplanattachment_gid,
								   doc_type_code,
								   fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
								   doc_subtype_code,
								   fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
								   file_path,
								   file_name,
								   attachment_remark,
								   created_by
				  from 			   pg_trn_tbussplanattachment
				  where 		   bussplan_id = _bussplan_id;
									
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_bussplan_old(_pg_id udd_code, _bussplan_id udd_code, _lang_code udd_code, INOUT _result_bussplan refcursor DEFAULT 'rs_bussplan'::refcursor, INOUT _result_product refcursor DEFAULT 'rs_product'::refcursor, INOUT _result_calendar refcursor DEFAULT 'rs_calendar'::refcursor, INOUT _result_attachment refcursor DEFAULT 'rs_attach'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
/*
	Created By : Mohan S
	Created Date : 16-12-2021
	SP Code : B04BPSG01
*/
begin
	-- stored procedure body 
	-- BUSINESS PLAN
	open _result_bussplan for select 	
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 bp.bussplan_gid as bussplan_gid,
								 bp.bussplan_id as bussplan_id,
								 bp.blockofficer_id as blockofficer_id,
								 bp.reviewer_type_code as reviewer_type_code,
								 fn_get_masterdesc('QCD_REVIEWER_TYPE',bp.reviewer_type_code,_lang_code) as reviewer_type_desc,
								 clf.clf_id as clf_block_id,
								 bp.reviewer_code as reviewer_code,
								 bp.bussplan_review_flag as bussplan_review_flag,
								 fn_get_masterdesc('QCD_YES_NO',bp.bussplan_review_flag,_lang_code) as review_flag_desc,
								 bp.ops_exp_amount as ops_exp_amount,
								 bp.net_pl_amount as net_pl_amount,
								 bp.bussplan_remark as bussplan_remark,
								 bp.status_code as status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as status_desc,
								 um.udyogmitra_name as ""udyog mitra"",
								 fn_get_villagedesc(pgadd.village_id) as village_desc,
								 fn_get_panchayatdesc(pgadd.panchayat_id) as panchayat_desc,
							     fn_get_blockdesc(pgadd.block_id) as block_desc,
								 bp.period_from as period_from,
								 bp.period_to as period_to,
								 'Y' as ""CLF Available"",
								 clf.clf_name as ""clf/bo"",
								 clf.clf_officer_id as ""clf/bo Reviwer id"",
								 clf.clf_officer_name as ""clf/bo reviwer name"",
								 3 as SC,
								 4 as ST,
								 2 as OBC,
								 8 as ""Others"",
								 17 as Total,
								 to_char(bp.row_timestamp,'DD-MM-YYYY HH:MI:SS:MS')  as row_timestamp
				  from 			 pg_mst_tproducergroup as pg
				  inner join 	 pg_mst_taddress as pgadd on pg.pg_id = pgadd.pg_id
				  and 			 pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
				  inner join     pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 			 um.tran_status_code = 'A'
				  left join 	 pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and 		     bp.bussplan_id = _bussplan_id
				  left join      pg_mst_tclf as clf on pg.pg_id = clf.pg_id 
				  where 		 pg.pg_id = _pg_id;
				  
	-- PRODUCT
	open _result_product for select 
							 bpp.bussplanprod_gid,
							 bpp.pg_id,
							 bpp.bussplan_id,
							 pm.prod_code,
							 protran.prod_desc,
							 prod.uom_code,
							 fn_get_masterdesc('QCD_UOM',prod.uom_code,_lang_code) as uom_desc,
							 bpp.selection_flag,
							 fn_get_masterdesc('QCD_YES_NO',bpp.selection_flag,_lang_code) as selection_flag_desc
				  from 		 pg_mst_tproductmapping as pm  
				  left join  pg_trn_tbussplanproduct as bpp on pm.prod_code = bpp.prod_code 
				  and 	 	 bpp.bussplan_id = _bussplan_id
				  inner join core_mst_tproducttranslate as protran on pm.prod_code = protran.prod_code 
				  and 		 protran.lang_code = _lang_code 
				  inner join core_mst_tproduct as prod on pm.prod_code = prod.prod_code
				  where 	 pm.pg_id = _pg_id;
				  
							 
	-- CALENDAR
	open _result_calendar for select 
									bpp.bussplanproduce_gid,
									bpp.finyear_id,
									bpp.produce_month,
									bpp.prod_type_code,
									bpp.prod_code,
									bpp.uom_code,
									bpp.sowing_flag,
									bpp.harvesting_qty,
									bpf.prod_rate,
									sum(bpp.harvesting_qty * bpf.prod_rate) as total_amt
							from 	pg_trn_tbussplanproduce as bpp
							left join  pg_trn_tbussplanfinyear as bpf on bpp.bussplan_id = bpf.bussplan_id
							and 	bpp.prod_code = bpf.prod_code
							where 	bpp.bussplan_id = _bussplan_id
							group by bpp.finyear_id, bpp.produce_month,bpp.prod_code,bpp.uom_code,
							bpp.sowing_flag,bpp.harvesting_qty,bpf.prod_rate,bpp.bussplanproduce_gid;
				  
	-- ATTACHMENT
	open _result_attachment for select 
								   bussplanattachment_gid,
								   doc_type_code,
								   fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
								   doc_subtype_code,
								   fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
								   file_path,
								   file_name,
								   attachment_remark
				  from 			   pg_trn_tbussplanattachment
				  where 		   bussplan_id = _bussplan_id;
									
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_collection(_coll_gid udd_int, _lang_code udd_code, INOUT _result_collection refcursor DEFAULT 'rs_collection'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mangai
		Created Date : 11-08-2022
		SP Code : B06COLCUD
	*/
begin
	-- stored procedure body
	
	open _result_collection for  select      
											 c.coll_gid,
											 s.pg_id,
											 s.collected_amount,
											 s.inv_amount,
											 s.buyer_name,
											 c.inv_no,
											 c.coll_no,
											 c.coll_date as received_date,
											 c.pay_mode_code,
											 fn_get_masterdesc('QCD_PAY_MODE',c.pay_mode_code,_lang_code) as pay_mode_desc,
											 c.pay_ref_no,
											 c.coll_amount as received_amount,
											 (s.inv_amount - s.collected_amount) as bal_amount
								 from        pg_trn_tcollection as c
								 inner join  pg_trn_tsale as s
								 on          s.pg_id    = c.pg_id
								 and         s.inv_no   = c.inv_no
								 where       c.coll_gid = _coll_gid;
					
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_config(_config_name udd_desc, INOUT _result_configfetch refcursor DEFAULT 'rs_config'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mangai
		Created Date : 21-04-2022
		SP Code : 
	*/
begin
	-- stored procedure body
	open _result_configfetch for select 	
										config_value
								 from   core_mst_tconfig
								 where  config_name = _config_name
								 and    status_code = 'A';
								 
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_dependentlist(_parent_code udd_code, _lang_code udd_code, INOUT _result_one refcursor DEFAULT 'rs_resultone'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 21-03-2022
		SP Code : B01DEPF01
	*/
	v_depend_parent_code 	udd_code := '';
begin
	select 		depend_parent_code into v_depend_parent_code 
	from 		core_mst_tmaster
	where 		master_code = _parent_code 
	and 		parent_code = 'SYS'
	and 		status_code = 'A' ;

	-- stored procedure body
	open _result_one for select 
							master_code as depend_code,
							fn_get_masterdesc(parent_code,master_code,_lang_code) as depend_desc
				  from 		core_mst_tmaster as mst
				  where 	parent_code = v_depend_parent_code
				  and		status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_funddisbursement(_pg_id udd_code, _funddisb_id udd_code, _lang_code udd_code, INOUT _result_funddisb refcursor DEFAULT 'rs_funddisb'::refcursor, INOUT _result_funddisbtranche refcursor DEFAULT 'rs_funddisbtranche'::refcursor, INOUT _result_fundrepaymt refcursor DEFAULT 'rs_fundrepaymt'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 03-01-2022
		SP Code : B05FDBG02
	*/
begin
	-- stored procedure body
	open _result_funddisb for select
								 fd.funddisb_id as ""FundDisb ID"",
								 fd.funddisb_gid as ""FundDisb GID"",
								 fr.bussplan_id as ""BP ID"",
								 fr.fundreq_id as fundreq_id,
								 pg.pg_id as ""PG ID"",
								 pg.pg_name as ""PG Name"",
								 fn_get_fundrequesttotamt(fr.pg_id,fr.fundreq_id)::udd_amount as ""FR Amount"",
-- 								 sum(fn_get_fundrequesttotamt(fr.pg_id, fr.fundreq_id)::udd_amount - fd.sanctioned_amount::udd_amount)  as ""FR Amount"",
-- 								 fr.tot_fundreq_amount as ""FR Amount"",
								 to_char(fd.row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') as row_timestamp,
								 fd.funddisb_type_code as funddisb_type_code,
								 fn_get_masterdesc('QCD_FUND_TYPE',fd.funddisb_type_code,_lang_code) as ""Head"",
								 fd.routing_inst_code as ""routing_inst_code"",		
								 fn_get_masterdesc('QCD_ROUTE_INST',fd.routing_inst_code,_lang_code) as ""Fund Routing Inst"",
								 fd.source_inst_code as ""source_inst_code"",		
								 fn_get_masterdesc('QCD_FUND_SOURCE',fd.source_inst_code,_lang_code) as ""Source"",
								 fd.loan_acc_no as ""Account_No"",
								 fd.sanctioned_date as ""Sanctioned Date"",
								 fd.sanctioned_amount as ""Sanctioned Amount"",
								 fd.interest_rate as ""Interest Rate"",
								 fd.repymt_tenure as ""Repayment Tenure (Years)"",
								 fd.repymt_freq_code as repymt_freq_code,
								 fn_get_masterdesc('QCD_PYMT_FREQ',fd.repymt_freq_code,_lang_code) as ""Repayment Frequency"",
								 '72' as ""Instalment Nos."",
								 fd.collateral_type_code as collateral_type_code,
								 fn_get_masterdesc('QCD_COLLATERAL_TYPE',fd.collateral_type_code,_lang_code) as ""Collateral Type"",
								 fd.collateral_amount as ""Collateral Amount"",
								 fn_get_trancheamount(_pg_id,_funddisb_id) as ""Total Amount Received"",
								 coalesce(fdrpyv.tot_principal_amount,0) as ""Princ. Amount Repaid"",
								 coalesce(fdrpyv.tot_interest_amount,0) as ""Int. Amount Repaid"",
								 coalesce(fn_get_trancheamount(_pg_id,_funddisb_id) - 
								 coalesce(fdrpyv.tot_principal_amount,0),0) as ""O/S Principle"",
								 fd.status_code as status_code,
								 fn_get_masterdesc('QCD_FUNDDISB_STATUS',fd.status_code,_lang_code) as ""Status_desc""
				  from 			 pg_mst_tproducergroup as pg
				  inner join 	 pg_trn_tfundrequisition as fr on pg.pg_id = fr.pg_id
				  and 			 fr.status_code = 'A'
				  inner join 	 pg_trn_tfunddisbursement as fd on fr.fundreq_id = fd.fundreq_id
				  left join 	 pg_fundrepymttotal_view as fdrpyv on fd.pg_id = fdrpyv.pg_id
				  and 			 fd.loan_acc_no = fdrpyv.loan_acc_no
				  where 		 fd.pg_id = _pg_id
				  and 			 fd.funddisb_id = _funddisb_id
				  group by fd.funddisb_id,fr.bussplan_id,fr.fundreq_id, pg.pg_id,pg.pg_name,fd.row_timestamp,
				  fd.funddisb_type_code,fd.routing_inst_code,fd.source_inst_code,fd.loan_acc_no,fd.sanctioned_date,
				  fd.sanctioned_amount,fd.interest_rate,fd.repymt_tenure,fd.repymt_freq_code,fd.collateral_type_code,
				  fdrpyv.tot_paid_amount,fdrpyv.tot_principal_amount,fdrpyv.tot_interest_amount,fd.status_code,fr.pg_id,
				  fd.collateral_amount,fd.funddisb_gid;
				  
	-- FUNDDISB TRANCHE 
	open _result_funddisbtranche for select 
										dt.funddisbtranche_gid,
								 		dt.tranche_no,
										dt.tranche_amount,
										db.sanctioned_date,
										dt.received_date,
										dt.tranche_date,
										dt.tranche_status_code as tranche_status_code,
										fn_get_masterdesc('QCD_TRANCHE_STATUS',dt.tranche_status_code,_lang_code) as tranche_status_desc
				  from 			 		pg_trn_tfunddisbtranche as dt
				  inner join    		pg_trn_tfunddisbursement as db on dt.pg_id = db.pg_id
				  and 					dt.funddisb_id = db.funddisb_id
				  where 		 		dt.pg_id = _pg_id
				  and 				    dt.funddisb_id = _funddisb_id
				  order by		 		dt.funddisbtranche_gid;
				  
	-- FUNDREPAYMENT 
	open _result_fundrepaymt for select 	
								 		rpy.pymt_date,
										rpy.pay_mode_code,
									    fn_get_masterdesc('QCD_PAY_MODE',rpy.pay_mode_code,_lang_code) as pay_mode_desc,
										rpy.principal_amount,
										rpy.interest_amount,
										rpy.other_amount,
										rpy.pymt_ref_no,
										rpy.pymt_remarks
				  from 			 		pg_trn_tfundrepymt as rpy
				  inner join 			pg_trn_tfunddisbursement as fd
				  on 					rpy.pg_id = fd.pg_id
				  and					rpy.loan_acc_no = fd.loan_acc_no
				  and					fd.status_code = 'A'
				  where 		 		rpy.pg_id = _pg_id
				  and 					fd.funddisb_id = _funddisb_id
				  and 			 		rpy.status_code = 'A'
				  order by		 		rpy.status_code,rpy.fundrepymt_gid;	  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_fundrepymtdtl(_fundrepymt_gid udd_int, _pg_id udd_code, _lang_code udd_code, INOUT _result_fundrepymt refcursor DEFAULT 'rs_fundrepymt'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 03-01-2022
		SP Code : B05FRPG02
	*/
	-- stored procedure body
	open _result_fundrepymt for select 	
							fr.fundrepymt_gid,
							fr.pg_id,
							fr.loan_acc_no,
							fr.pymt_date,						
							fr.pay_mode_code,
							fn_get_masterdesc('QCD_PAY_MODE',fr.pay_mode_code,_lang_code) as acchead_desc,
							fr.paid_amount,
							fr.pymt_ref_no,
							fr.principal_amount,
							fr.interest_amount,
							fr.other_amount,
							fr.pymt_remarks,														
							fr.status_code,
							fn_get_masterdesc('QCD_STATUS',fr.status_code,_lang_code) as status_desc,
							fd.source_inst_code,
							fn_get_masterdesc('QCD_FUND_SOURCE',fd.source_inst_code,_lang_code) as source_desc,
							fr.created_date,
							fr.created_by,
							fr.updated_date,
							fr.updated_by							
               from 		pg_trn_tfundrepymt 	as fr
			   inner join   pg_trn_tfunddisbursement as fd
			   on           fr.loan_acc_no = fd.loan_acc_no
			   and          fd.pg_id       = _pg_id
			   where 	    fundrepymt_gid = _fundrepymt_gid
			   and 		    fr.pg_id 	   = _pg_id
		       and          fr.status_code <> 'I'
			   and          fd.status_code <> 'I'
		   	   order by 	fundrepymt_gid;				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_fundrequisition(_pg_id udd_code, _bussplan_id udd_code, _fundreq_id udd_code, _lang_code udd_code, INOUT _result_fundrequisition refcursor DEFAULT 'rs_funrequisition'::refcursor, INOUT _result_fundrequirements refcursor DEFAULT 'rs_funrequirements'::refcursor, INOUT _result_fundattachment refcursor DEFAULT 'rs_fundattach'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 31-12-2021
		SP Code : B05FDRG01
	*/
	config_path udd_text := '';
begin
	select  fn_get_configvalue('server_atm_path')
	into 	config_path;
	-- stored procedure body
	-- FUND REQUISITION
	if _fundreq_id <> '0' then
	open _result_fundrequisition for select 
								 fr.fundreq_id as fundreq_id,
								 fr.fundreq_gid as fundreq_gid,
								 fr.bussplan_id as bussplan_id,
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 um.udyogmitra_name as udyogmitra_name,
								 fn_get_villagedesc(addr.village_id) as village_desc,
								 fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
								 fn_get_blockdesc(addr.block_id) as block_desc,
								 bp.period_from as Period_from,
								 bp.period_to as Period_to,
								 fr.tot_fundreq_amount as tot_fundreq_amount,
								 bp.ops_exp_amount as ops_exp_amount,
								 bp.net_pl_amount as net_pl_amount,
								 case 
								 when clf.clf_name <> '' or clf.clf_name <> null then
									 'Y' 
									 else 
									 'N' 
								 end as ""Is_CLF_Available"",
								 clf.clf_name as CLF_BO,
								 bp.clf_block_id,
								 bp.reviewer_code as CLF_BO_Reviewer_ID,
-- 								 fn_get_masterdesc('QCD_REVIEWER_TYPE',bp.reviewer_type_code,_lang_code) as CLF_BO_Reviewer_ID,
								 coalesce(clf.clf_officer_id,bp.reviewer_code) as CLF_BO_Reviewer_ID,
								 coalesce(clf.clf_officer_name,bp.reviewer_name) as CLF_BO_Reviewer_Name,
								 fn_get_lokoscaste(pg.pg_id,'1') as SC,
								 fn_get_lokoscaste(pg.pg_id,'2') as ST,
								 fn_get_lokoscaste(pg.pg_id,'3') as OBC,
								 fn_get_lokoscaste(pg.pg_id,'4') as General,
								 fn_get_lokoscaste(pg.pg_id,'99') as ""Others"",
								 sum(fn_get_lokoscaste(pg.pg_id,'1')::udd_int + 
									 fn_get_lokoscaste(pg.pg_id,'2')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'3')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'4')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'99')::udd_int ) as Total,
								 COALESCE(fr.fundreq_purpose,'') as fundreq_purpose,
								 fr.fundreq_remark as Remarks,
								 fr.status_code as status,
								 coalesce(fn_get_masterdesc('QCD_STATUS',fr.status_code,_lang_code),'') as Status_desc,
								 to_char(fr.row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') as row_timestamp
				  from 		 pg_trn_tfundrequisition as fr
				  inner join pg_mst_tproducergroup as pg on fr.pg_id = pg.pg_id
				  inner join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
				  and 		 addr.addr_type_code = 'QCD_ADDRTYPE_REG' 
				  inner join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 		 um.tran_status_code in ('A','P')
				  inner join pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and 		 bp.bussplan_id = fr.bussplan_id 
				  and 		 bp.status_code = 'A'
				  left  join  pg_mst_tclf as clf on pg.pg_id = clf.pg_id
				  and 		 fr.fundreq_id = _fundreq_id
				  where 	 fr.pg_id = _pg_id
				  and 		 fr.bussplan_id = _bussplan_id
				  group by fr.fundreq_id,fr.fundreq_gid,fr.bussplan_id,pg.pg_id,pg.pg_name,
				  um.udyogmitra_name,addr.village_id,addr.panchayat_id,addr.block_id,bp.period_from,
				  bp.period_to,fr.tot_fundreq_amount,bp.net_pl_amount,clf.clf_name,clf.clf_name,
				  bp.clf_block_id,bp.reviewer_type_code,bp.reviewer_code,bp.reviewer_name,bp.ops_exp_amount,
				  clf.clf_officer_id,clf.clf_officer_name
				  order by 	 fr.status_code,fr.fundreq_gid;
	 else
			open _result_fundrequisition for select
								 '0' as fundreq_id,
								 bp.bussplan_id as bussplan_id,
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 um.udyogmitra_name as udyogmitra_name,
								 fn_get_villagedesc(addr.village_id) as village_desc,
								 fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
								 fn_get_blockdesc(addr.block_id) as block_desc,
								 bp.period_from as Period_from,
								 bp.period_to as Period_to,
								 '0' as tot_fundreq_amount,
								 bp.ops_exp_amount as ops_exp_amount,
								 bp.net_pl_amount as net_pl_amount,
								 case 
								 when clf.clf_name <> '' or clf.clf_name <> null then
									 'Y' 
									 else 
									 'N' 
								 end as ""Is_CLF_Available"",
								 clf.clf_name as CLF_BO,
								 bp.clf_block_id,
								 bp.reviewer_code as CLF_BO_Reviewer_ID,
-- 								 fn_get_masterdesc('QCD_REVIEWER_TYPE',bp.reviewer_type_code,_lang_code) as CLF_BO_Reviewer_ID,
								 bp.reviewer_code as CLF_BO_Reviewer_Name,
								 fn_get_lokoscaste(pg.pg_id,'1') as SC,
								 fn_get_lokoscaste(pg.pg_id,'2') as ST,
								 fn_get_lokoscaste(pg.pg_id,'3') as OBC,
								 fn_get_lokoscaste(pg.pg_id,'4') as General,
								 fn_get_lokoscaste(pg.pg_id,'99') as ""Others"",
								 sum(fn_get_lokoscaste(pg.pg_id,'1')::udd_int + 
									 fn_get_lokoscaste(pg.pg_id,'2')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'3')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'4')::udd_int +
									 fn_get_lokoscaste(pg.pg_id,'99')::udd_int ) as Total,
								 '' as fundreq_purpose,
								 '' as Remarks,
								 'Draft' as Status_desc
				  from 		 pg_mst_tproducergroup as pg
				  inner join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
				  and 		 addr.addr_type_code = 'QCD_ADDRTYPE_REG' 
				  inner join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 		 um.tran_status_code in ('A','P')
				  inner join pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and 		 bp.status_code = 'A'
				  left join  pg_trn_tfundrequisition as fr
				  on 		 pg.pg_id = fr.pg_id
				  and 		 fr.bussplan_id = bp.bussplan_id
				  left  join pg_mst_tclf as clf on pg.pg_id = clf.pg_id
				  where 	 bp.bussplan_id = _bussplan_id 
				  and		 bp.pg_id = _pg_id
				  group by bp.bussplan_id,fr.fundreq_gid,fr.bussplan_id,pg.pg_id,pg.pg_name,
				  um.udyogmitra_name,addr.village_id,addr.panchayat_id,addr.block_id,bp.period_from,
				  bp.period_to,fr.tot_fundreq_amount,bp.net_pl_amount,clf.clf_name,clf.clf_name,
				  bp.clf_block_id,bp.reviewer_type_code,bp.reviewer_code,bp.reviewer_name,bp.ops_exp_amount,
				  clf.clf_officer_id,clf.clf_officer_name,bp.status_code
				  order by 	 bp.status_code;
		end if;
				  
	-- FUN REQUIERMENTS
	open _result_fundrequirements for select 
								   fundreq_gid,
								   routing_inst_code,
								   fn_get_masterdesc('QCD_ROUTE_INST',routing_inst_code,_lang_code) as routing_inst_desc,
								   fundreq_head_code,
								   fn_get_masterdesc('QCD_FUNDREQ_HEAD',fundreq_head_code,_lang_code) as fundreq_head_desc,
				 				   fundreq_amount
				  from 			   pg_trn_tfundrequisitiondtl
				  where 		   bussplan_id = _bussplan_id
				  and 			   pg_id = _pg_id;
				  
	-- ATTACHMENT
	open _result_fundattachment for select 
								   fundreqattachment_gid,
								   pg_id,
								   bussplan_id,
								   doc_type_code,
								   fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
								   doc_subtype_code,
								   fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
								   config_path || file_path as file_path,
								   file_name,
								   attachment_remark,
								   created_date,
								   created_by,
								   updated_date,
								   updated_by
				  from 			   pg_trn_tfundreqattachment
				  where 		   fundreq_id = _fundreq_id;
									
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_incomeexpensedtl(_pg_id udd_code, _incomeexpense_gid udd_int, _lang_code udd_code, INOUT _result_incomeexpense refcursor DEFAULT 'rs_incomeexpense'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 03-01-2022
		SP Code : B05IEXCUD
	*/
	-- stored procedure body
	-- Income Expense --
	open _result_incomeexpense for select 	
							incomeexpense_gid,
							pg_id,
							acchead_type_code,
							fn_get_masterdesc('QCD_ACC_HEAD_TYPE',acchead_type_code,_lang_code) as acchead_type_desc,
							acchead_code,
							fn_get_masterdesc('QCD_ACC_HEAD',acchead_code,_lang_code) as acchead_desc,							tran_date,
							tran_date,
							dr_amount,
							cr_amount,
							narration_code,
							fn_get_masterdesc('QCD_ACC_NARRATION',narration_code,_lang_code) as narration_desc,
							tran_ref_no,
							tran_remark,
							pay_mode_code,
							fn_get_masterdesc('QCD_PAY_MODE',pay_mode_code,_lang_code) as pay_mode_desc,
							status_code,
							fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
							created_date,
							created_by,
							updated_date,
							updated_by							
				  from 		pg_trn_tincomeexpense 				 
				  where 	pg_id 		= _pg_id
				  and 		incomeexpense_gid = _incomeexpense_gid
		   		  order by 	incomeexpense_gid;				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_invoice(_pg_id udd_code, _inv_no udd_code, _lang_code udd_code, INOUT _result_invoice refcursor DEFAULT 'rs_invoice'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mangai
		Created Date : 22-08-2022
		SP Code : 
	*/
begin
	-- stored procedure body
	
	open _result_invoice for select      sp.adjust_type_code,
										 fn_get_masterdesc('QCD_ADJUST_TYPE',sp.adjust_type_code,_lang_code) as adjust_type_desc,
										 sp.adjust_date,
										 sp.inv_no,
										 sp.prod_code,
										 fn_get_productdesc(sp.prod_code,_lang_code) as prod_desc,
										 sp.grade_code,
										 concat(fn_get_productdesc(sp.prod_code,_lang_code),'-', sp.grade_code) as prod_grade,
										 sp.prod_type_code,
										 fn_get_masterdesc('QCD_PROD_TYPE',sp.prod_type_code,_lang_code) as prod_type_desc,
										 sp.sale_qty as invoiced_qty,
										 sp.rec_slno
							 from        pg_trn_tsale as s
							 inner join  pg_trn_tsaleproduct as sp
							 on          s.pg_id    = sp.pg_id
							 and         s.inv_no   = sp.inv_no
							 and         s.inv_date = sp.inv_date
							 where       s.pg_id = _pg_id
							 and         s.inv_no = _inv_no;
					
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_invoiceadjustment(_pg_id udd_code, _inv_no udd_code, _prod_code udd_code, _grade_code udd_code, _rec_slno udd_int, _lang_code udd_code, INOUT _result_salelst refcursor DEFAULT 'rs_salelst'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 18-08-2022
		SP Code : B04SALG02
	*/
begin
	-- stored procedure body
	-- SALE
	open _result_salelst for select 
									pg.pg_name,
									s.pg_id,
									sp.adjust_type_code,
									fn_get_masterdesc('QCD_ADJUST_TYPE',sp.adjust_type_code,_lang_code) as adjust_type_desc,
									s.inv_no,
									sp.adjust_date,
									sp.prod_code,
									fn_get_productdesc(sp.prod_code,_lang_code) as prod_desc,
									concat(fn_get_productdesc(sp.prod_code,_lang_code),'&',
	   								fn_get_masterdesc('QCD_GRADE',sp.grade_code,_lang_code)) as prodgrade,
									sp.grade_code,
									fn_get_masterdesc('QCD_GRADE',sp.grade_code,_lang_code) as grade_desc,
									sp.sale_qty,
									sp.inv_qty
						from 		pg_trn_tsale as s 
						inner join  pg_trn_tsaleproduct as sp on s.pg_id = sp.pg_id
						and 		s.inv_date = sp.inv_date
						and 		s.inv_no = sp.inv_no
						inner join  core_mst_tproduct as p on sp.prod_code = p.prod_code
						inner join  pg_mst_tproducergroup as pg on s.pg_id = pg.pg_id 
						and 		pg.status_code <> 'I'
						where 		sp.pg_id 	   = _pg_id
						and 		sp.inv_no 	   = _inv_no
						and         sp.prod_code   = _prod_code
						and         sp.grade_code  = _grade_code
						and 		sp.rec_slno	   = _rec_slno	
						and 		s.status_code  = 'A';
						

end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_masterdependdescription(_parent_code udd_code, _depend_code udd_code, _lang_code udd_code, INOUT _result_fetchmstdesc refcursor DEFAULT 'rs_rlfetchmstdesc'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 29-12-2021
		SP Code : B01CMBF02
	*/
	v_depend_parent_code 	udd_code := '';
begin
	-- stored procedure body
			select 		depend_parent_code into v_depend_parent_code 
			from 		core_mst_tmaster
			where 		master_code = _parent_code 
			and 		parent_code = 'SYS'
			and 		status_code = 'A' ;
			
	if (v_depend_parent_code <> '' and _depend_code <> '') then
		open _result_fetchmstdesc for  select 		
													a.depend_parent_code,
													a.depend_code,
													a.master_code,
													fn_get_masterdesc(a.parent_code,a.master_code,_lang_code) as master_desc
										from 		core_mst_tmaster as a 
										where 		a.parent_code = _parent_code 
										and 		a.depend_code = _depend_code
										and 		a.status_code = 'A';
	else
		open _result_fetchmstdesc for  select 		
													a.depend_parent_code,
													a.depend_code,
													a.master_code,
													fn_get_masterdesc(a.depend_parent_code,a.depend_code,_lang_code) as depend_desc,
													fn_get_masterdesc(a.parent_code,a.master_code,_lang_code) as master_desc
										from 		core_mst_tmaster as a 
										where 		a.parent_code = _parent_code
										and 		a.status_code = 'A';
	
	/*
	if (v_depend_parent_code <> '' and _depend_code <> '') then
		open _result_fetchmstdesc for  select 		b.master_code,
													b.master_desc,
													a.depend_parent_code,
													a.depend_code,
													fn_get_masterdesc(a.parent_code,a.master_code,_lang_code) as depend_desc
										from 		core_mst_tmaster as a 
										inner join 	core_mst_tmastertranslate as b 
										on 			a.parent_code = b.parent_code 
										and 		a.master_code = b.master_code 
										where 		a.parent_code = _parent_code 
										and 		a.depend_code = _depend_code 
										and 		b.lang_code = _lang_code
										and 		a.status_code = 'A'
										order  by 	b.master_desc;
	
	/*
		open _result_fetchmstdesc for  select 		b.master_code,
													b.master_desc,
													a.depend_parent_code,
													a.depend_code,
													fn_get_masterdesc(a.depend_parent_code,a.depend_code,_lang_code) as depend_desc
										from 		core_mst_tmaster as a 
										inner join 	core_mst_tmastertranslate as b 
										on 			a.parent_code = b.parent_code 
										and 		a.master_code = b.master_code 
										where 		a.parent_code = v_depend_parent_code 
										and 		a.master_code = _depend_code 
										and 		b.lang_code = _lang_code
										and 		a.status_code = 'A';
										
	*/
	else
		open _result_fetchmstdesc for  select 		b.master_code,
													b.master_desc,
													a.depend_parent_code,
													a.depend_code,
													fn_get_masterdesc(a.depend_parent_code,a.depend_code,_lang_code) as depend_desc
										from 		core_mst_tmaster as a 
										inner join 	core_mst_tmastertranslate as b 
										on 			a.parent_code = b.parent_code 
										and 		a.master_code = b.master_code 
										where 		a.parent_code = _parent_code 
										and 		b.lang_code = _lang_code
										and 		a.status_code = 'A'
										order  by 	b.master_desc;
	*/
	end if;			  				 		
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_masterdescription(_parent_code udd_code, _lang_code udd_code, INOUT _result_fetchmstdesc refcursor DEFAULT 'rs_rlfetchmstdesc'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
	/*
		Created By : Mohan S
		Created Date : 21-12-2021
		SP Code : B01CMBF01
	*/
begin
	-- stored procedure body
	open _result_fetchmstdesc for  select 		b.master_code as master_code,
												b.master_desc as master_desc
									from 		core_mst_tmaster as a 
									inner join 	core_mst_tmastertranslate as b 
									on 			a.parent_code = b.parent_code 
									and 		a.master_code = b.master_code 
									where 		a.parent_code = _parent_code 
									and 		b.lang_code = _lang_code
									and 		a.status_code = 'A';
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_masterdtl(_master_code udd_code, _parent_code udd_code, _lang_code udd_code, INOUT _result_mstdtl refcursor DEFAULT 'rs_mstdtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
	/*
		Created By : Mohan S
		Created Date : 11-01-2022
		SP Code : B01MSTF01
	*/
begin
	-- stored procedure body 
		open _result_mstdtl  for 	select 		b.master_code as master_code,
												a.master_gid as master_gid,
												b.mastertranslate_gid as mastertranslate_gid,
												a.parent_code as parent_code,
												a.depend_parent_code as depend_parent_code,
												a.depend_code as depend_code,
												fn_get_masterdesc('QCD_STATUS',a.status_code,_lang_code) as Status,
												to_char(a.row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') as row_timestamp,
 												c.lang_name as lang_name,
 												c.lang_code as lang_code,
												b.master_desc as master_desc
									from 		core_mst_tmaster as a 
									inner join 	core_mst_tmastertranslate as b 
									on 			a.parent_code = b.parent_code 
									and 		a.master_code = b.master_code 
									inner join  core_mst_tlanguage as c 
									on 			b.lang_code = c.lang_code
									where 		a.master_code = _master_code 
									and 		a.parent_code = _parent_code
-- 									and 		c.lang_code <> 'en_US'
									and 		a.status_code = 'A';
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_menulist(_role_code udd_code, _lang_code udd_code, INOUT _result_menufetch refcursor DEFAULT 'rs_menufetch'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 16-12-2021
		SP Code : B01MNUF01
	*/
begin
	-- stored procedure body
	open _result_menufetch for select 	Distinct
								 rol.role_code as role_code,
								 rol.role_name as role_name,
								 rol.status_code as status_code,
								 fn_get_masterdesc('QCD_STATUS',rol.status_code,_lang_code) as status_desc,
				  				 rolmenu.menu_code as menu_code,
								 fn_get_menudesc(rolmenu.menu_code,_lang_code) as menu_desc,
-- 								 mentran.menu_desc as menu_desc,
								 menu.parent_code as parent_code,
								 menu.url_action_method as url_action_method,
								 menu.menu_type_code as menu_type_code,
								 rolmenu.add_flag as add_flag,
								 rolmenu.modifiy_flag as modifiy_flag,
								 rolmenu.view_flag as view_flag,
								 rolmenu.auth_flag as auth_flag,
								 rolmenu.print_flag as print_flag,
								 rolmenu.inactive_flag as inactive_flag,
								 rolmenu.deny_flag as deny_flag,
								 menu.menu_slno
				  from 		 core_mst_trole as rol
				  inner join core_mst_trolemenurights as rolmenu 
				  on 		 rolmenu.role_code = rol.role_code
				  inner join core_mst_tmenutranslate as mentran 
				  on 		 mentran.menu_code = rolmenu.menu_code
				  inner join core_mst_tmenu as menu 
				  on 		 menu.menu_code = mentran.menu_code
				  and 	 	 menu.status_code = 'A'
				  where		 rol.status_code = 'A' 
				  and 		 rolmenu.role_code = _role_code 
-- 				  and   	 mentran.lang_code = _lang_code
				  and 		 menu.parent_code <> 'SYS'
				  and (	rolmenu.add_flag 		= 'Y' 	or rolmenu.modifiy_flag 	= 'Y'
				  or 	rolmenu.view_flag 		= 'Y' 	or rolmenu.auth_flag 		= 'Y' 
				  or 	rolmenu.print_flag 		= 'Y' 	or rolmenu.inactive_flag 	= 'Y'
				  or 	rolmenu.deny_flag       = 'Y')
				  order by 	 menu.menu_slno asc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_menutranslate(_menutranslate_gid udd_int, _lang_code udd_code, INOUT _result_menutranslate refcursor DEFAULT 'rs_menutranslate'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 07-04-2022
		SP Code      : B01METG01
	*/
	-- Menu Translate Details--
	open _result_menutranslate for select 
							menutranslate_gid,
							menu_code,
							lang_code,	
							menu_desc					
				  from 		core_mst_tmenutranslate 				 
				  where 	menutranslate_gid 	= _menutranslate_gid
		   		  order by 	menutranslate_gid;				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_messagedtl(_msg_code udd_code, _lang_code udd_code, INOUT _result_message refcursor DEFAULT 'rs_message'::refcursor, INOUT _result_messagetranslate refcursor DEFAULT 'rs_messagetranslate'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01SCRCUD
	*/
	-- Message Details
	open _result_message for select 	
							msg_gid,
							msg_code,											
							status_code,
							fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
							created_date,
							created_by,
							updated_date,
							updated_by							
				  from 		core_mst_tmessage 				 
				  where 	msg_code 	= _msg_code
		   		  order by 	msg_gid;	


-- Message Translate Details--
	open _result_messagetranslate for select 
							msgtranslate_gid,
							msg_code,
							lang_code,	
							msg_desc					
				  from 		core_mst_tmessagetranslate 				 
				  where 	msg_code 		= _msg_code
		   		  order by 	msgtranslate_gid;				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_messagetranslate(_msgtranslate_gid udd_int, _lang_code udd_code, INOUT _result_messagetranslate refcursor DEFAULT 'rs_messagetranslate'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Mohan s
		Created Date : 05-04-2022
		SP Code : B01MGTG01
	*/
	-- Message Translate Details--
	open _result_messagetranslate for select 
							msgtranslate_gid,
							msg_code,
							lang_code,	
							msg_desc					
				  from 		core_mst_tmessagetranslate 				 
				  where 	msgtranslate_gid 	= _msgtranslate_gid
		   		  order by 	msgtranslate_gid;				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_pgfund(_pgfund_gid udd_int, _lang_code udd_code, INOUT _result_pgfund refcursor DEFAULT 'rs_pgfund'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 23-01-2022
		SP Code      : B05FUNCUD
	*/
	
	-- PG Fund 
	open _result_pgfund for select
						pgfund_gid,
						pg_id,
						fn_get_pgname(pg_id) as pg_name,
						pgfund_code,
						fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code)
																	as pgfund_code_desc,
						pgfund_date,
						pgfund_source_code,
						fn_get_masterdesc('QCD_PGFUND_SOURCE',pgfund_source_code,_lang_code)
																	as pgfund_source_code_desc,
						pgfund_amount,
						pgfund_available_amount,
						pgfund_remark,
						status_code,
						fn_get_masterdesc('QCD_STATUS',status_code,_lang_code)
																	as status_code_desc,
						created_date,
						created_by,
						updated_date,
						updated_by
				 from   pg_trn_tpgfund
				 where  pgfund_gid  = _pgfund_gid;
	
	
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_pgfundexpenses(_pgfundexp_gid udd_int, _lang_code udd_code, INOUT _result_pgfundexpenses refcursor DEFAULT 'rs_pgfundpgfundexpenses'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 02-03-2022
		
		Updated By   : Mohan
		Updated Date : 05-03-2022
		
		SP Code      : B05FUECUD
	*/
	
	-- PG Fund Expenses
	open _result_pgfundexpenses for select
										fde.pgfundexp_gid,
										fde.pg_id,
										fn_get_pgname(fde.pg_id) as pg_name,
										fde.pgfund_code,
										fn_get_masterdesc('QCD_PGFUND',fde.pgfund_code,_lang_code) as pgfund_code_desc,
										fde.expense_head_code,
										fn_get_masterdesc('QCD_PGFUND_EXPHEAD',fde.expense_head_code,_lang_code) as expense_head_code_desc,
										fde.expense_date,
										fde.expense_amount,
										fde.recovery_flag,
										fn_get_masterdesc('QCD_YES_NO',fde.recovery_flag,_lang_code) as recovery_flag_desc,
										fde.recovered_flag,
										fn_get_masterdesc('QCD_YES_NO',fde.recovered_flag,_lang_code) as recovered_flag_desc,
										fde.beneficiary_name,
										sum(fd.pgfund_available_amount + fde.expense_amount) as pgfund_available_amount,
										fde.expense_remark,
										fde.status_code,
										fn_get_masterdesc('QCD_STATUS',fde.status_code,_lang_code) as status_code_desc
								 from   pg_trn_tpgfundexpenses as fde
								 inner join pg_trn_tpgfund as fd on fde.pg_id = fd.pg_id
								 and 	fde.pgfund_code = fd.pgfund_code
								 and 	fd.status_code = 'A'
								 where  fde.pgfundexp_gid  = _pgfundexp_gid
								 and 	fde.status_code = 'A'
								 group by fde.pgfundexp_gid,
										  fde.pg_id,
										  fde.pgfund_code,
										  fde.expense_head_code,
										  fde.expense_date,
										  fde.expense_amount,
										  recovery_flag,
										  fde.beneficiary_name,
										  fde.expense_remark,
										  fde.status_code;
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_pgfundledger(_pgfundledger_gid udd_int, _lang_code udd_code, INOUT _result_fundledgdtl refcursor DEFAULT 'rs_fundledgdtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 08-03-2022
		SP Code : B05FDLG02
	*/
begin
	-- stored procedure body
	open _result_fundledgdtl for select 
									pgfundledger_gid,
									pg_id,
									pgfund_code,
									fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code) as pgfund_desc,
									pgfund_trantype_code,
									fn_get_masterdesc('QCD_PGFUND_TRANTYPE',pgfund_trantype_code,_lang_code) as pgfund_trantype_desc,
									pgfund_ledger_code,
									fn_get_masterdesc('QCD_ACC_HEAD',pgfund_ledger_code,_lang_code) as pgfund_ledger_desc,
									tran_date,
									cr_amount,
									dr_amount,
									recovery_flag,
									recovered_flag,
									beneficiary_name,
									pgfund_remark,
									status_code,
									fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc
					  from 			pg_trn_tpgfundledger
					  where 		pgfundledger_gid = _pgfundledger_gid
					  and 			status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_procurecost(_pg_id udd_code, _tran_datetime udd_datetime, _lang_code udd_code, INOUT _result_proccostdtl refcursor DEFAULT 'rs_proccostdtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B01PPCG02
	*/
begin
	-- stored procedure body
	-- PROCURE COST
	open _result_proccostdtl for select
									pc.proccost_gid,
									pc.pg_id,
									pc.proc_date,
									to_char(pc.tran_datetime,'YYYY-MM-DD HH24:MI:SS') as tran_datetime,
									pc.package_cost,
									pc.loading_unloading_cost,
									pc.transport_cost,
									pc.other_cost,
									pc.proccost_remark,
									pc.sync_status_code,
									fn_get_masterdesc('QCD_STATUS',pc.status_code,_lang_code) as status_desc,
									pc.status_code,
									pc.payment_calc_flag,
									fn_get_masterdesc('QCD_YES_NO',pc.payment_calc_flag,_lang_code) as payment_calc_flag_desc,
									pc.paymentcalc_date,
									pg.pg_name,
									pg.pg_id
					from 		    pg_trn_tprocurecost as pc
					inner join 		pg_mst_tproducergroup as pg 
					on 				pc.pg_id = pg.pg_id
					and 			pg.status_code <> 'I'
					where 			pc.pg_id = _pg_id
					and				to_char(pc.tran_datetime,'YYYY-MM-DD HH24:MI:SS') = _tran_datetime::udd_text
					and 			pc.status_code = 'A';
					
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_procureproduct(_pg_id udd_code, _session_id udd_code, _lang_code udd_code, INOUT _result_procprod refcursor DEFAULT 'rs_procprod'::refcursor, INOUT _result_procproddtl refcursor DEFAULT 'rs_procproddtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B01PPRG02
	*/
begin
	-- stored procedure body
	-- PROCURE PRODUCT
	open _result_procprod for select
								pg.pg_ll_name,
								s.session_date,
								s.session_id,
								count(distinct p.pgmember_id) as tot_members,
								sum(case when pp.prod_type_code = 'P' then pp.proc_qty else 0 end) as tot_peri_qty,
								sum(case when pp.prod_type_code = 'N' then pp.proc_qty else 0 end) as tot_nonperi_qty,
								pg.pg_name
					from 		pg_trn_tsession as s
					inner join 	pg_trn_tprocure as p on s.pg_id = p.pg_id 
					and 		s.session_id = p.session_id and p.status_code = 'A'
					inner join 	pg_trn_tprocureproduct as pp on	p.pg_id = pp.pg_id 
					and 		p.session_id = pp.session_id
					and 		p.pgmember_id = pp.pgmember_id 
					and 		p.proc_date = pp.proc_date
					inner join  pg_mst_tproducergroup as pg on s.pg_id = pg.pg_id 
					and 		pg.status_code <> 'I'
					where 	    p.pg_id = _pg_id
					and 		p.session_id = _session_id
					and 		s.status_code = 'A'
					group by 	s.session_date,s.session_id,pg.pg_ll_name,pg.pg_name;
					
	-- PROCURE PRODUCT DETAIL
	open _result_procproddtl for select 	
								   pp.procprod_gid,
								   pp.pg_id,
								   pp.session_id,
								   pp.pgmember_id,
								   pp.rec_slno,
								   pp.proc_date,
								   pp.prod_type_code,
								   pp.grade_code,
								   pp.proc_rate,
								   pp.uom_code,
								   mem.pgmember_name,
								   mem.fatherhusband_name,
								   mem.mobile_no_active,
								   fn_get_pgmembervillage(pp.pg_id,pp.pgmember_id,_lang_code) as village,
								   pp.prod_code,
								   fn_get_productdesc(pp.prod_code, _lang_code) as prod_desc,
								   mem.pgmember_clas_code,
							       fn_get_masterdesc('QCD_PGMEMBER_CLAS',mem.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
								   pp.prod_code,
								   fn_get_masterdesc('QCD_PROD_TYPE',pp.prod_type_code,_lang_code) as prod_type_desc,
								   fn_get_masterdesc('QCD_GRADE',pp.grade_code,_lang_code) as grade_desc,
								   fn_get_masterdesc('QCD_UOM',pp.uom_code,_lang_code) as uom_desc,
								   pp.proc_qty,
								   case when pp.rec_slno = 1 then proc.advance_amount else 0 end as advance_amount,
								   pp.proc_remark as remarks
						from	   pg_trn_tprocure as proc
						inner join pg_trn_tprocureproduct as pp on proc.session_id = pp.session_id 
						and 	   proc.pg_id = pp.pg_id and proc.pgmember_id = pp.pgmember_id
						and 	   proc.proc_date = pp.proc_date
						inner join pg_mst_tpgmember as mem on  mem.pgmember_id = proc.pgmember_id 
						and 	   mem.pg_id = proc.pg_id			
						where 	   proc.pg_id = _pg_id
						and 	   proc.session_id = _session_id
						and 	   mem.status_code <> 'I'
						and 	   proc.status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_reportdtl(_report_code udd_code, _param_code udd_code, _lang_code udd_code, INOUT _result_reportdtl refcursor DEFAULT 'rs_reportdtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 16-05-2022
		SP Code      : B01REPFET
	*/
	
	open _result_reportdtl for select 
											report_code,
											param_code,
											param_type_code,
											fn_get_masterdesc('QCD_PARAM_TYPE', param_type_code, _lang_code) as param_type_desc,
											param_name,
											param_desc,
											param_datatype_code,
											fn_get_masterdesc('QCD_PARAM_DATATYPE', param_datatype_code, _lang_code) as param_datatype_desc,
											param_order
								from 		core_mst_treportparam 
								where       report_code = _report_code
								and         param_code  = _param_code;
	
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_role(_role_code udd_code, _lang_code udd_code, INOUT _result_rlfetch refcursor DEFAULT 'rs_rlfetch'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 16-12-2021
		SP Code : B01ROLF01
	*/
begin
	-- stored procedure body
	if _role_code = 'pla' then
		open _result_rlfetch for select 	
									 rol.role_code as role_code,
									 rol.role_name as role_name,
									 rol.status_code as status_code,
									 fn_get_masterdesc('QCD_STATUS',rol.status_code,_lang_code) as status_desc,
									 rolmenu.menu_code as menu_code,
									 mentran.menu_desc as menu_desc,
									 menu.parent_code as parent_code,
									 menu.url_action_method as url_action_method,
									 menu.menu_type_code as menu_type_code,
									 rolmenu.add_flag as add_flag,
									 rolmenu.modifiy_flag as modifiy_flag,
									 rolmenu.view_flag as view_flag,
									 rolmenu.auth_flag as auth_flag,
									 rolmenu.print_flag as print_flag,
									 rolmenu.inactive_flag as inactive_flag,
									 rolmenu.deny_flag as deny_flag
					  from 		 core_mst_trole as rol
					  inner join core_mst_trolemenurights as rolmenu 
					  on 		 rolmenu.role_code = rol.role_code
					  inner join core_mst_tmenutranslate as mentran 
					  on 		 mentran.menu_code = rolmenu.menu_code
					  inner join core_mst_tmenu as menu 
					  on 		 menu.menu_code = mentran.menu_code
					  and 	 	 menu.status_code = 'A'
					  and		 menu.menu_type_code = 'T'
					  where		 rol.status_code = 'A' 
					  and 		 rolmenu.role_code = _role_code 
					  and   	 mentran.lang_code = _lang_code
					  and 		 menu.parent_code <> 'SYS'
					  and 		 menu.parent_code <> 'MAIN'
					  and 		 mentran.menu_desc <> 'Change password'
					  order by 	 menu.menu_slno asc;
	else			  
				  open _result_rlfetch for select * from (select 
														  menu.menu_slno,
								 rol.role_code as role_code,
								 rol.role_name as role_name,
								 rol.status_code as status_code,
								 fn_get_masterdesc('QCD_STATUS',rol.status_code,_lang_code) as status_desc,
				  				 rolmenu.menu_code as menu_code,
								 mentran.menu_desc as menu_desc,
								 menu.parent_code as parent_code,
								 menu.url_action_method as url_action_method,
								 menu.menu_type_code as menu_type_code,
								 rolmenu.add_flag as add_flag,
								 rolmenu.modifiy_flag as modifiy_flag,
								 rolmenu.view_flag as view_flag,
								 rolmenu.auth_flag as auth_flag,
								 rolmenu.print_flag as print_flag,
								 rolmenu.inactive_flag as inactive_flag,
								 rolmenu.deny_flag as deny_flag
				  from 		 core_mst_trole as rol
				  inner join core_mst_trolemenurights as rolmenu 
				  on 		 rolmenu.role_code = rol.role_code
				  inner join core_mst_tmenutranslate as mentran 
				  on 		 mentran.menu_code = rolmenu.menu_code
				  inner join core_mst_tmenu as menu 
				  on 		 menu.menu_code = mentran.menu_code
				  and 	 	 menu.status_code = 'A'
				  and		 menu.menu_type_code = 'L'
				  where		 rol.status_code = 'A' 
				  and 		 rolmenu.role_code = _role_code 
				  and   	 mentran.lang_code = _lang_code
				  and 		 menu.parent_code <> 'SYS'
				  and 		 menu.parent_code <> 'MAIN'
				union all
				  select 	menu.menu_slno,
								 rol.role_code as role_code,
								 rol.role_name as role_name,
								 rol.status_code as status_code,
								 fn_get_masterdesc('QCD_STATUS',rol.status_code,_lang_code) as status_desc,
				  				 rolmenu.menu_code as menu_code,
								 mentran.menu_desc as menu_desc,
								 menu.parent_code as parent_code,
								 menu.url_action_method as url_action_method,
								 menu.menu_type_code as menu_type_code,
								 rolmenu.add_flag as add_flag,
								 rolmenu.modifiy_flag as modifiy_flag,
								 rolmenu.view_flag as view_flag,
								 rolmenu.auth_flag as auth_flag,
								 rolmenu.print_flag as print_flag,
								 rolmenu.inactive_flag as inactive_flag,
								 rolmenu.deny_flag as deny_flag
				  from 		 core_mst_trole as rol
				  inner join core_mst_trolemenurights as rolmenu 
				  on 		 rolmenu.role_code = rol.role_code
				  inner join core_mst_tmenutranslate as mentran 
				  on 		 mentran.menu_code = rolmenu.menu_code
				  inner join core_mst_tmenu as menu 
				  on 		 menu.menu_code = mentran.menu_code
				  and 	 	 menu.status_code = 'A'
				  and		 menu.menu_type_code = 'T'
				  where		 rol.status_code = 'A' 
				  and 		 rolmenu.role_code = _role_code 
				  and   	 mentran.lang_code = _lang_code
				  and 		 menu.parent_code <> 'SYS'
				  and 		 menu.parent_code <> 'MAIN'
				  and 		 mentran.menu_code in ('MASCHP007','MASPRM004')) as a
				  order by a.menu_slno;
	end if;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_sale(_pg_id udd_code, _sale_date udd_date, _lang_code udd_code, INOUT _result_salelist refcursor DEFAULT 'rs_salelist'::refcursor, INOUT _result_saledtl refcursor DEFAULT 'rs_saledtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B01SALG02
	*/
begin
	-- stored procedure body
	-- SALE
	open _result_salelist for select 
									pg.pg_ll_name,
									s.pg_id,
									s.inv_date,
									count(distinct s.sale_gid) as tot_member,
									sum(case when sp.prod_type_code = 'P' 
													then sp.sale_qty else 0 end) 		as tot_peri_qty,
									count(distinct (case when sp.prod_type_code = 'P' 
													then sp.prod_code else null end)) 	as tot_peri_count,
									sum(case when sp.prod_type_code = 'N' 
													then sp.sale_qty else 0 end) 		as tot_nonperi_qty,
									count(distinct (case when sp.prod_type_code = 'N' 
													then sp.prod_code else null end)) 	as tot_nonperi_count,
									sum(sp.sale_base_amount+sp.cgst_amount+sp.sgst_amount) as sale_amount ,
									pg.pg_name
						from 		pg_trn_tsale as s 
						inner join  pg_trn_tsaleproduct as sp on s.pg_id = sp.pg_id
						and 		s.inv_date = sp.inv_date
						and 		s.inv_no = sp.inv_no
						inner join  core_mst_tproduct as p on sp.prod_code = p.prod_code
						inner join  pg_mst_tproducergroup as pg on s.pg_id = pg.pg_id 
						and 		pg.status_code <> 'I'
						where 		s.pg_id = _pg_id
						and			s.inv_date = _sale_date
						and 		s.status_code = 'A'
						group by s.pg_id,s.inv_date,pg.pg_name,pg.pg_ll_name;
						
	-- SALE DETAIL
	open _result_saledtl for select 
								s.sale_gid,
								sp.saleprod_gid,
								sp.pg_id,
								sp.inv_date,
								sp.rec_slno,
								s.buyer_name,
								s.buyer_mobile_no,
								sp.inv_no,
								sp.prod_code,
								fn_get_productdesc(sp.prod_code,_lang_code) as prod_desc,
								sp.prod_type_code,
								fn_get_masterdesc('QCD_PROD_TYPE',sp.prod_type_code,_lang_code) as prod_type_desc,
								sp.grade_code,
								fn_get_masterdesc('QCD_GRADE',sp.grade_code,_lang_code) as grade_desc,
								p.uom_code,
								fn_get_masterdesc('QCD_UOM',p.uom_code,_lang_code) as uom_desc,
								sp.sale_qty,
								sp.inv_qty,
								sp.sale_rate,
								sp.sale_base_amount,
								sp.sale_amount,
								(sp.cgst_amount+sp.sgst_amount) as gst_amount,
								sp.sale_remark as sale_remark 
					from 		pg_trn_tsale as s 
					inner join  pg_trn_tsaleproduct as sp on  s.pg_id = sp.pg_id
					and 		s.inv_date = sp.inv_date
					and 		s.inv_no = sp.inv_no
					inner join  core_mst_tproduct as p on sp.prod_code = p.prod_code
					where 		s.pg_id = _pg_id
					and			s.inv_date = _sale_date
					and 		s.status_code = 'A';

end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_salecollection(_pg_id udd_code, _buyer_name udd_desc, _inv_no udd_code, _sale_date udd_date, _lang_code udd_code, INOUT _result_salelst refcursor DEFAULT 'rs_salelst'::refcursor, INOUT _result_collectiondtl refcursor DEFAULT 'rs_collectiondtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 17-08-2022
		SP Code : B04COLG01
	*/
begin
	-- stored procedure body
	-- SALE
	open _result_salelst for select distinct
									pg.pg_name,
									s.pg_id,
									s.inv_date,
									s.buyer_name,
									s.inv_amount,
									s.inv_no,
									s.collected_amount as received_amount,
									(s.inv_amount - s.collected_amount) as balance_amount,
									pg.pg_name
						from 		pg_trn_tsale as s 
						inner join  pg_trn_tsaleproduct as sp on s.pg_id = sp.pg_id
						and 		s.inv_date = sp.inv_date
						and 		s.inv_no = sp.inv_no
						inner join  core_mst_tproduct as p on sp.prod_code = p.prod_code
						inner join  pg_mst_tproducergroup as pg on s.pg_id = pg.pg_id 
						and 		pg.status_code <> 'I'
						where 		s.pg_id 	  = _pg_id
						and 		s.buyer_name  = _buyer_name
						and 		s.inv_no 	  = _inv_no
						and			s.inv_date    = _sale_date
						and 		s.status_code = 'A';
						
	-- SALE DETAIL
	open _result_collectiondtl for select distinct
											sp.pg_id,
											c.pay_mode_code,
											fn_get_masterdesc('QCD_PAY_MODE',c.pay_mode_code,_lang_code) as pay_mode_desc,
											c.coll_date,
											c.coll_amount,
											c.pay_ref_no
								from 		pg_trn_tsale as s 
								inner join  pg_trn_tsaleproduct as sp on  s.pg_id = sp.pg_id
								and 		s.inv_date = sp.inv_date
								and 		s.inv_no = sp.inv_no
								inner join  core_mst_tproduct as p on sp.prod_code = p.prod_code
								inner join  pg_trn_tcollection as c on s.inv_no = c.inv_no
								and 	    s.pg_id = c.pg_id
								where 		c.pg_id = _pg_id
								and			c.inv_no = _inv_no
								and 		s.status_code = 'A';

end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_screendtl(_screen_code udd_code, _lang_code udd_code, INOUT _result_screen refcursor DEFAULT 'rs_screen'::refcursor, INOUT _result_screendata refcursor DEFAULT 'rs_screendata'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01SCRG02
	*/
	-- Screen Details
	open _result_screen for select 	
							screen_gid,
							screen_code,
							screen_name,														
							status_code,
							fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
							created_date,
							created_by,
							updated_date,
							updated_by							
				  from 		core_mst_tscreen 				 
				  where 	screen_code 		= _screen_code
		   		  order by 	status_code,screen_gid;	

		  -- Screen Data Details--
	open _result_screendata for select 
							screendata_gid,
							screen_code,
							lang_code,	
							ctrl_type_code,	
							fn_get_masterdesc('QCD_CTRL_TYPE',ctrl_type_code,_lang_code) as ctrl_type_desc,
							ctrl_id,	
							data_field,	
							label_desc,	
							tooltip_desc,
							default_label_desc,	
							default_tooltip_desc,	
							ctrl_slno,												
							created_date,
							created_by,
							updated_date,
							updated_by							
				  from 		core_mst_tscreendata 				 
				  where 	screen_code 		= _screen_code
		   		  order by 	screendata_gid;		
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_smstran(_pg_id udd_code, _lang_code udd_code, INOUT _result_smstran refcursor DEFAULT 'rs_smstran'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 25-01-2022
		SP Code      : B04SMSCXD
	*/
	
	open _result_smstran for select 
							smstran_gid,
							pg_id,
							smstemplate_code,
							mobile_no,
							sms_text,
							scheduled_date,
							sms_delivered_flag,
							fn_get_masterdesc('QCD_YES_NO',sms_delivered_flag,_lang_code)
																	as sms_delivered_flag_desc,
							user_code,
							role_code,
							status_code,
							fn_get_masterdesc('QCD_STATUS',status_code,_lang_code)
																	as status_code_desc,
							created_date,
							created_by,
							updated_date,
							updated_by
					from    pg_trn_tsmstran
					where   pg_id              = _pg_id
					and     sms_delivered_flag = 'N';
	
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_sqliteattachment(_sqliteattachment_gid udd_int, _lang_code udd_code, INOUT _result_sqlliteatmfetch refcursor DEFAULT 'rs_sqlliteatmfetch'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 22-03-2022
		SP Code : B04SAMF01
	*/
begin
	-- stored procedure body
	open _result_sqlliteatmfetch for select 	
								 		sqliteattachment_gid,
										pg_id,
										role_code,
										user_code,
										mobile_no
				  from 		 pg_trn_tsqliteattachment
				  where 	 sqliteattachment_gid = _sqliteattachment_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_fetch_tenantidentifier(_tenant_identifier udd_code, INOUT _result_tenantidfetch refcursor DEFAULT 'rs_tenantidfetch'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 18-06-2021
		SP Code : (Tenant Identifier)
	*/
begin
	-- stored procedure body
	open _result_tenantidfetch for select 	
										tenant_gid,
										tenant_identifier,
										geo_location_flag,
										bank_branch_flag,
										shg_profile_flag,
										tenant_user,
										tenant_password,
										status_code,
										state_id
				  from 		core_mst_ttenantidentifier
				  where		tenant_identifier = _tenant_identifier
				  and		status_code 	  = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_allattachment(_attachment_gid udd_code, _pg_id udd_code, _pgmember_id udd_code, _attachment_type udd_code, _lang_code udd_code, INOUT _result_attachment refcursor DEFAULT 'rs_attachmentlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
/*
	Created By : Mohan S
	Created Date : 05-04-2022
	SP Code : B04ATMG01
*/
	 config_path udd_text := '';

begin
	select  fn_get_configvalue('server_atm_path')
	into 	config_path;

	-- stored procedure body
	-- 	PG ATTACHMENT --
	if _attachment_type = 'PG' then
		open _result_attachment for select
									  pgattachment_gid,
									  pg_id,
									  doc_type_code,
									  fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
									  doc_subtype_code,
									  fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
									  config_path || file_path as file_path,
									  file_name,
									  attachment_remark,
									  original_verified_flag,
									  fn_get_masterdesc('QCD_YES_NO',original_verified_flag,_lang_code) as original_verified_desc,
									  created_by
							from 	  pg_mst_tattachment
							where 	  pgattachment_gid = _attachment_gid::udd_int;
	end if;
	-- 	PGMEMBER ATTACHMENT --						
    if _attachment_type = 'PGMEM' then
			open _result_attachment for select 
										 pgmemberattachment_gid,
										 pgmember_id,
										 doc_type_code,
										 fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
										 doc_subtype_code,
										 fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
										 file_name,
										 config_path || file_path as file_path,
										 attachment_remark
							from	pg_mst_tpgmemberattachment
							where pgmemberattachment_gid = _attachment_gid::udd_int
							and   pgmember_id 			 = _pgmember_id;
	end if;
	-- 	BUSSPLAN ATTACHMENT --	
    if _attachment_type = 'BPLAN' then
			open _result_attachment for  select 
										   bussplanattachment_gid,
										   doc_type_code,
										   fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
										   doc_subtype_code,
										   fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
										   config_path || file_path as file_path,
										   file_name,
										   attachment_remark,
										   created_by
						  from 			   pg_trn_tbussplanattachment
						  where 		   bussplanattachment_gid = _attachment_gid::udd_int;
	end if;
	-- 	FUNDREQU ATTACHMENT --		
    if _attachment_type = 'FUND' then
			open _result_attachment for  select 
										   fundreqattachment_gid,
										   pg_id,
										   bussplan_id,
										   doc_type_code,
										   fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
										   doc_subtype_code,
										   fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
										   config_path || file_path as file_path,
										   file_name,
										   attachment_remark
						  from 			   pg_trn_tfundreqattachment
						  where 		   fundreqattachment_gid = _attachment_gid::udd_int;
	end if;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_allpgnamelist(_lang_code udd_code, INOUT _result_allpgname refcursor DEFAULT 'rs_allpgnamelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan
		Created Date : 16-03-2022
		SP Code : B04PGLG03
	*/
begin
	-- stored procedure body
	-- PG NAME LIST
	open _result_allpgname for select 	
							pg_id,
							pg_name,
							concat(pg_id,'-',pg_name) as pg_id_name
				  from 		pg_mst_tproducergroup 
				  where 	status_code <> 'I'
		   		  order by 	pg_name;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_bankbranchlist(_pg_id udd_code, INOUT _result_bankbranch refcursor DEFAULT 'rs_bankbranch'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 13-01-2022
		SP Code : B01BNKG02
	*/
begin
	-- stored procedure body select * from pg_bank_branch_view
	open _result_bankbranch for select 	
							 pg_id,
							 state_id,
							 district_id,
							 bank_code,
							 bank_name,
							 bank_branch_id,
							 bank_branch_code,
							 bank_branch_name,
							 ifsc_code
				  from 		 pg_bank_branch_view
				  where 	 pg_id = _pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_banklist(_pg_id udd_code, INOUT _result_bank refcursor DEFAULT 'rs_bank'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 13-01-2022
		SP Code : B01BNKG01
	*/
begin
	-- stored procedure body
	open _result_bank for select Distinct	
							 bank_code,
							 bank_name
				  from 		 pg_bank_branch_view
				  where 	 pg_id = _pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_blkstatedistlist(_block_code udd_code, INOUT _result_sdblist refcursor DEFAULT 'rs_sdblist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan
		Created Date : 21-02-2022
		SP Code : B01BLKG01
	*/
begin
	-- stored procedure body
	-- BLOCK LIST
	open _result_sdblist for select 	
								block_id,
								block_name_en as block_desc,
								state_id,
								district_id
				  from 		block_master 
				  where 	block_code = _block_code
				  and 		is_active = true;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_blockid_pgid(_block_id udd_int, INOUT _result_blockpgid refcursor DEFAULT 'rs_blockpgid'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 09-02-2022
		SP Code : B04BLKG01
	*/
begin
	-- stored procedure body
	open _result_blockpgid for select 	
									  pg_id
				  from          pg_mst_tpanchayatmapping
				  where 		block_id = _block_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_blocklist(_role_code udd_code, _state_code udd_code, _district_id udd_int, INOUT _result_block refcursor DEFAULT 'rs_block'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 26-09-2022
		
		Updated By : Mangai
		Updated Date : 20-01-2023
		
		SP Code : B01BLMG02
	*/
begin
	
	-- State Level user --
	if _role_code = 'state' and _state_code <> '' then
		open _result_block for select 	
									a.block_id,
									a.state_id,
									a.district_id,
									a.block_code,
									a.block_name_en,
									a.block_name_local
					  from 			block_master as a
					  inner join 	state_master as b 
					  on 			a.state_id = b.state_id
					  and 			a.is_active = true
					  where 		b.state_code = _state_code
					  and 			a.is_active = true
-- 					  order by 		a.is_active,a.block_id;
					  order by      a.block_name_en;
	
	-- National Level user -- 
	else if _role_code = 'national' then
		open _result_block for select 	
									block_id,
									state_id,
									district_id,
									block_code,
									block_name_en  || '-' ||
									fn_get_districtdesc(district_id) || '-' ||
									fn_get_statedesc(state_id) as block_name_en,
									block_name_local
					  from 			block_master
					  where 		is_active = true
					  order by      block_name_en;
	
	-- Except sate and national level users --
	else if _role_code <> 'state' and _role_code <> 'national' then
	 	open _result_block for select 	
									block_id,
									state_id,
									district_id,
									block_code,
									block_name_en,
									block_name_local
					  from 			block_master
					  where 		district_id = _district_id
					  and 			is_active = true
-- 					  order by 		is_active,block_id;
					  order by      block_name_en;
	end if;
	end if;
	end if;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_blocklist(_district_id udd_int, INOUT _result_block refcursor DEFAULT 'rs_block'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 03-01-2022
		
		updated By : Mangai
		updated Date : 20-01-2023
		
		SP Code : B01BLMG01
	*/
begin
	-- stored procedure body
	open _result_block for select 	
								block_id,
								state_id,
								district_id,
								block_code,
								block_name_en,
								block_name_local
				  from 			block_master
				  where 		district_id = _district_id
				  and 			is_active = true
-- 				  order by 		is_active,block_id;
				  order by      block_name_en;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_bussplan(_bussplan_id udd_code, _lang_code udd_code, INOUT _result_bussplan refcursor DEFAULT 'rs_bussplan'::refcursor, INOUT _result_comm refcursor DEFAULT 'rs_comm'::refcursor, INOUT _result_attachment refcursor DEFAULT 'rs_attach'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
/*
	Created By : Mohan S
	Created Date : 16-12-2021
	SP Code : B04BPSG01
*/
begin
	-- stored procedure body
	-- BUSINESS PLAN
	open _result_bussplan for select 	
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 bp.bussplan_gid as bussplan_gid,
								 bp.bussplan_id as bussplan_id,
								 bp.blockofficer_id as blockofficer_id,
								 bp.reviewer_type_code as reviewer_type_code,
								 fn_get_masterdesc('QCD_REVIEWER_TYPE',bp.reviewer_type_code,_lang_code) as reviewer_type_desc,
								 bp.clf_block_id as clf_block_id,
								 bp.reviewer_code as reviewer_code,
								 bp.bussplan_review_flag as bussplan_review_flag,
								 fn_get_masterdesc('QCD_YES_NO',bp.bussplan_review_flag,_lang_code) as review_flag_desc,
								 0 as ops_exp_amount,
								 0 as net_pl_amount,
								 bp.bussplan_remark as bussplan_remark,
								 bp.status_code as status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as status_desc,
								 'Rajesh chauhan' as ""udyog mitra"",
								 'Beebra' as ""Village"",
								 'Bilaspur' as ""Gram Panchayat"",
								 'Rampur' as ""Block"",
								 bp.period_from as period_from,
								 bp.period_to as period_to,
								 'Y' as ""CLF Available"",
								 'Bilaspur' as ""clf/bo"",
								 'CLFO - 002' as ""clf/bo Reviwer id"",
								 'Ramesh Govind P' as ""clf/bo reviwer name"",
								 3 as SC,
								 4 as ST,
								 2 as OBC,
								 8 as ""Others"",
								 17 as Total
				  from 			 pg_mst_tproducergroup as pg
				  inner join 	 pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  where 		 bp.bussplan_id = _bussplan_id;
				  
	-- COMMODITY
	open _result_comm for select 
							 prod_code,
							 prod_type_code,
							 fn_get_masterdesc('QCD_PROD_TYPE',prod_type_code,_lang_code) as pg_type_desc,
							 jan_sowing_flag,
							 jan_harvesting_qty,
							 feb_sowing_flag,
							 feb_harvesting_qty,
						     mar_sowing_flag,
							 mar_harvesting_qty,
							 apr_sowing_flag,
							 apr_harvesting_qty,
							 may_sowing_flag,
							 may_harvesting_qty,
							 jun_sowing_flag,
							 jun_harvesting_qty,
							 jul_sowing_flag,
							 jul_harvesting_qty,
							 aug_sowing_flag,
						     aug_harvesting_qty,
						     sep_sowing_flag,
							 sep_harvesting_qty,
							 oct_sowing_flag,
							 oct_harvesting_qty,
							 nov_sowing_flag,
							 nov_harvesting_qty,
							 dec_sowing_flag,
							 dec_harvesting_qty,
							 revenue_amount,
							 procure_amount
				  from 		 pg_trn_tbussplanproduct
				  where 	 bussplan_id = _bussplan_id;
				  
				  
	-- ATTACHMENT
	open _result_attachment for select 
								   bussplanattachment_gid,
								   doc_type_code,
								   fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
								   doc_subtype_code,
								   fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
								   file_path,
								   file_name,
								   attachment_remark
				  from 			   pg_trn_tbussplanattachment
				  where 		   bussplan_id = _bussplan_id;
									
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_bussplanapprovallist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_bpalist refcursor DEFAULT 'rs_bpalist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
Declare
	/*
		Created By : Mohan S
		Created Date : 01-04-2022
		SP Code : B04BPAG01
	*/
	v_reviewer_type_code udd_code = '';
	v_block_id udd_int = 0;
begin
	select fn_get_blockid(_block_code)::udd_int into v_block_id;
	
	/*if _role_code = 'clfofficer' or _role_code = 'clfmanager' then
		v_reviewer_type_code = 'QCD_CLF';
	elseif _role_code = 'bo' then
		v_reviewer_type_code = 'QCD_BO';
	else 
		v_reviewer_type_code = null;
		_user_code = null;
	end if;*/
	
	-- stored procedure body
	open _result_bpalist for select 	
								 bp.bussplan_id,
								 pg.pg_name,
								 pg.pg_id,
								 pg.village_id,
								 fn_get_villagedesc(pgadd.village_id) as village_desc,
								 pgadd.block_id,
								 fn_get_blockdesc(pgadd.block_id) as block_desc,
								 bp.period_from,
								 bp.period_to,
								 bp.bussplan_remark,
								 bp.status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as status_desc
				  from 		  pg_mst_tproducergroup  as pg
				  inner join  pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
 				  and 		  bp.status_code <> 'D'
				  inner join  pg_mst_taddress  as pgadd on pg.pg_id = pgadd.pg_id 
				  and 		  pgadd.addr_type_code 	= 'QCD_ADDRTYPE_REG'
				  where 	  pg.pg_id in  (select fn_get_pgid(v_block_id))
-- 				  and 		  reviewer_type_code 	= coalesce(v_reviewer_type_code,reviewer_type_code)
				  and		  reviewer_code 	 	= _user_code
				  order by    bp.bussplan_gid desc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_bussplandownloadlog(_pg_id udd_code, _bussplan_id udd_code, INOUT _downloaded_count udd_int)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 18-12-2021
		SP Code : B04BPDG01
	*/
begin
	-- stored procedure body
	-- Downloaded Count
	select 
		count(*) into _downloaded_count
		from 	 pg_trn_tbussplandownloadlog
		where 	 pg_id = _pg_id
		and 	 bussplan_id = _bussplan_id;
									
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_bussplanlist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_bpslist refcursor DEFAULT 'rs_bpslist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
Declare
	/*
		Created By : Mohan S
		Created Date : 30-03-2022
		SP Code : B04BPSG01
	*/
	v_reviewer_type_code udd_code = '';
	v_block_id udd_int = 0;
begin
	select fn_get_blockid(_block_code)::udd_int into v_block_id;
	
	/*if _role_code = 'clfofficer' or _role_code = 'clfmanager' then
		v_reviewer_type_code = 'QCD_CLF';
	elseif _role_code = 'bo' then
		v_reviewer_type_code = 'QCD_BO';
	else 
		v_reviewer_type_code = null;
		_user_code = null;
	end if;*/
	
	-- stored procedure body
	open _result_bpslist for select 	
								 bp.bussplan_id,
								 pg.pg_name,
								 pg.pg_id,
								 pg.village_id,
								 fn_get_villagedesc(pgadd.village_id) as village_desc,
								 pgadd.block_id,
								 fn_get_blockdesc(pgadd.block_id) as block_desc,
								 bp.period_from,
								 bp.period_to,
								 bp.bussplan_remark,
								 bp.status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as status_desc
				  from 		  pg_mst_tproducergroup  as pg
				  inner join  pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				 -- and 		  bp.status_code <> 'S' and bp.status_code <> 'A'
				  inner join  pg_mst_taddress  as pgadd on pg.pg_id = pgadd.pg_id 
				  and 		  pgadd.addr_type_code 	= 'QCD_ADDRTYPE_REG'
				  where 	  pg.pg_id in  (select fn_get_pgid(v_block_id))
-- 				  and 		  reviewer_type_code 	= coalesce(v_reviewer_type_code,reviewer_type_code)
-- 				  and		  bp.reviewer_code 	 	= coalesce(_user_code,bp.reviewer_code)
				  and		  bp.created_by 	 	= _user_code
				  order by    bp.bussplan_gid desc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_bussplanprodlist(_pg_id udd_code, _lang_code udd_code, INOUT _result_bpl refcursor DEFAULT 'rs_bussplanlist'::refcursor, INOUT _result_commodity refcursor DEFAULT 'rs_commodity'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan
		Created Date : 28-01-2022
		SP Code : B04BPSG02
	*/
begin
	-- stored procedure body 
	-- BUSSPLAN LIST
	open _result_bpl for select 	
							pg.pg_id,
							pg.pg_name,
							pgud.udyogmitra_name as udyogmitra_name,
							fn_get_villagedesc(pgadd.village_id) as village_desc,
							fn_get_panchayatdesc(pgadd.panchayat_id) as panchayat_desc,
							fn_get_blockdesc(pgadd.block_id) as block_desc,
							fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc,
							clf.clf_id as clf_id,
							clf.clf_name as clf_name,
							clf.clf_officer_id as clf_officer_id,
							clf.clf_officer_name as clf_officer_name
				  from 		pg_mst_tproducergroup as pg
				  left join pg_mst_taddress as pgadd on pg.pg_id = pgadd.pg_id 
				  and		addr_type_code = 'QCD_ADDRTYPE_REG'  
				  left join pg_mst_tudyogmitra as pgud on pg.pg_id = pgud.pg_id
				  and 		pgud.tran_status_code = 'A'
				  left join pg_mst_tclf as clf on pg.pg_id = clf.pg_id
				  where 	pg.pg_id = _pg_id 
		   		  order by 	pg.status_code,pg.pg_gid;
				  
	-- COMMODITY			  
	open _result_commodity for select 	
						   'N' as checkbox, 
							pm.prod_code,
							pt.prod_desc,
							pro.prod_type_code,
							fn_get_masterdesc('QCD_PROD_TYPE',pro.prod_type_code,_lang_code) as pg_type_desc,
							pro.uom_code as uom_code,
							fn_get_masterdesc('QCD_UOM',pro.uom_code,_lang_code) as uom_desc							
				  from 		pg_mst_tproductmapping as pm
				  inner join core_mst_tproduct as pro on pm.prod_code = pro.prod_code
				  and 		 pro.status_code = 'A'
				  inner join core_mst_tproducttranslate as pt on pm.prod_code = pt.prod_code
				  and 		pt.lang_code = _lang_code
				  where 	pm.pg_id = _pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_bussplansubmissionlist(_lang_code udd_code, INOUT _result_bpslist refcursor DEFAULT 'rs_bpslist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
Declare
	/*
		Created By : Mohan S
		Created Date : 23-12-2021
		SP Code : B04BPSF01
	*/
begin
	-- stored procedure body
	open _result_bpslist for select 	
								 bp.bussplan_id,
								 pg.pg_name,
								 pg.pg_id,
								 pg.village_id,
								 fn_get_villagedesc(pgadd.village_id) as village_desc,
								 pgadd.block_id,
								 fn_get_blockdesc(pgadd.block_id) as block_desc,
				  				 bp.period_from,
								 bp.period_to,
								 bp.bussplan_remark,
								 bp.status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as status_desc
				  from 		  pg_mst_tproducergroup  as pg
				  inner join  pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				 -- and 		  bp.status_code <> 'S' and bp.status_code <> 'A'
				  inner join  pg_mst_taddress  as pgadd on pg.pg_id = pgadd.pg_id 
				  and 		  pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
				  order by    bp.bussplan_gid desc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_buyernamelist(_pg_id udd_code, INOUT _result_buyername refcursor DEFAULT 'rs_buyername'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 28-01-2022
		SP Code : B06BUYG01
	*/
begin
	-- stored procedure body
	open _result_buyername for select 	
								   pg_id,
								   buyer_name
							 from  pg_trn_tsale
							 where pg_id = _pg_id
							 and   status_code = 'A';
									
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_clfmemberprofilelist(_pg_id udd_code, INOUT _result_clfmemberproflist refcursor DEFAULT 'rs_clfmemprof'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 06-01-2022
		SP Code : B04CMPG01
	*/
begin
	-- stored procedure body
	open _result_clfmemberproflist for select 	
									pg_id,
									clf_id,
									clf_name,
									clf_name_local,
									clf_member_id,
									clf_member_name,
									clf_member_name_local,
									state_id,
									district_id,
									block_id
				  from 		clfmember_profile_view
				  where 	pg_id = _pg_id
				  order by  pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_clfprofilelist(_pg_id udd_code, INOUT _result_clfproflist refcursor DEFAULT 'rs_clfprof'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 06-01-2022
		SP Code : B04CLPG01
	*/
begin
	-- stored procedure body
	open _result_clfproflist for select 	
									pg_id,
									clf_id,
									clf_name,
									clf_name_local,
									state_id,
									district_id,
									block_id
				  from 		clf_profile_view
				  where 	pg_id = _pg_id
				  order by  pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_collectionlist(_pg_id udd_code, _inv_no udd_code, _lang_code udd_code, INOUT _result_collection refcursor DEFAULT 'rs_coll_list'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mangai
		Created Date : 11-08-2022
		SP Code : B06COLCUD
	*/
begin
	-- stored procedure body
	open _result_collection for  select 	 c.coll_gid,
											 s.pg_id,
											 s.collected_amount,
											 s.inv_amount,
											 s.buyer_name,
											 c.inv_no,
											 c.coll_no,
											 c.coll_date as received_date,
											 c.pay_mode_code,
											 fn_get_masterdesc('QCD_PAY_MODE',c.pay_mode_code,_lang_code) as pay_mode_desc,
											 c.pay_ref_no,
											 c.coll_amount as received_amount
								 from        pg_trn_tcollection as c
								 inner join  pg_trn_tsale as s
								 on          s.pg_id  = c.pg_id
								 and         s.inv_no = c.inv_no
								 where       s.pg_id  = _pg_id
								 and         s.inv_no = _inv_no
								 and         c.coll_amount <= s.inv_amount
								 and         s.status_code = 'A';
									
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_costreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _cost_type udd_code, _from_date udd_date, _to_date udd_date, _user_code udd_user, _role_code udd_code, _lang_code udd_code, INOUT _result_cost refcursor DEFAULT 'rs_cost'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 23-02-2022
		SP Code : B08COSR01
	*/
begin
	_cost_type = coalesce(_cost_type,'');
	
	-- stored procedure body
if _cost_type <> '' and _cost_type <> 'null' then 
	open _result_cost for select 	
							   proc_date,
							   case when _cost_type = 'QCD_PACKAGE_COST' then 'Packet Cost'
									when _cost_type = 'QCD_LOAD_UNLOAD_COST' then 'Loading Unloading Cost'
								    when _cost_type = 'QCD_TRANSPORT_COST' then 'Transport Cost'
								   	when _cost_type = 'QCD_OTHER_COST' then 'Other Cost'
									else _cost_type
							   end as cost_type,
							   case when _cost_type = 'QCD_PACKAGE_COST' then package_cost
									when _cost_type = 'QCD_LOAD_UNLOAD_COST' then loading_unloading_cost
								    when _cost_type = 'QCD_TRANSPORT_COST' then transport_cost
								   	when _cost_type = 'QCD_OTHER_COST' then other_cost
							   end as amount,
							   proccost_remark
					from	   pg_trn_tprocurecost
					where proc_date >= _from_date and proc_date <= _to_date
					and   pg_id = _pg_id and status_code = 'A';
	else
		open _result_cost for select 
							   proc_date,
							   'Packet Cost' as cost_type,
							   package_cost as amount,
							   proccost_remark
					from	   pg_trn_tprocurecost
					where proc_date >= _from_date and proc_date <= _to_date
					and   pg_id = _pg_id and status_code = 'A'
					
				 union all 
							select 
							   proc_date,
							   'Transport Cost' as cost_type,
							   transport_cost as amount,
							   proccost_remark
					from	   pg_trn_tprocurecost
					where proc_date >= _from_date and proc_date <= _to_date
					and   pg_id = _pg_id and status_code = 'A'
					
				 union all 
							select 
							   proc_date,
							   'loading unloading cost' as cost_type,
							   loading_unloading_cost as amount,
							   proccost_remark
					from	   pg_trn_tprocurecost
					where proc_date >= _from_date and proc_date <= _to_date
					and   pg_id = _pg_id and status_code = 'A'
					
				union all 
							select 
							   proc_date,
							   'Other Cost' as cost_type,
							   other_cost as amount,
							   proccost_remark
					from	   pg_trn_tprocurecost
					where proc_date >= _from_date and proc_date <= _to_date
					and   pg_id = _pg_id and status_code = 'A'
					order by proc_date;
					
end if;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_districtlist(_state_id udd_int, INOUT _result_district refcursor DEFAULT 'rs_district'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 03-01-2022
		
		Updated By : Mangai
		Updated Date : 20-01-2023
		
		SP Code : B01DSMG01
	*/
begin
	-- stored procedure body
	open _result_district for select 	
								district_id,
								state_id,
								district_code,
								district_name_en,
								district_name_hi,
								district_name_local
				  from 			district_master
				  where 		state_id = _state_id
				  and 			is_active = true
-- 				  order by 		is_active,district_id;
				  order by      district_name_en;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_finyearlist(_lang_code udd_code, INOUT _result_finyearlist refcursor DEFAULT 'rs_funyearlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$

declare
	/*
	 	created by   : Mangai
		created date : 07-03-2022
		SP Code		 : B01FING01	
	*/
	
begin

	open _result_finyearlist for select 
										finyear_id,
										finyear_name
								from    core_mst_tfinyear
					 		    where	status_code = 'A' ;
								
	end;
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_frontendmessagedesc(_lang_code udd_code, INOUT _result_frontendmsgdesc refcursor DEFAULT 'rs_frontendmsgdesc'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 08-02-2022
		SP Code : B01MSGG04
	*/
begin
	-- stored procedure body
	open _result_frontendmsgdesc for select 
										 mt.msg_code,
										 mt.msg_desc 
							 from 	     core_mst_tmessage as m
							 inner join  core_mst_tmessagetranslate as mt on m.msg_code = mt.msg_code
							 where 		 mt.lang_code = _lang_code
							 and 		 m.status_code = 'A' 
							 and 		 upper(substr(m.msg_code,2,1)) = 'F';
							 
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_funddisb_disbursementlist(_pg_id udd_code, _udyogmitra_id udd_code, _lang_code udd_code, INOUT _result_funddisb refcursor DEFAULT 'rs_funddisb'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 14-02-2022
		SP Code : B05FDRG01
	*/
begin
	-- stored procedure body
	open _result_funddisb for select 
								 fdt.funddisbtranche_gid as funddisbtranche_gid,
								 fd.source_inst_code as source_inst_code,		
								 fn_get_masterdesc('QCD_FUND_SOURCE',fd.source_inst_code,_lang_code) as source_inst_desc,
								 fd.funddisb_type_code as funddisb_type_code,
								 fn_get_masterdesc('QCD_FUND_TYPE',fd.funddisb_type_code,_lang_code) as ""Head"",
								 fd.loan_acc_no as loan_acc_no,
								 sum(fd.sanctioned_amount) as sanctioned_amount,
								 sum(fdt.tranche_amount) as tranche_amount,
								 fd.sanctioned_date as sanctioned_date,
								 fdt.tranche_no as tranche_no,
								 fdt.tranche_date as tranche_date,
								 '' as remarks,
								 fdt.received_date  as received_date,
								 fdt.received_ref_no as received_ref_no
				  from 			 pg_mst_tproducergroup as pg
-- 				  temparory commanded instraction from Vjvel on 04-mar-2022
-- 				  inner join 	 pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
-- 				  and 			 tran_status_code = 'A'
				  inner join 	 pg_trn_tfunddisbursement as fd on pg.pg_id = fd.pg_id
				  inner join 	 pg_trn_tfunddisbtranche as fdt on fd.funddisb_id = fdt.funddisb_id
				  and            fdt.tranche_status_code = 'QCD_DISB'
				  where 		 fd.pg_id = _pg_id
-- 				  and 			 um.udyogmitra_id = _udyogmitra_id
				  and 			 fd.status_code = 'A' 
				  group by 		 fd.source_inst_code,fd.funddisb_type_code,fd.loan_acc_no,
				  fdt.received_date,fdt.received_ref_no,fd.sanctioned_date,fdt.tranche_no,
				  fdt.funddisbtranche_gid;  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_funddisbursementlist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_fdlist refcursor DEFAULT 'rs_fdlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 03-01-2022
		SP Code : B05FDBG01
	*/
	v_block_id udd_int = 0;
	
begin

	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	open _result_fdlist for select 	
								 fd.funddisb_id as ""FundDisb ID"",
								 fd.funddisb_gid as ""FundDisb GID"",
								 fr.bussplan_id as ""BP ID"",
								 pg.pg_id as ""PG ID"",
								 pg.pg_name as ""PG Name"",
 								 (fn_get_fundrequesttotamt(fr.pg_id,fr.fundreq_id)::udd_amount -
								  fn_get_fundsantionedamount(fr.pg_id,fr.fundreq_id)::udd_amount)  as ""Disbu balance"",
								 fn_get_fundrequesttotamt(fr.pg_id,fr.fundreq_id)::udd_amount as ""FR Amount"",
								 fr.fundreq_remark as remarks, 
								 fd.funddisb_type_code as funddisb_type_code,
								 fn_get_masterdesc('QCD_FUND_TYPE',fd.funddisb_type_code,_lang_code) as ""Head"",
								 fd.source_inst_code as ""source_inst_code"",								 
								 fn_get_masterdesc('QCD_FUND_SOURCE',fd.source_inst_code,_lang_code) as ""Source"",
								 fd.loan_acc_no as ""Account_No"",
								 fd.sanctioned_date as ""Sanctioned Date"",
								 fd.sanctioned_amount as ""Sanctioned Amount"",
								 fn_get_masterdesc('QCD_FUNDDISB_STATUS',fd.status_code,_lang_code) as ""Status""
				  from 		 	 pg_mst_tproducergroup as pg
				  inner join 	 pg_trn_tfundrequisition as fr on pg.pg_id = fr.pg_id
				  and 		 	 fr.status_code = 'A'
				  inner join  	 pg_trn_tfunddisbursement as fd on fr.fundreq_id = fd.fundreq_id
				  where 	     pg.pg_id in (select fn_get_pgid(v_block_id))
				  and            pg.status_code = 'A'
-- 				  and 		 	 (fn_get_fundrequtotamount(fr.pg_id,fr.fundreq_id)::udd_amount - fd.sanctioned_amount) > '0'
				  order by 	 	 fd.funddisb_gid desc;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_fundrepymt(_pg_id udd_code, _from_date udd_date, _to_date udd_date, _lang_code udd_code, _user_code udd_code, INOUT _result_fundrepymt refcursor DEFAULT 'rs_fundrepymtlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 03-01-2022
		SP Code : B05FRPCUD
	*/
	-- stored procedure body
	open _result_fundrepymt for select 	
									a.fundrepymt_gid,
									a.pg_id,
									b.source_inst_code as source,
									fn_get_masterdesc('QCD_FUND_SOURCE',b.source_inst_code,_lang_code) as source_desc,
									b.funddisb_type_code as head,
									fn_get_masterdesc('QCD_FUND_TYPE',b.funddisb_type_code,_lang_code) as head_desc,
									b.sanctioned_amount,
									sum(a.paid_amount) as repaid_amount,
									0 as os_amount,
									a.loan_acc_no,
									a.pymt_date,
									a.pay_mode_code,
									a.pymt_ref_no,
									a.principal_amount,
									a.interest_amount,
									a.other_amount,
									a.pymt_remarks,
									a.status_code
							  from 	pg_trn_tfundrepymt as a
							  inner join pg_trn_tfunddisbursement as b
							  on 	a.pg_id = b.pg_id 
							  and 	a.loan_acc_no = b.loan_acc_no 
							  and 	b.status_code = 'A'
							  where a.status_code = 'A'
							  and   a.pg_id = _pg_id
							  and 	a.pymt_date >= _from_date
							  and 	a.pymt_date <= _to_date
							  group by a.pg_id,b.source_inst_code,b.funddisb_type_code,
							  b.sanctioned_amount,a.loan_acc_no,a.fundrepymt_gid
							  order by 	a.fundrepymt_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_fundrepymtlist(_pg_id udd_code, _lang_code udd_code, _user_code udd_code, INOUT _result_fundrepymt refcursor DEFAULT 'rs_fundrepymtlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 03-01-2022
		SP Code : B05FRPCUD
	*/
	-- stored procedure body
	open _result_fundrepymt for select 	
									a.fundrepymt_gid,
									a.pg_id,
									b.source_inst_code as source,
									fn_get_masterdesc('QCD_FUND_SOURCE',b.source_inst_code,_lang_code) as source_desc,
									b.funddisb_type_code as head,
									fn_get_masterdesc('QCD_FUND_TYPE',b.funddisb_type_code,_lang_code) as head_desc,
									b.sanctioned_amount,
									sum(a.paid_amount) as repaid_amount,
									0 as os_amount,
									a.loan_acc_no,
									a.pymt_date,
									a.pay_mode_code,
									a.pymt_ref_no,
									a.principal_amount,
									a.interest_amount,
									a.other_amount,
									a.pymt_remarks,
									a.status_code
							  from 	pg_trn_tfundrepymt as a
							  inner join pg_trn_tfunddisbursement as b
							  on 	a.pg_id = b.pg_id 
							  and 	a.loan_acc_no = b.loan_acc_no 
							  and 	b.status_code = 'A'
							  where a.status_code = 'A'
							  and   a.pg_id = _pg_id
							  group by a.pg_id,b.source_inst_code,b.funddisb_type_code,
							  b.sanctioned_amount,a.loan_acc_no,a.fundrepymt_gid
							  order by 	a.fundrepymt_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_fundreqactivelist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_fractlist refcursor DEFAULT 'rs_fractlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 04-02-2022
		SP Code : B05FRAG02
	*/
		v_block_id udd_int = 0;

begin
	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	open _result_fractlist for select 	
								 COALESCE(fr.fundreq_id,'0') as fundreq_id,
								 bp.bussplan_id as bussplan_id,
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 fn_get_villagedesc(pgadd.village_id) as village_id,
								 fn_get_blockdesc(pgadd.block_id) as block_id,
								 bp.period_from,
								 bp.period_to,
-- 								 fn_get_fundrequtotamount(fr.pg_id,fr.fundreq_id)::udd_amount as tot_fundreq_amount,
								 fn_get_fundrequesttotamt(fr.pg_id,fr.fundreq_id)::udd_amount as tot_fundreq_amount,
								 (fn_get_fundrequesttotamt(fr.pg_id, fr.fundreq_id)::udd_amount
								 - fn_get_fundsantionedamount(fr.pg_id, fr.fundreq_id)::udd_amount) as disbu_balance,
								 fr.fundreq_remark as fundreq_remark,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as bussplan_Status,
								 fn_get_masterdesc('QCD_STATUS',fr.status_code,_lang_code) as fundreq_Status
				  from 		 pg_mst_tproducergroup as pg
				  inner join pg_mst_taddress as pgadd on pg.pg_id = pgadd.pg_id
				  and 		 pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
				  inner join pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and        bp.status_code = 'A'
				  inner join  pg_trn_tfundrequisition as fr on pg.pg_id = fr.pg_id
				  and 		 bp.bussplan_id = fr.bussplan_id
				  and        fr.status_code = 'A' 
				  where 	 pg.pg_id in (select fn_get_pgid(v_block_id))
				  and 		 pg.status_code = 'A'
-- 				  and		 fr.created_by = _user_code
				  order by   fr.fundreq_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_fundreqapprovallist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_frapplist refcursor DEFAULT 'rs_frapplist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 01-02-2022
		SP Code : B05FRAG01
	*/
	v_block_id udd_int = 0;

begin
	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	open _result_frapplist for select 	
								 COALESCE(fr.fundreq_id,'0') as fundreq_id,
								 bp.bussplan_id as bussplan_id,
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 fn_get_villagedesc(pgadd.village_id) as village_id,
								 fn_get_blockdesc(pgadd.block_id) as block_id,
								 bp.period_from,
								 bp.period_to,
								 fr.tot_fundreq_amount as amount,
								 fn_get_fundrequtotamount(fr.pg_id, fr.fundreq_id) as tot_fundreq_amount,
								 fr.fundreq_remark as fundreq_remark,
								 bp.status_code as bussplan_Status_code,
								 coalesce(fr.status_code,'') as fundreq_Status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as bussplan_Status,
								 fn_get_masterdesc('QCD_STATUS',fr.status_code,_lang_code) as fundreq_Status
				  from 		 pg_mst_tproducergroup as pg
				  inner join pg_mst_taddress as pgadd on pg.pg_id = pgadd.pg_id
				  and 		 pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
				  inner join pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and        bp.status_code = 'A'
				  inner join pg_trn_tfundrequisition as fr on pg.pg_id = fr.pg_id
				  and 		 bp.bussplan_id = fr.bussplan_id
				  where 	 pg.pg_id in (select fn_get_pgid(v_block_id))
				  and		 bp.reviewer_code 	 	= _user_code
				  and        fr.status_code <> 'D' 
				  order by   fr.row_timestamp desc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_fundrequisitionlist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_frlist refcursor DEFAULT 'rs_frlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 31-12-2021
		SP Code : B05FRLG01
	*/
		v_block_id udd_int = 0;

begin
	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	open _result_frlist for select 	
								 COALESCE(fr.fundreq_id,'0') as fundreq_id,
								 bp.bussplan_id as bussplan_id,
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 fn_get_villagedesc(pgadd.village_id) as village_id,
								 fn_get_blockdesc(pgadd.block_id) as block_id,
								 bp.period_from,
								 bp.period_to,
								 fr.tot_fundreq_amount as amount,
								 fn_get_fundrequtotamount(fr.pg_id, fr.fundreq_id) as tot_fundreq_amount,
								 fr.fundreq_remark as fundreq_remark,
								 bp.status_code as bussplan_status_code,
								 coalesce(fr.status_code,'') as fundreq_status_code,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as bussplan_Status,
								 fn_get_masterdesc('QCD_STATUS',fr.status_code,_lang_code) as fundreq_Status
				  from 		 pg_mst_tproducergroup as pg
				  inner join pg_mst_taddress as pgadd on pg.pg_id = pgadd.pg_id
				  and 		 pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
				  inner join pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and        bp.status_code = 'A'
				  left join  pg_trn_tfundrequisition as fr on pg.pg_id = fr.pg_id
				  and 		 bp.bussplan_id = fr.bussplan_id
				  where 	 pg.pg_id in (select fn_get_pgid(v_block_id))
				  and		 bp.created_by 	 = _user_code
				  order by   bp.bussplan_gid desc;
				  -- order by   coalesce(fr.rowtimestamp,bp.rowtimestamp) desc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_incomeexpenselist(_tran_from udd_date, _tran_to udd_date, _pg_id udd_code, _user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_income_expense refcursor DEFAULT 'rs_incomeexpenselist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 03-01-2022
		SP Code : B05IEXCUD
	*/
		v_block_id udd_int = 0;
begin
	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	open _result_income_expense for select 	
									inx.incomeexpense_gid,
									inx.pg_id,
									inx.acchead_type_code,
									fn_get_masterdesc('QCD_ACC_HEAD_TYPE',inx.acchead_type_code,_lang_code) as acchead_type_desc,
									inx.acchead_code,
									fn_get_masterdesc('QCD_ACC_HEAD',inx.acchead_code,_lang_code) as acchead_desc,
									inx.tran_date,	
									inx.dr_amount,
									inx.cr_amount,
									case 
										when inx.acchead_type_code = 'QCD_EXPENSE' 
											then inx.dr_amount 
										when inx.acchead_type_code = 'QCD_INCOME' 
											then inx.cr_amount 
										else 0
									end as amount,
									inx.narration_code,
									fn_get_masterdesc('QCD_ACC_NARRATION',inx.narration_code,_lang_code) as narration_desc,	
									inx.tran_ref_no,
									inx.tran_remark,
									inx.pay_mode_code,
									fn_get_masterdesc('QCD_PAY_MODE',inx.pay_mode_code,_lang_code) as pay_mode_desc,
									inx.status_code,
									fn_get_masterdesc('QCD_STATUS',inx.status_code,_lang_code) as status_desc,
									inx.created_date,
									inx.created_by,
									inx.updated_date,
									inx.updated_by
						from 		pg_trn_tincomeexpense as inx
						inner join 	pg_mst_tproducergroup as pg 
						on 			inx.pg_id = pg.pg_id
						and 		pg.pg_id in (select fn_get_pgid(_block_code, _role_code, _user_code))
						and			pg.status_code = 'A'
						where 		inx.tran_date >= _tran_from
						and 		inx.tran_date <= _tran_to
						and 		inx.pg_id      = _pg_id
						and 		inx.status_code = 'A'
						order by 	inx.status_code,inx.pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_invoicelist(_pg_id udd_code, _lang_code udd_code, INOUT _result_invoice refcursor DEFAULT 'rs_invoice_list'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mangai
		Created Date : 22-08-2022
		SP Code : 
	*/
begin
	-- stored procedure body
	open _result_invoice for   select 		
									buyer_name, 
									inv_amount,
									inv_no,
									inv_date,
									collected_amount as received_amount ,
									inv_amount - collected_amount as balance_amount
						from 		pg_trn_tsale
						where       pg_id    = _pg_id
						and   		status_code = 'A';						
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_languagelist(INOUT _result_lang refcursor DEFAULT 'rs_lang'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	-- stored procedure body
	open _result_lang for select 	
							lang_gid,
							lang_code,
							lang_name,
							default_flag,
							status_code
				  from 		core_mst_tlanguage
		   		  order by 	lang_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_loanaccno(_pg_id udd_code, _source_inst_code udd_code, _lang_code udd_code, INOUT _result_loanaccno refcursor DEFAULT 'rs.loanaccno'::refcursor)
 LANGUAGE plpgsql
AS $procedure$

Declare
	/*
		Created by   : Mangai
		Created date : 15-03-2022
		SP Code		 : B04FUDG01
	*/
	
	begin
	
	-- Loan Account Number
	open _result_loanaccno for  select 
									     	loan_acc_no 
								from        pg_trn_tfunddisbursement
								where       source_inst_code = _source_inst_code
								and         pg_id            = _pg_id
								and         status_code      = 'A';
	end;
	$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_locallanguagelist(INOUT _result_lang refcursor DEFAULT 'rs_lang'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan
		Created Date : 30-12-2021
		SP Code : B01LCLG01
	*/
begin
	-- stored procedure body
	open _result_lang for select 	
							lang_gid,
							lang_code,
							lang_name,
							default_flag,
							status_code
				  from 		core_mst_tlanguage
				  where     default_flag = 'N' 
		   		  order by 	status_code,lang_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_lokossync(_state_id udd_int, INOUT _result_lokossync refcursor DEFAULT 'rs_lokossync'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin 
	/*
		Created By   : Mohan
		Created Date : 31-03-2022
		SP Code      : B01LSYG01
	*/

	open _result_lokossync for select 
									*
							from 	core_mst_tlokossync
							where	state_id 	= _state_id
							and 	status_code = 'A';
End;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_lokossyncqry(_state_id udd_int, _table_type_code udd_code, INOUT _result_lokossyncqry refcursor DEFAULT 'rs_lokossyncqry'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mohan
		Created Date : 31-03-2022
		SP Code      : B01LSQCUD
	*/
		_schema_name udd_desc := '';
		_last_sync_date udd_datetime := null;
begin 
	
	
	--Get Schema name,lastsyncdate 
	select 	schema_name,last_sync_date 
	into 	_schema_name,_last_sync_date 
	from 	core_mst_tlokossync 
	where 	state_id = _state_id;
	
	open _result_lokossyncqry for select 
									lokossyncqry_gid,
									lokossync_qry_name,
									replace
									(
										replace
										(
											replace(lokossync_qry collate pg_catalog.default,'_schema_name',_schema_name),
											'_state_id',_state_id::udd_text
										),
										'_last_sync_date',
										chr(39) || _last_sync_date::udd_text || chr(39)
									) as lokossync_qry,
									pg_sp_name,
									status_code,
									created_date,
									created_by,
									updated_date,
									updated_by
							from 	core_mst_tlokossyncqry
							where 	table_type_code = _table_type_code
							and 	status_code = 'A';
End;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_masterlist(_parent_code udd_code, _lang_code udd_code, INOUT _result_one refcursor DEFAULT 'rs_resultone'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	-- stored procedure body
	open _result_one for select 	
							master_gid,
							parent_code,
							fn_get_masterdesc('SYS',parent_code,_lang_code) as parent_desc,
							master_code,
							fn_get_masterdesc(parent_code,master_code,_lang_code) as master_desc,
							depend_parent_code,
							fn_get_masterdesc('SYS',depend_parent_code,_lang_code) as depend_parent_desc,
							depend_code,
							fn_get_masterdesc(depend_parent_code,depend_code,_lang_code) as depend_desc,
							sys_flag,
							fn_get_masterdesc('QCD_YES_NO',sys_flag,_lang_code) as sys_flag_desc,
							status_code,
							fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
							created_date,
							created_by,
							updated_date,
							updated_by,
							to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') as row_timestamp
				  from 		core_mst_tmaster
				  where 	parent_code = _parent_code
		   		  order by 	core_mst_tmaster.row_timestamp desc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_menulist(_lang_code udd_code, _user_code udd_user, _role_code udd_code, _block_code udd_code, INOUT _result_menu refcursor DEFAULT 'rs_menulist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 07-04-2022
		SP Code      : B01MENG01
		
	*/
	-- stored procedure body
	open _result_menu for select 	
								m.menu_gid,
								mt.menutranslate_gid,
								mt.menu_code,
								mt.menu_desc,
								m.status_code,
								fn_get_masterdesc('QCD_STATUS',m.status_code,_lang_code) as status_desc
				 from 			core_mst_tmenu as m
				 inner join 	core_mst_tmenutranslate as mt
				 on 			m.menu_code   = mt.menu_code
				 where 			mt.lang_code  = _lang_code
				 and			m.status_code = 'A'
				 order by 		m.status_code,m.menu_code;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_messagedesclist(_lang_code udd_code, INOUT _result_messagedesc refcursor DEFAULT 'rs_messagedesc'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Mohan
		Created Date : 24-02-2022
		SP Code : B01MSGG05
	*/
	-- stored procedure body
	open _result_messagedesc for select 	
									msg_code,
									fn_get_msg(msg_code, _lang_code) as msg_desc,
									_lang_code as lang_code
						  from 		core_mst_tmessage
						  where 	status_code = 'A'
						  order by 	msg_code;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_messagedescription(_msg_code udd_code, _lang_code udd_code, INOUT _result_msgdesc refcursor DEFAULT 'rs_msgdesc'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 08-02-2022
		SP Code : B01MSGG03
	*/
	v_count udd_int := 0;
begin
	-- stored procedure body
	open _result_msgdesc for select 
							 fn_get_msg(_msg_code, _lang_code) as fn_get_msg;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_messagelist(_lang_code udd_code, _user_code udd_code, INOUT _result_message refcursor DEFAULT 'rs_messagelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01MSGG01
		
		Updated By : Mohan
		Updated Date : 07-04-2022
	*/
	-- stored procedure body
	open _result_message for select 	
								msg.msg_gid,
								msgtran.msgtranslate_gid,
								msgtran.msg_code,
								msgtran.msg_desc,
								msg.status_code,
								fn_get_masterdesc('QCD_STATUS',msg.status_code,_lang_code) as status_desc
				 from 			core_mst_tmessage as msg
				 inner join 	core_mst_tmessagetranslate as msgtran
				 on 			msg.msg_code = msgtran.msg_code
				 where 			msgtran.lang_code = _lang_code
				 and			msg.status_code = 'A'
				 order by 		msg.status_code,msg.msg_code;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_mobilesyncdtl(_pg_id udd_code, _role_code udd_code, _user_code udd_code, _mobile_no udd_mobile, _sync_type_code udd_code, INOUT _result_mblsync refcursor DEFAULT 'rs_mblsync'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
	/*
		Created By : Mohan s
		Created Date : 15-02-2022
		SP Code : B01MBSG01
	*/
begin
	-- stored procedure body
	
if not exists  (select 	* 
				   	from 	core_mst_tmobilesync
				   	where 	pg_id = _pg_id
					and 	role_code = _role_code
					and 	user_code = _user_code
					and 	mobile_no = mobile_no
					and 	sync_type_code = _sync_type_code
					and		status_code = 'A'
				   ) then
				   
	Insert into core_mst_tmobilesync (		pg_id,
											role_code,
											user_code,
											mobile_no,
											sync_type_code,
											last_sync_date,
											prev_last_sync_date,
											status_code,
											created_date,
											created_by)
								values 		(_pg_id,
											_role_code,
											_user_code,
											_mobile_no,
											_sync_type_code,
											'2020-01-01',
											'2020-01-01',
											'A',
											now(),
											_user_code);
	end if;

	open _result_mblsync for select 	
							mobilesync_gid,
							pg_id,
							role_code,
							user_code,
							mobile_no,
							sync_type_code,
							(last_sync_date::timestamp without time zone)::text as last_sync_date,
							(prev_last_sync_date::timestamp without time zone)::text as prev_last_sync_date,
							status_code,
							created_date,
							created_by,
							updated_date,
							updated_by,
							(now()::timestamp without time zone)::text as ""system_datetime""
				  from 		core_mst_tmobilesync
				  where 	pg_id = _pg_id
				  and 		role_code = _role_code
				  and 		user_code = _user_code
				  and 		mobile_no = _mobile_no
				  and 		sync_type_code = _sync_type_code
				  and 		status_code = 'A';
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_mtwaggresync(_procure udd_jsonb, _sale udd_jsonb, _procure_cost udd_jsonb, _session udd_jsonb, _sync_info udd_jsonb, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B06SYNG01
	*/
begin
	-- stored procedure body 
	call public.pr_iud_mtwaggreofprodjson(_procure::udd_jsonb);
	
    select 	'Data Synced Successfully' into _succ_msg ;
	
	call public.pr_iud_mtwsalejson(_sale::udd_jsonb);
	
	call public.pr_iud_mtwprocurecostjson(_procure_cost::udd_jsonb);
	
	call public.pr_iud_mtwsessionjson(_session::udd_jsonb);
	
	call public.pr_iud_mtwmobilesyncjson(_sync_info::udd_jsonb);
   
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_mtwaggresyncstring(_procure udd_text, _sale udd_text, _procure_cost udd_text, _session udd_text, _sync_info udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B06SYNG01
	*/
begin
	-- stored procedure body 
	call public.pr_iud_mtwaggreofprodjson(_procure::udd_jsonb);
	
	call public.pr_iud_mtwsalejson(_sale::udd_jsonb);
	
	call public.pr_iud_mtwprocurecostjson(_procure_cost::udd_jsonb);
	
	call public.pr_iud_mtwsessionjson(_session::udd_jsonb);
	
	call public.pr_iud_mtwmobilesyncjson(_sync_info::udd_jsonb);
	
    select 	'Data Synced Successfully' into _succ_msg ;
	
   
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_panchayatlist(_block_id udd_int, INOUT _result_panchayatlist refcursor DEFAULT 'rs_panlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	/*
		Created By : Mohan S
		Created Date : 03-01-2022
		SP Code : B01GPMG01
	*/
begin
	-- stored procedure body
	open _result_panchayatlist for select 	
									  	panchayat_id,
										fn_get_panchayatdesc(panchayat_id) as panchayat_desc,
										state_id,
										fn_get_statedesc(state_id) as state_desc,
										district_id,
										fn_get_districtdesc(district_id) as district_desc,
										block_id,
										fn_get_blockdesc(block_id) as block_desc,
										panchayat_code,
										panchayat_name_en,
										panchayat_name_local
							from 		panchayat_master
				  			where 		block_id = _block_id
				 		 	and 		is_active = true
				  			order by 	panchayat_name_en;
				 
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_panchayatmappedlist(_pg_id udd_code, INOUT _result_gpmappedlist refcursor DEFAULT 'rs_gpmappedlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	/*
		Created By : Mohan S
		Created Date : 17-02-2022
		SP Code : B04GPMG01
	*/
begin
	-- stored procedure body
	open _result_gpmappedlist for select 	
									  	gpm.panchayat_id,
										fn_get_panchayatdesc(gpm.panchayat_id) as panchayat_desc,
										addr.village_id,
										fn_get_villagedesc(addr.village_id) as village_desc
							from 		pg_mst_tproducergroup as pg
							inner join  pg_mst_taddress as addr on pg.pg_id = addr.pg_id
							and 		addr_type_code = 'QCD_ADDRTYPE_REG'
							inner join  pg_mst_tpanchayatmapping as gpm on pg.pg_id = gpm.pg_id
				  			where 		pg.pg_id = _pg_id;
				 
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgblkgpvillagelist(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, INOUT _result_pgnamelist refcursor DEFAULT 'rs_pgnamelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 21-02-2022
		SP Code : B04BPVG01
	*/
begin
	-- stored procedure body
	open _result_pgnamelist for select distinct
								pg.pg_id,
								pg.pg_name,
								concat(pg.pg_id,'-',pg.pg_name) as pg_id_name
				  from 			pg_location_view as lv
				  inner join 	pg_mst_tproducergroup as pg on lv.pg_id = pg.pg_id
				  where 		lv.block_id = _block_id
				  and 			lv.panchayat_id =
				  case 
							when _panchayat_id = 0  then 
								coalesce(lv.panchayat_id,_panchayat_id)
							else 
								coalesce(_panchayat_id,lv.panchayat_id) 
				  end 
				  and		lv.village_id = 	
				  case 			
							when _village_id = 0  then 
								coalesce(lv.village_id,_village_id)
							else 
								coalesce(_village_id,lv.village_id) 
				  end 
				  order by 		pg.pg_name;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgblwthresholdreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _status_code udd_code, _lang_code udd_code, INOUT _result_pgblwthreshold refcursor DEFAULT 'rs_pgblwthreshold'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By   : Mangai
		Created Date : 31-03-2022
		SP Code      : B08BTHR01
	*/
	
begin
	
	-- stored procedure body
	open _result_pgblwthreshold for select 	
											pg.pg_id,
											pg.pg_name,
											pg.formation_date,
											um.udyogmitra_name as udyogmitra_name,
											um.mobile_no as mobile_no,
											fn_get_villagecount_pgid(pg.pg_id) as village_count,
											fn_get_membercount_pgid(pg.pg_id) as member_count,
											fn_get_masterdesc('QCD_ADDR_TYPE',addr.addr_type_code,_lang_code) as addr_type_desc,
											addr.addr_line,
											fn_get_villagedesc(addr.village_id) as village_desc,
											fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
											fn_get_blockdesc(addr.block_id) as block_desc,
											fn_get_districtdesc(addr.district_id) as district_desc,
											fn_get_statedesc(addr.state_id) as state_desc,
											fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc,
											pg.status_code as status_code
								  from 		pg_mst_tproducergroup as pg
								  left join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
								  and 		addr.addr_type_code = 'QCD_ADDRTYPE_REG'
  								  left join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
								  and 		um.tran_status_code <> 'I'
								  where 	addr.block_id = case 
																when _block_id = 0 then 
																	 coalesce(addr.block_id,_block_id)
																else 
																	coalesce(_block_id,addr.block_id) 
															 end
								  and addr.panchayat_id = case 
															when _panchayat_id = 0 then 
																 coalesce(addr.panchayat_id,_panchayat_id)
															 else 
																coalesce(_panchayat_id,addr.panchayat_id) 
														  end
								 and addr.village_id = case 
															when _village_id = 0 then 
																 coalesce(addr.village_id,_village_id)
															 else 
																coalesce(_village_id,addr.village_id) 
														  end
								 and pg.status_code = case 
															when _status_code = '' then 
																 coalesce(pg.status_code,_status_code)
															 else 
																coalesce(_status_code,pg.status_code) 
														  end
								  and       pg.status_code in ('D','M')
								 order by 	pg_gid desc;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgdtl(_pg_id udd_code, _lang_code udd_code, INOUT _result_profile refcursor DEFAULT 'rs_profile'::refcursor, INOUT _result_address refcursor DEFAULT 'rs_address'::refcursor, INOUT _result_panchayat refcursor DEFAULT 'rs_panchayat'::refcursor, INOUT _result_collpoint refcursor DEFAULT 'rs_collpoint'::refcursor, INOUT _result_bank refcursor DEFAULT 'rs_bank'::refcursor, INOUT _result_udyog_mitra refcursor DEFAULT 'rs_udyog_mitra'::refcursor, INOUT _result_product refcursor DEFAULT 'rs_product'::refcursor, INOUT _result_office_bearers refcursor DEFAULT 'rs_office_bearers'::refcursor, INOUT _result_activities refcursor DEFAULT 'rs_activities'::refcursor, INOUT _result_bomanager refcursor DEFAULT 'rs_bomanager'::refcursor, INOUT _result_fin_summ refcursor DEFAULT 'rs_finsumm'::refcursor, INOUT _result_fund_supp refcursor DEFAULT 'rs_fundsupp'::refcursor, INOUT _result_attachment refcursor DEFAULT 'rs_attach'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 13-12-2021
		SP Code : B04PGPG02
		
		updated by : Mohan S
		updated date : 20-01-2023
	*/
	 config_path udd_text := '';
begin
	select  fn_get_configvalue('server_atm_path')
	into 	config_path;
	-- stored procedure body
	-- PROFILE --
	open _result_profile for select 	
							pg_gid,
							pg_id,
							pg_name,
							pg_ll_name,
							fn_get_villagecount_pgid(_pg_id) as village_count,
							fn_get_membercount_pgid(_pg_id) as member_count,
							pg_type_code,
							fn_get_masterdesc('QCD_PG_TYPE',pg_type_code,_lang_code) as pg_type_desc,
							formation_date,
							promoter_code,
							fn_get_masterdesc('QCD_PROMOTER',promoter_code,_lang_code) as promoter_desc,
							state_id,
							fn_get_statedesc(state_id) as state_desc,
							district_id,
							fn_get_districtdesc(district_id) as district_desc,
							block_id,
							fn_get_blockdesc(block_id) as block_desc,
							panchayat_id,
							fn_get_panchayatdesc(panchayat_id) as panchayat_desc,
							village_id,
							fn_get_villagedesc(village_id) as village_desc,
							cbo_id,
							cbo_name,
							clf_id,
							clf_name,
							status_code,
							fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
							created_date,
							created_by,
							updated_date,
							updated_by,
							row_timestamp
				  from 		pg_mst_tproducergroup
				  where 	pg_id = _pg_id
		   		  order by 	pg_gid;
				 
	-- ADDRESS --
	open _result_address for select 
							 add.pgaddress_gid,
							 add.pg_id,
							 add.addr_type_code,
							 fn_get_masterdesc('QCD_ADDR_TYPE',add.addr_type_code,_lang_code) as addr_type_desc,
							 add.addr_line,
							 add.pin_code,
							 add.village_id,
							 fn_get_villagedesc(add.village_id) as village_desc,
							 fn_get_villagecode(add.village_id) as village_code,
							 add.panchayat_id,
							 fn_get_panchayatdesc(add.panchayat_id) as panchayat_desc,
							 fn_get_panchayatcode(add.panchayat_id) as panchayat_code,
							 add.block_id,
							 fn_get_blockdesc(add.block_id) as block_desc,
							 fn_get_blockcode(add.block_id) as block_code,
							 add.district_id,
							 fn_get_districtdesc(add.district_id) as district_desc,
							 fn_get_districtcode(add.district_id) as district_code,
							 add.state_id,
							 fn_get_statedesc(add.state_id) as state_desc,
							 fn_get_statecode(add.state_id) as state_code,
							 pg.status_code,
							 fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc
				  from 		 pg_mst_taddress as add
				  inner join pg_mst_tproducergroup as pg
				  on         add.pg_id = pg.pg_id
				  where 	 add.pg_id = _pg_id; 
				  
	-- PANCHAYAT -- 
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
	open _result_panchayat for select distinct
										 pm.pgpanchayatmapping_gid,
										 pm.pg_id,
										 pm.state_id,
										 fn_get_statedesc(pm.state_id) as state_desc,
										 pm.district_id,
										 fn_get_districtdesc(pm.district_id) as district_desc,
										 pm.panchayat_id,
										 fn_get_panchayatdesc(pm.panchayat_id) as panchayat_desc,
										 pm.block_id,
										 fn_get_blockdesc(pm.block_id) as block_desc,
										 pg.status_code,
										 fn_get_masterdesc('QCD_STATUS',pg.status_code,'en_US') as status_desc,
										 fn_get_concatvillage(pm.pg_id,pm.panchayat_id) as village_desc,
										 fn_get_concatvillage_jsonb(pm.pg_id,pm.panchayat_id,vm.village_id) as village_desc_json
							  from 		 pg_mst_tpanchayatmapping as pm
							  inner join pg_mst_tvillagemapping as vm
							  on 		 pm.panchayat_id = vm.panchayat_id
							  and 		 pm.pg_id = vm.pg_id
							  inner join pg_mst_tproducergroup as pg
							  on         pm.pg_id = pg.pg_id
							  where 	 pm.pg_id = _pg_id
							  group by  pm.pgpanchayatmapping_gid,pm.pg_id,pm.state_id,pm.district_id,pm.panchayat_id, pm.block_id,
							  			pg.status_code,vm.village_id;
							 /*select 
							 pm.pgpanchayatmapping_gid,
							 pm.pg_id,
							 pm.state_id,
							 fn_get_statedesc(pm.state_id) as state_desc,
							 pm.district_id,
							 fn_get_districtdesc(pm.district_id) as district_desc,
							 pm.panchayat_id,
							 fn_get_panchayatdesc(pm.panchayat_id) as panchayat_desc,
							 pm.block_id,
							 fn_get_blockdesc(pm.block_id) as block_desc,
							 pg.status_code,
							 fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc
				  from 		 pg_mst_tpanchayatmapping as pm
				  inner join pg_mst_tproducergroup as pg
				  on         pm.pg_id = pg.pg_id
				  where 	 pm.pg_id = _pg_id;*/
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001			  
	-- COLLECTION POINT -- 
	open _result_collpoint for 	select 
								collpoint_gid,
								pg_id,
								row_number() over (order by collpoint_gid) as collpoint_no,
								collpoint_name,
								fn_get_collpoint_name(pg_id,collpoint_no,collpoint_lang_code) as collpoint_ll_name,
								collpoint_lang_code,
								fn_get_languagedesc(collpoint_lang_code) as lang_desc,
								latitude_code,
								longitude_code
					  from 		pg_mst_tcollectionpoint 
					  where 	pg_id = _pg_id
					  and 		status_code = 'A';
				  
	-- BANK --
	open _result_bank for select 
						 pgbank_gid,
						 pg_id,
						 bankacc_type_code,
						 fn_get_masterdesc('QCD_BANKACC_TYPE',bankacc_type_code,_lang_code) as bankacc_type_desc,
						 ifsc_code,
						 bank_code,
						 fn_get_masterdesc('QCD_BANK',bank_code,_lang_code) as bank_desc,
						 bank_name,
						 branch_name,
						 bankacc_no
				  from 	 pg_mst_tbank
				  where  pg_id = _pg_id;
				  
	-- UDYOG MITRA --
	open _result_udyog_mitra for select 
				  				pgudyogmitra_gid,
								pg_id,
								udyogmitra_id,
								udyogmitra_name,
								mobile_no,
								token_no,
								tran_status_code,
								fn_get_masterdesc('QCD_TRAN_STATUS',tran_status_code,_lang_code) as status_desc,
								pgmember_type_code,
								fn_get_masterdesc('QCD_PGMEMBER_TYPE',pgmember_type_code,_lang_code) as pgmember_type_desc,
								fatherhusband_name,
								village_id,
								fn_get_villagedesc(village_id) as village_desc,
								shgmember_relation_code,
								shgmember_id,
								shgmember_name,
								shgmember_mobile_no,
								fn_get_shgmembervillagedesc(pg_id,shgmember_id) as shgmem_villagedesc,
								fn_get_shgmemberpanchayatdesc(pg_id,shgmember_id) as shgmem_panchayatdesc,
								fn_get_shgmembervillage(pg_id,shgmember_id) as shgmem_village,
								fn_get_shgmemberpanchayat(pg_id,shgmember_id) as shgmem_panchayat
				  	from 		pg_mst_tudyogmitra
				  	where 		pg_id = _pg_id
					order by 	pg_id,tran_status_code;
					
	-- PRODUCT --  
	open _result_product for select
							promap.pgprodmapp_gid as pgprodmapp_gid,
							promap.pg_id as pg_id,
							promap.prod_code as prod_code,
-- 							protran.prod_desc as prod_desc,
							pro.prod_type_code as prod_type_code,
							fn_get_masterdesc('QCD_PROD_TYPE',pro.prod_type_code,_lang_code) as prod_type_desc,
							pro.category_code as category_code,
							fn_get_masterdesc('QCD_CATEGORY',pro.category_code,_lang_code) as category_desc,
							pro.subcategory_code as subcategory_code,
							fn_get_masterdesc('QCD_SUBCATEGORY',pro.subcategory_code,_lang_code) as subcategory_desc,
							promap.frequent_flag as frequent_flag,
							fn_get_productdesc(promap.prod_code,_lang_code) as prod_desc,
							-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
							case 
								when promap.stock_reset_flag = 'Y' then 
									'N' 
								else 'Y' 
							end as stock_reset_flag,
-- 							fn_get_masterdesc('QCD_YES_NO',stock_reset_flag,_lang_code) as stock_reset_flag_desc,
							case 
								when promap.stock_reset_flag = 'Y' then
									fn_get_masterdesc('QCD_YES_NO','N',_lang_code) 
								else 
									fn_get_masterdesc('QCD_YES_NO','Y',_lang_code) 
							end as stock_reset_flag_desc
							-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001
					from 	pg_mst_tproductmapping as promap
					inner join core_mst_tproduct as pro on promap.prod_code = pro.prod_code
-- 					inner join core_mst_tproducttranslate as protran on pro.prod_code = protran.prod_code
					where 	promap.pg_id = _pg_id ;
-- 					and protran.lang_code = _lang_code ;

	-- OFFICE BEARERS --
	/*open _result_office_bearers for select
								   pgoffbearer_gid,
								   pg_id,
								   offbearer_name as offbearer_id,
								   fn_get_pgmembername(pg_id, offbearer_name) offbearer_name,
								   designation_code,
								   fn_get_masterdesc('QCD_DESIGNATION',designation_code,_lang_code) as designation_desc,
								   signatory_code,
								   fn_get_masterdesc('QCD_SIGNATORY',signatory_code,_lang_code) as signatory_desc,
								   mobile_no
					from 		   pg_mst_tofficebearers
					where 		   pg_id = _pg_id;*/
					
	-- OFFICE BEARERS --				
	open _result_office_bearers for select 	
									 _pg_id as pg_id,
									 pgmember_name as offbearer_name,
									 fn_get_masterdesc('QCD_DESIGNATION',designation_code,_lang_code) as designation_desc,
									 designation_code,
									 fn_get_masterdesc('QCD_SIGNATORY',signatory_code,_lang_code) as signatory_desc,
									 signatory_code,
									 case when mobile_no_active = '' then
									  			mobile_no_alternative
									 else
									  			mobile_no_active
									 end as 	mobile_no
						  from 		 pg_mst_tpgmember
						  where 	 pg_id = _pg_id
						  and 		 officebearer_flag = 'Y'
-- 						  and 		 pgmember_clas_code = 'PG'
						  and 		 status_code = 'A';
					
	-- ACTIVITIES --
	open _result_activities for select
-- 								pgactivitity_gid,
								pg_id,
								prod_code,
								fn_get_productdesc(prod_code,_lang_code) as prod_desc,
-- 								seq_no,
-- 								activity_code,
								json_agg(activity_code)::udd_text as activity_code,
-- 								fn_get_masterdesc('QCD_ACTIVITY',activity_code,_lang_code) as activity_desc
								json_agg(fn_get_masterdesc('QCD_ACTIVITY',activity_code,_lang_code))::udd_text as activity_desc
					from	    pg_mst_tactivity
					where 		pg_id = _pg_id
					group 	by  pg_id,prod_code;
	/*				
	-- CLF --
	open _result_clf for select
						pgclf_gid,
						pg_id,
						clf_id,
						clf_name,
						clf_officer_id,
						clf_officer_name
				from	pg_mst_tclf
				where 	pg_id = _pg_id;
	*/
	
	-- Bomanager --
	open _result_bomanager for select
						pgbomanager_gid,
						pg_id,
						bomanager_id,
						bomanager_name
				from	pg_mst_tbomanager
				where 	pg_id = _pg_id;
				
	-- FINANCIAL SUMMARY --
	open _result_fin_summ for select
							 pgfinsumm_gid,
							 pg_id,
							 till_date,
							 cash_in_hand,
							 cash_in_bank,
							 opening_stock_value
					from     pg_mst_tfinancesumm
					where 	 pg_id = _pg_id; 
					
					
	-- FUND SUPPORT --
 	open _result_fund_supp for select
							  pgfundsupp_gid,
							  pg_id,
							  fund_source_code,
							  fn_get_masterdesc('QCD_FUND_SOURCE',fund_source_code,_lang_code) as fund_source_desc,
							  fund_type_code,
							  fn_get_masterdesc('QCD_FUND_TYPE',fund_type_code,_lang_code) as fund_type_desc,
							  fund_supp_date,
							  fund_supp_amount,
							  purpose_code,
							  fn_get_masterdesc('QCD_PURPOSE',purpose_code,_lang_code) as purpose_desc
					from 	  pg_mst_tfundsupport
					where 	  pg_id = _pg_id;
					
	-- ATTACHMENT --
 	open _result_attachment for select
							  pgattachment_gid,
							  pg_id,
							  doc_type_code,
							  fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
							  doc_subtype_code,
							  fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
							  config_path || file_path as file_path,
							  file_name,
							  attachment_remark,
							  original_verified_flag,
							  fn_get_masterdesc('QCD_YES_NO',original_verified_flag,_lang_code) as original_verified_desc,
							  created_by
					from 	  pg_mst_tattachment
					where 	  pg_id = _pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgfund(_pg_id udd_code, _pgfund_code udd_code, _lang_code udd_code, INOUT _result_pgfund refcursor DEFAULT 'rs_pgfund'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 02-03-2022
		SP Code      : B05FUECUD
	*/
	
	-- PG Fund Expenses
	open _result_pgfund for select
								pgfund_gid,
								pg_id,
								fn_get_pgname(pg_id) as pg_name,
								pgfund_code,
								fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code) as pgfund_desc,
								pgfund_date,
								pgfund_source_code,
								fn_get_masterdesc('QCD_PGFUND_SOURCE',pgfund_source_code,_lang_code) as pgfund_source_desc,
								pgfund_amount,
								pgfund_available_amount,
								pgfund_remark,
								fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc
						 from   pg_trn_tpgfund
						 where  pg_id  = _pg_id
						 and 	pgfund_code = _pgfund_code
						 and 	status_code = 'A';
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgfundexpenseslist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _from_date udd_date, _to_date udd_date, _pg_id udd_code, _lang_code udd_code, INOUT _result_pgfundexplist refcursor DEFAULT 'rs_pgfundexplist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By   : Mangai
		Created Date : 02-03-2022
		SP Code      : B05FUECUD
	*/
	
	v_block_id udd_int = 0;
	
begin

	-- PG Fundexpenses
	/*
	open _result_pgfundexplist for select 
									fx.pgfundexp_gid,
									fx.expense_date,
									fx.pgfund_code,
									fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code)
																	as pgfund_code_desc,
									fx.expense_head_code,
									fn_get_masterdesc('QCD_PGFUND_EXPHEAD',expense_head_code,_lang_code)
																	as expense_head_code_desc,
									fx.beneficiary_name,
									fx.expense_amount,
									fx.recovery_flag,
									fn_get_masterdesc('QCD_YES_NO',recovery_flag,_lang_code)
																	as recovery_flag_desc,
									coalesce(fx.expense_remark,'') as expense_remark ,
									pg.pg_name
						from 		pg_trn_tpgfundexpenses as fx
						inner join  pg_mst_tproducergroup as pg
						on          fx.pg_id = pg.pg_id
						and         pg.status_code <> 'I'
						where 		fx.expense_date >= _from_date
						and 		fx.expense_date <= _to_date
						and 		fx.pg_id = _pg_id
						and         fx.status_code <> 'I';
	*/
	
	select fn_get_blockid(_block_code)::udd_int into v_block_id;
						
	open _result_pgfundexplist for select 
									fx.pgfundledger_gid as pgfundexp_gid,
									fx.tran_date as expense_date,
									fx.pgfund_code,
									fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code)
																	as pgfund_code_desc,
									fx.pgfund_ledger_code as expense_head_code,
									fn_get_masterdesc('QCD_PGFUND_LEDGER',fx.pgfund_ledger_code,_lang_code)
																	as expense_head_code_desc,
									fx.beneficiary_name,
									fx.dr_amount as expense_amount,
									fx.recovery_flag,
									fn_get_masterdesc('QCD_YES_NO',recovery_flag,_lang_code)
																	as recovery_flag_desc,
									coalesce(fx.pgfund_remark,'') as expense_remark ,
									pg.pg_name
						from 		pg_trn_tpgfundledger as fx
						inner join  pg_mst_tproducergroup as pg
						on          fx.pg_id = pg.pg_id
						and         pg.pg_id in (select fn_get_pgid(v_block_id))
						and         pg.status_code <> 'I'
						where 		fx.tran_date >= _from_date
						and 		fx.tran_date <= _to_date
						and 		fx.pg_id = _pg_id
						and 		fx.pgfund_trantype_code = 'QCD_PGFUND_EXPENSES'
						and         fx.status_code <> 'I';
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgfundledger(_pg_id udd_code, _pgfund_code udd_code, _from_date udd_date, _to_date udd_date, _pgfund_trantype_code udd_code, _pgfund_ledger_code udd_code, _lang_code udd_code, INOUT _result_fundledglist refcursor DEFAULT 'rs_fundledglist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 08-03-2022
		SP Code : B05FDLG01
	*/
begin
	-- stored procedure body
	open _result_fundledglist for select 
									pgfundledger_gid,
									pg_id,
									pgfund_code,
									fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code) as pgfund_desc,
									pgfund_trantype_code,
									fn_get_masterdesc('QCD_PGFUND_TRANTYPE',pgfund_trantype_code,_lang_code) as pgfund_trantype_desc,
									pgfund_ledger_code,
									fn_get_masterdesc('QCD_ACC_HEAD',pgfund_ledger_code,_lang_code) as pgfund_ledger_desc,
									tran_date,
									cr_amount,
									dr_amount,
									recovery_flag,
									recovered_flag,
									beneficiary_name,
									pgfund_remark,
									status_code,
									fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc
					  from 			pg_trn_tpgfundledger
					  where 		pg_id = _pg_id
					  and 			tran_date >= _from_date
					  and 			tran_date <= _to_date
 					  and 			pgfund_trantype_code = _pgfund_trantype_code
					  and 			status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgfundledgersumm(_pg_id udd_code, _from_date udd_date, _to_date udd_date, _lang_code udd_code, INOUT _result_fundledgsumm refcursor DEFAULT 'rs_fundledgsumm'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 08-03-2022
		SP Code : B05FLSG01
	*/
begin
	-- stored procedure body
	open _result_fundledgsumm for select 
									pgfundledgersumm_gid,
									pg_id,
									pgfund_code,
									fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code) as pgfund_desc,
									dr_amount,
									cr_amount,
									as_of_date,
									status_code,
									fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc
					  from 			pg_trn_tpgfundledgersumm
					  where 		pg_id = _pg_id
					  and 			status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgfundlist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _from_date udd_date, _to_date udd_date, _pg_id udd_code, _lang_code udd_code, INOUT _result_pgfundlist refcursor DEFAULT 'rs_pgfundlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By   : Mangai
		Created Date : 02-03-2022
		SP Code      : B05FUNCUD
	*/
	v_block_id udd_int = 0;
	
begin
	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- PG Fund
	open _result_pgfundlist for select 
									f.pgfundledger_gid as pgfund_gid,
									f.tran_date as pgfund_date,
									f.pgfund_code,
									fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code)
																	as pgfund_code_desc,
									f.pgfund_ledger_code as pgfund_source_code,
									fn_get_masterdesc('QCD_ACC_HEAD',pgfund_ledger_code,_lang_code)
																	as pgfund_source_code_desc,
									f.cr_amount as pgfund_amount,
									f.pgfund_remark,
									pg.pg_name
						from 		pg_trn_tpgfundledger as f
						inner join  pg_mst_tproducergroup as pg
						on          f.pg_id = pg.pg_id
						and         pg.pg_id in (select fn_get_pgid(v_block_id))
						and         pg.status_code <> 'I'
						where 		f.tran_date >= _from_date
						and 		f.tran_date <= _to_date
						and 		f.pg_id	= _pg_id
						and			f.pgfund_trantype_code = 'QCD_PGFUND_SOURCE'
						and         f.status_code <> 'I';
						
						
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pglist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_pg refcursor DEFAULT 'rs_pglist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
/*
	Created By : Mohan S
	Created Date : 13-12-2021
	SP Code : B04PGPG01
*/
	v_block_id udd_int = 0;

begin

-- 	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	open _result_pg for select 	
							pg_gid,
							pg_id,
							pg_name,
							pg_ll_name,
							pg_type_code,
							fn_get_masterdesc('QCD_PG_TYPE',pg_type_code,_lang_code) as promoter_desc,
							formation_date,
							promoter_code,
							fn_get_masterdesc('QCD_PROMOTER',promoter_code,_lang_code) as promoter_desc,
							state_id,
							fn_get_statedesc(state_id) as state_desc,
							district_id,
							fn_get_districtdesc(district_id) as district_desc,
							block_id,
							fn_get_blockdesc(block_id) as block_desc,
							panchayat_id,
							fn_get_panchayatdesc(panchayat_id) as panchayat_desc,
							village_id,
							fn_get_villagedesc(village_id) as village_desc,
							cbo_id,
							cbo_name,
							clf_id,
							clf_name,
							status_code,
							fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
							created_date,
							created_by,
							updated_date,
							updated_by,
							row_timestamp
				  from 		pg_mst_tproducergroup
				  where 	pg_id in (select fn_get_pgid(_block_code, _role_code, _user_code))
				  and       status_code = 'A'
		   		  order by 	pg_name;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pglistreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _status_code udd_code, _lang_code udd_code, INOUT _result_pglist refcursor DEFAULT 'rs_pglist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 18-02-2022
		SP Code : B08PGLR01
	*/
	
begin
	if _block_id = 0 then
		_block_id = null;
	end if;

	if _panchayat_id = 0 then
		_panchayat_id = null;
	end if;

	if _village_id = 0 then
		_village_id = null;
	end if;
	
	if _status_code = '' then
		_status_code = null;
	end if;

	-- stored procedure body
	open _result_pglist for select 	
							pg.pg_id,
							pg.pg_name,
							pg.formation_date,
							um.udyogmitra_name as udyogmitra_name,
							um.mobile_no as mobile_no,
				 			addr.addr_line,
							pg.status_code as status_code,
							fn_get_villagecount_pgid(pg.pg_id) as village_count,
							fn_get_membercount_pgid(pg.pg_id) as member_count,
							fn_get_masterdesc('QCD_ADDR_TYPE',addr.addr_type_code,_lang_code) as addr_type_desc,
							fn_get_villagedesc(addr.village_id) as village_desc,
							fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
							fn_get_blockdesc(addr.block_id) as block_desc,
							fn_get_districtdesc(addr.district_id) as district_desc,
							fn_get_statedesc(addr.state_id) as state_desc,
							fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc
				  from 		pg_mst_tproducergroup as pg
				  left join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
				  and 		addr.addr_type_code = 'QCD_ADDRTYPE_REG'
				  left join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 		um.tran_status_code <> 'I'
				  where 	addr.block_id = coalesce(_block_id,addr.block_id)
				  and 		addr.panchayat_id = coalesce(_panchayat_id,addr.panchayat_id)
				  and 		addr.village_id = coalesce(_village_id,addr.village_id) 
				  and 		pg.status_code = coalesce(_status_code,pg.status_code)
				  order by pg_gid desc;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberdtl(_pg_id udd_code, _pgmember_id udd_code, _lang_code udd_code, INOUT _result_memprofile refcursor DEFAULT 'rs_memprof'::refcursor, INOUT _result_address refcursor DEFAULT 'rs_address'::refcursor, INOUT _result_bank refcursor DEFAULT 'rs_bank'::refcursor, INOUT _result_land refcursor DEFAULT 'rs_land'::refcursor, INOUT _result_crop refcursor DEFAULT 'rs_crop'::refcursor, INOUT _result_livestock refcursor DEFAULT 'rs_livestock'::refcursor, INOUT _result_assets refcursor DEFAULT 'rs_assets'::refcursor, INOUT _result_membership refcursor DEFAULT 'rs_memebership'::refcursor, INOUT _result_memberattachment refcursor DEFAULT 'rs_memberattachment'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
Declare
	/*
		Created By : Mohan S
		Created Date : 16-12-2021
		
		updated By : Mohan S
		Updated date : 09-08-2022
		
		SP Code : B04PGMG02
	*/
	config_path udd_text := '';
begin
	select  fn_get_configvalue('server_atm_path')
	into 	config_path;
	-- stored procedure body
	-- PROFILE --
	open _result_memprofile for select 	
							pm.pgmember_gid,
							pm.pg_id,
							pg.pg_name,
							pm.pgmember_id,
							pm.pgmember_type_code,
							fn_get_masterdesc('QCD_PGMEMBER_TYPE',pm.pgmember_type_code,_lang_code) as pgmember_type_desc,
							case when _lang_code = 'en_US' then
									pm.pgmember_name
								 when coalesce(pm.pgmember_ll_name,'') = '' then
								 	pm.pgmember_name
							else pm.pgmember_ll_name end as
							pgmember_name,
							pm.pgmember_ll_name,
							case when _lang_code = 'en_US' then 
									pm.fatherhusband_name
								 when coalesce(pm.fatherhusband_ll_name,'') = '' then
								 	pm.fatherhusband_name
							else pm.fatherhusband_ll_name end as
							fatherhusband_name,
							pm.fatherhusband_ll_name,
							pm.pgmember_clas_code,
							fn_get_masterdesc('QCD_PGMEMBER_CLAS',pm.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
							pm.dob_date,
							pm.gender_code,
							fn_get_masterdesc('QCD_GENDER',pm.gender_code,_lang_code) as gender_desc,
							pm.caste_code,
							fn_get_masterdesc('LOKOS_SOCIAL_CAT',pm.caste_code,_lang_code) as caste_desc,
							/*case when pm.mobile_no_active = '' then
									  pm.mobile_no_alternative
							else
									  pm.mobile_no_active
							end as 	  mobile_no_active,*/
							pm.mobile_no_active,
							pm.mobile_no_alternative,
							pm.member_remark as remarks,
							pm.pgmember_photo,
							pm.shg_id,
							pm.shgmember_id,
							pm.sync_status_code,
							pm.dbo_available_flag,
							fn_get_masterdesc('QCD_YES_NO',pm.dbo_available_flag,_lang_code) as dbo_available_flag_desc,
							pm.age,
							pm.age_ason_date,
							pm.status_code,
							fn_get_masterdesc('QCD_STATUS',pm.status_code,_lang_code) as status_desc,
							pm.created_date,
							pm.created_by,
							pm.updated_date,
							pm.updated_by
				  from 		pg_mst_tpgmember as pm
				  inner join pg_mst_tproducergroup as pg on pm.pg_id = pg.pg_id
				  where     pm.pg_id = _pg_id 
				  and       pm.pgmember_id = _pgmember_id
				  and 		pm.pgmember_clas_code = 'PG'
		   		  order by 	pm.pgmember_gid;

	-- ADDRESS --
	open _result_address for select 
							pgmemberaddress_gid,
							pgmember_id,
							addr_type_code,
							fn_get_masterdesc('LOKOS_MEM_ADDRTYPE',addr_type_code,_lang_code) as addr_type_desc,
							addr_line,
							pin_code,
							village_id,
							fn_get_villagedesc(village_id) as village_desc,
							panchayat_id,
							fn_get_panchayatdesc(panchayat_id) as panchayat_desc,
							block_id,
							fn_get_blockdesc(block_id) as block_desc,
							district_id,
							fn_get_districtdesc(district_id) as district_desc,
							state_id,
							fn_get_statedesc(state_id) as state_desc
				  from 		pg_mst_tpgmemberaddress 
				  where pgmember_id = _pgmember_id; 	
				  
	-- BANK --
	open _result_bank for select 
						 pgmemberbank_gid,
						 pgmember_id,
						 bankacc_type_code,
						 fn_get_masterdesc('QCD_MEMBANKACC_TYPE',bankacc_type_code,_lang_code) as bankacc_type_desc,
						 ifsc_code,
						 bank_code,
						 fn_get_masterdesc('QCD_BANK',bank_code,_lang_code) as bank_desc,
						 bank_name,
						 branch_name,
						 bankacc_no
				  from 	 pg_mst_tpgmemberbank
				  where pgmember_id = _pgmember_id;
				  
	-- LAND --
	open _result_land for select
				  				pgmemberland_gid,
								pgmember_id,
								pgmemberland_id,
								land_type_code,
								fn_get_masterdesc('QCD_LAND_TYPE',land_type_code,_lang_code) as land_type_desc,
								ownership_type_code,
								fn_get_masterdesc('QCD_OWNERSHIP_TYPE',ownership_type_code,_lang_code) as ownership_type_desc,
								land_size,
								cropping_area as cultivable_area,
								soil_type_code,
								fn_get_masterdesc('QCD_SOIL_TYPE',soil_type_code,_lang_code) as soil_type_desc,
								irrigation_source_code,
								fn_get_masterdesc('QCD_IRRIGATION_SOURCE',irrigation_source_code,_lang_code) as irrigation_source_desc,
								latitude_value,
								longitude_value
				  	from 		pg_mst_tpgmemberland
				  	where pgmember_id = _pgmember_id;
					
	-- CROP -- 
	open _result_crop for select
							pgmembercrop_gid,
							pgmember_id,
							season_type_code,
							fn_get_masterdesc('QCD_SEASON_TYPE',season_type_code,_lang_code) as season_type_desc,
							crop_type_code,
							fn_get_masterdesc('QCD_SUBCATEGORY',crop_type_code,_lang_code) as crop_type_desc,
							crop_code,
							fn_get_masterdesc('QCD_CROP_TYPE',crop_code,_lang_code) as crop_desc,
							crop_name,
							sowing_area,
							fn_get_landdtl(pgmember_id,pgmemberland_id,_lang_code) as pgmemberland_id
					from 	pg_mst_tpgmembercrop 
					where pgmember_id = _pgmember_id;
					
	-- LIVE STOCK --
	open _result_livestock for select
								   pgmemberlivestock_gid,
								   pgmember_id,
								   livestock_type_code,
								   fn_get_masterdesc('QCD_LIVESTOCK_TYPE',livestock_type_code,_lang_code) as livestock_type_desc,
								   livestock_code,
								   fn_get_masterdesc('QCD_LIVESTOCK',livestock_code,_lang_code) as livestock_desc,
								   ownership_type_code,
								   fn_get_masterdesc('QCD_OWNERSHIP_TYPE',ownership_type_code,_lang_code) as ownership_type_desc,
								   livestock_qty,
								   livestock_remark
					from 	pg_mst_tpgmemberlivestock	   
					where pgmember_id = _pgmember_id;
					
	-- ASSETS --
	open _result_assets for select
								pgmemberasset_gid,
								pgmember_id,
								asset_type_code,
								fn_get_masterdesc('QCD_ASSET_TYPE',asset_type_code,_lang_code) as asset_type_desc,
								asset_code,
								fn_get_masterdesc('QCD_ASSET',asset_code,_lang_code) as asset_desc,
								ownership_type_code,
								fn_get_masterdesc('QCD_OWNERSHIP_TYPE',ownership_type_code,_lang_code) as ownership_type_desc,
								asset_count,
								asset_desc as remarks,
								hirer_mfg_name,
								hirer_mfg_date
					from	    pg_mst_tpgmemberasset
					where pgmember_id = _pgmember_id;
					
	-- MEMBERSHIP --
	open _result_membership for select
							 pgmembership_gid,
							 pgmember_id,
							 membership_type_code,
							 fn_get_masterdesc('QCD_PGMEMBER_TYPE',membership_type_code,_lang_code) as membership_type_desc,
							 membership_amount,
							 effective_from,
							 membership_status_code,
							 fn_get_masterdesc('QCD_STATUS',membership_status_code,_lang_code) as membership_status_desc
				from	pg_mst_tpgmembership
				where pgmember_id = _pgmember_id;
				
	-- MEMBER ATTACHMENT --
	open _result_memberattachment for select 
										 pgmemberattachment_gid,
										 pgmember_id,
										 doc_type_code,
										 fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
										 doc_subtype_code,
										 fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
										 file_name,
										 config_path || file_path as file_path,
										 attachment_remark
							from	pg_mst_tpgmemberattachment
							where pgmember_id = _pgmember_id;
				
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberinvoicestm(_pg_id udd_code, _pgmember_id udd_code, _period_from udd_date, _period_to udd_date, _lang_code udd_code, INOUT _result_memberledger refcursor DEFAULT 'rs_memberledger'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mangai
		Created Date : 09-05-2022
		SP Code : B08MBKR01
	*/
	
	v_amount udd_amount := 0;
	v_dr_amount udd_amount := 0;
	v_cr_amount udd_amount := 0;
begin
	-- opening
	select 	
			   coalesce(sum(dr_amount*-1+cr_amount),0) into v_amount
	from	   pg_trn_tpgmemberledger 
	where 	   pg_id 	 	 = _pg_id
	and 	   pgmember_id	 = _pgmember_id
	and		   tran_date 	 < _period_from
	and 	   status_code 	 = 'A';

	v_amount = coalesce(v_amount,0);
	
	if v_amount >= 0 then
		v_cr_amount = v_amount;
	else 
		v_dr_amount = abs(v_amount);
	end if;	
	-- stored procedure body
	open _result_memberledger for select 
								   a.tran_date as Date,
								   a.tran_narration as Description,
								   fn_get_masterdesc('QCD_PAY_MODE',paymode_code,'en_US') as PayMode,
								   a.dr_amount as Due,
								   a.cr_amount as Paid,
								   sum(coalesce(a.closing_amount - a.dr_amount + a.cr_amount,0) * -1)
								   over (order by a.tran_date,a.pgmemberledger_gid) as balance 
								   
						from
						(
							select 	
									   -1 as pgmemberledger_gid,
									   _period_from::udd_date as tran_date,
									   'Opening' as tran_narration,
									   '' as paymode_code,
									   '' as paymode_desc,
									   v_dr_amount as dr_amount,
									   v_cr_amount as cr_amount,
									   0 as closing_amount
							union all 
							select 	
								pgmemberledger_gid,
								tran_date::udd_date as tran_date,
								tran_narration,
								paymode_code,
								fn_get_masterdesc('QCD_PAY_MODE',paymode_code,'en_US') 
									as paymode_desc,
								dr_amount,
								cr_amount,
								0 as closing_amount 
							from	   pg_trn_tpgmemberledger
							where 	   pg_id 	 	 = _pg_id
							and		   pgmember_id	 = _pgmember_id
							and 	   tran_date 	 >= _period_from
							and 	   tran_date 	 <  _period_to + INTERVAL '1 day'
							and 	   status_code 	 = 'A'
						) as a order by a.tran_date,a.pgmemberledger_gid;
	
	end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberinvoicestm(_pg_id udd_code, _pgmember_id udd_code, _period_from udd_date, _period_to udd_date, _lang_code udd_code, INOUT _result_memberledger refcursor DEFAULT 'rs_memberledger'::refcursor, INOUT _result_openingbalance refcursor DEFAULT 'rs_openingbalance'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By 		: Mohan S
		Created Date 	: 05-05-2022
		SP Code 		: 
	*/
	-- stored procedure body
	-- Member Ledger --
	open _result_memberledger for select 	
							p.tran_date as ""Date"",
							p.tran_narration as Description,
							fn_get_masterdesc('QCD_PAY_MODE',p.paymode_code,_lang_code) as PayMode,
							p.dr_amount as Due,
							p.cr_amount as Paid			
				  from 		pg_trn_tpgmemberledger p				 
				  where 	p.pg_id 		=  _pg_id
				  and       p.pgmember_id 	=  _pgmember_id
				  and 		p.tran_date		>= _period_from
				  and 		p.tran_date		< (_period_to + INTERVAL '1 day')
				  and	    p.status_code	= 'A'
		   		  order by 	pgmemberledger_gid;
				 
	-- Get Opening Balance --
	open _result_openingbalance for select coalesce(sum(cr_amount+(dr_amount*-1.0)),0) as openingbal_amount				
				  from 	pg_trn_tpgmemberledger p				 
				  where p.pg_id 		=  _pg_id
				  and   p.pgmember_id 	=  _pgmember_id
				  and 	p.tran_date		< _period_from 
				  and	p.status_code	= 'A';
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberledger(_pg_id udd_code, _pgmember_id udd_code, _period_from udd_date, _period_to udd_date, _lang_code udd_code, INOUT _result_memberledger refcursor DEFAULT 'rs_memberledger'::refcursor, INOUT _result_openingbalance refcursor DEFAULT 'rs_openingbalance'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By 		: Vijayavel J
		Created Date 	: 09-03-2022
		SP Code 		: 
	*/
	-- stored procedure body
	-- Member Ledger --
	open _result_memberledger for select 	
							p.pgmemberledger_gid,
							p.pg_id,
							p.pgmember_id,							
							p.acchead_code,
							fn_get_masterdesc('QCD_ACC_HEAD_TYPE',p.acchead_code,_lang_code) as acchead_desc,
							p.tran_date,
							p.dr_amount,
							p.cr_amount,
							p.tran_narration,
							p.tran_ref_no,
							p.paid_date,
							p.paymode_code,
							fn_get_masterdesc('QCD_PAY_MODE',p.paymode_code,_lang_code) as paymode_desc,
							p.tran_remark,														
							p.status_code,
							fn_get_masterdesc('QCD_STATUS',p.status_code,_lang_code) as status_desc,
							p.created_date,
							p.created_by,
							p.updated_date,
							p.updated_by							
				  from 		pg_trn_tpgmemberledger p				 
				  where 	p.pg_id 		=  _pg_id
				  and       p.pgmember_id 	=  _pgmember_id
				  and 		p.tran_date		>= _period_from
				  and 		p.tran_date		< (_period_to + INTERVAL '1 day')
				  and	    p.status_code	= 'A'
		   		  order by 	pgmemberledger_gid;
				 
	-- Get Opening Balance --
	open _result_openingbalance for select coalesce(sum(cr_amount+(dr_amount*-1.0)),0) as openingbal_amount				
				  from 	pg_trn_tpgmemberledger p				 
				  where p.pg_id 		=  _pg_id
				  and   p.pgmember_id 	=  _pgmember_id
				  and 	p.tran_date		< _period_from 
				  and	p.status_code	= 'A';
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberledgerdtl(_pg_id udd_code, _pgmember_id udd_code, _lang_code udd_code, INOUT _result_memberledger refcursor DEFAULT 'rs_memberledger'::refcursor, INOUT _result_memberpayment refcursor DEFAULT 'rs_memberpayment'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 31-12-2021
		SP Code : B07MLDG01
	*/
	-- stored procedure body
	-- Member Ledger --
	open _result_memberledger for select 	
							p.pgmemberledger_gid,
							p.pg_id,
							p.pgmember_id,							
							p.acchead_code,
							fn_get_masterdesc('QCD_PROD_TYPE',p.acchead_code,_lang_code) as acchead_desc,
							p.tran_date,
							p.dr_amount,
							p.cr_amount,
							p.tran_narration,
							p.tran_ref_no,
							p.tran_remark,														
							p.status_code,
							fn_get_masterdesc('QCD_STATUS',p.status_code,_lang_code) as status_desc,
							p.created_date,
							p.created_by,
							p.updated_date,
							p.updated_by							
				  from 		pg_trn_tpgmemberledger p				 
				  where 	p.pg_id 		= _pg_id
				  and       p.pgmember_id 	= _pgmember_id
		   		  order by 	pgmemberledger_gid;
				 
	-- Member Payment --
	open _result_memberpayment for select 
							p.pgmemberpymt_gid,
							p.pg_id,
							p.pgmember_id,
							p.paid_date,
							p.period_from,
							p.period_to,
							p.paymode_code,
							fn_get_masterdesc('QCD_PROD_TYPE',p.paymode_code,_lang_code) as paymode_desc,
							p.paid_amount,
							p.pymt_ref_no,
							p.pymt_remark,
							p.status_code,
							fn_get_masterdesc('QCD_STATUS',p.status_code,_lang_code) as status_desc,
							p.created_date,
							p.created_by,
							p.updated_date,
							p.updated_by								
				  from 		pg_trn_tpgmemberpayment p				 
				  where 	p.pg_id 		= _pg_id
				  and       p.pgmember_id 	= _pgmember_id
		   		  order by 	pgmemberpymt_gid;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberledgersummlist(_lang_code udd_code, _user_code udd_code, INOUT _result_memberledgersumm refcursor DEFAULT 'rs_memberledgersummlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 31-12-2021
		SP Code : B07MLSG01
	*/
	-- stored procedure body
	open _result_memberledgersumm for select 	
									pgmemberledger_gid as pgmemberledgersumm_gid,
									pg_id,
									pgmember_id,
									dr_amount,
									cr_amount,
									tran_date as as_of_date,							
									status_code,
									fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
									created_date,
									created_by,
									updated_date,
									updated_by
							
							  from 		pg_trn_tpgmemberledger
							  order by 	status_code,pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberlist(_pg_id udd_code, _user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_pgmem refcursor DEFAULT 'rs_pgmemlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
Declare 
	/*
		Created By : Mohan S
		Created Date : 16-12-2021
				
		Updated By : Mohan S
		Updated Date : 09-08-2022
		
		SP Code : B04PGMG01
	*/
	
	v_block_id udd_int = 0;
-- 	v_menu_code udd_code = 'PGC004';
-- 	v_err_code udd_code = 'VB00CMNCMN_021';
-- 	v_err_msg udd_desc = '';
-- 	v_authorization udd_boolean = false;
begin

	select fn_get_blockid(_block_code)::udd_int into v_block_id;
-- 	select fn_get_authorization(_role_code,v_menu_code,_user_code) into v_authorization;

	-- stored procedure body
-- 	if v_authorization then
			open _result_pgmem for select 
									pgmem.pg_id,
									pgmem.pgmember_id,
									case when _lang_code = 'en_US' then
											progro.pg_name
										 when coalesce(progro.pg_ll_name,'') = '' then
											progro.pg_name
									else progro.pg_ll_name end as
									pg_name,
									progro.pg_ll_name,
									pgmem.pgmember_type_code,
									fn_get_masterdesc('QCD_PGMEMBER_TYPE',pgmem.pgmember_type_code,_lang_code) as pgmember_type_desc,
									case when _lang_code = 'en_US' then
											pgmem.pgmember_name
										 when coalesce(pgmem.pgmember_ll_name,'') = '' then
											pgmem.pgmember_name
									else pgmem.pgmember_ll_name end as
									pgmember_name,
									pgmem.pgmember_ll_name,
									case when _lang_code = 'en_US' then 
											pgmem.fatherhusband_name
										 when coalesce(pgmem.fatherhusband_ll_name,'') = '' then
											pgmem.fatherhusband_name
									else pgmem.fatherhusband_ll_name end as
									fatherhusband_name,
									pgmem.fatherhusband_ll_name,
									pgmem.pgmember_clas_code,
									fn_get_masterdesc('QCD_PGMEMBER_CLAS',pgmem.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
									pgmem.dob_date,
									pgmem.age_ason_date, 
									case when pgmem.age <> 0 then
										concat(pgmem.age,'-','(', to_char(age_ason_date::udd_date, 'DD-MM-YYYY'),')') 
									else 
										''
									end
									as age_ason_date_concat ,
									pmaddr.addr_line,
									fn_get_villagedesc(pmaddr.village_id) as village_desc,
									fn_get_panchayatdesc(pmaddr.panchayat_id) as panchayat_desc,
									fn_get_blockdesc(pmaddr.block_id) as block_desc,
									fn_get_districtdesc(pmaddr.district_id) as district_desc,
									concat(fn_get_villagedesc(pmaddr.village_id),'-',
										  fn_get_blockdesc(pmaddr.block_id),'-',
										  fn_get_districtdesc(pmaddr.district_id)) as vill_blk_dist,
									pgmem.gender_code,
									fn_get_masterdesc('QCD_GENDER',pgmem.gender_code,_lang_code) as gender_desc,
									pgmem.caste_code,
									concat(	pmaddr.addr_line,'<br>',fn_get_villagedesc(pmaddr.village_id),
													'<br>',concat(fn_get_panchayatdesc(pmaddr.panchayat_id),
													', ',fn_get_blockdesc(pmaddr.block_id),
													', ',fn_get_districtdesc(pmaddr.district_id))) as ""registered_address"",
									fn_get_masterdesc('LOKOS_SOCIAL_CAT',pgmem.caste_code,_lang_code) as caste_desc,
									/*case when pgmem.mobile_no_active = '' then
											  pgmem.mobile_no_alternative
									else
											  pgmem.mobile_no_active
									end as 	  mobile_no_active,*/
									pgmem.mobile_no_active,
									pgmem.mobile_no_alternative,
									pgmem.member_remark,
									pgmem.shg_id,
									fn_get_shgcodename(pgmem.shg_id) as shgcode_name,
									pgmem.shgmember_id,
									pgmem.sync_status_code,
									pgmem.status_code,
									fn_get_masterdesc('QCD_STATUS',pgmem.status_code,_lang_code) as status_desc
						  from 		pg_mst_tpgmember as pgmem
						  inner join pg_mst_tproducergroup as progro 
						  on 		 pgmem.pg_id = progro.pg_id
						  and        progro.pg_id in (select fn_get_pgid(_block_code, _role_code, _user_code))
						  left join pg_mst_tpgmemberaddress as pmaddr on pgmem.pgmember_id = pmaddr.pgmember_id
						  and 		addr_type_code = '1' -- Retrives ""Primary"" Address type only
						  where 	pgmem.pg_id = _pg_id
						  and 		pgmem.pgmember_clas_code = 'PG'
						  order by 	pgmem.pgmember_gid;
-- 		else 
-- 			select fn_get_msg('VB00CMNCMN_021',_lang_code) into v_err_msg;
-- 			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
-- 	 end if;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmembernamelist(_pg_id udd_code, _lang_code udd_code, INOUT _result_pgmemname refcursor DEFAULT 'rs_pgmemname'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 16-02-2022
		
		Updated By : Mohan S
		Updated Date : 16-08-2022
		
		SP Code : B04PGMG03
	*/
begin
	-- stored procedure body
	open _result_pgmemname for select 	
									 pgmember_gid,
									 pgmember_id,
									 pgmember_name,
									 fn_get_masterdesc('QCD_DESIGNATION',designation_code,_lang_code) as designation_desc,
									 designation_code,
									 fn_get_masterdesc('QCD_SIGNATORY',signatory_code,_lang_code) as signatory_desc,
									 signatory_code,
									 case when mobile_no_active = '' then
									  			mobile_no_alternative
									 else
									  			mobile_no_active
									 end as 	mobile_no_active
						  from 		 pg_mst_tpgmember
						  where 	 pg_id = _pg_id
-- 						  and 		 officebearer_flag = 'Y'
						  and 		 pgmember_clas_code = 'PG'
						  and 		 status_code = 'A';
						  
						  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberpayablelist(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _lang_code udd_code, INOUT _result_pgmemberpayablelist refcursor DEFAULT 'rs_get_pgmemberpayablelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By 	 : Vijayavel
		Created Date : 09-03-2022
		SP Code 	 : 
	*/
	
	-- stored procedure body
	open _result_pgmemberpayablelist for select 	
				s.pgmemberledgersumm_gid,
				s.pg_id,
				s.pgmember_id,
				pm.pgmember_name,
				s.dr_amount,
				s.cr_amount,
				(s.dr_amount-s.cr_amount) as due_amount,
				s.as_of_date,							
				s.status_code,
				fn_get_pgmembervillage(s.pg_id,s.pgmember_id,_lang_code) as village_name,
				s.created_date,
				s.created_by,
				s.updated_date,
				s.updated_by
	from 		pg_mst_tpgmember as pm 
	inner join 	pg_trn_tpgmemberledgersumm as s 
	on			s.pg_id 		= pm.pg_id
	and			s.pgmember_id 	= pm.pgmember_id
	and 		s.status_code 	= 'A'
	where 		pm.pg_id		= _pg_id
	-- and 		(s.dr_amount - s.cr_amount) > 0 
	and 		pm.status_code	= 'A'
	order by 	status_code,pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberreport(_pg_id udd_code, _pgmember_id udd_code, _lang_code udd_code, INOUT _result_pgmemberprofile refcursor DEFAULT 'rs_pgmemprof'::refcursor, INOUT _result_pgmemberaddress refcursor DEFAULT 'rs_pgmemaddr'::refcursor, INOUT _result_pgmemberbank refcursor DEFAULT 'rs_pgmembank'::refcursor, INOUT _result_pgmemberland refcursor DEFAULT 'rs_pgmemland'::refcursor, INOUT _result_pgmembercrop refcursor DEFAULT 'rs_pgmemcrop'::refcursor, INOUT _result_pgmemberlivestock refcursor DEFAULT 'rs_pgmemlivestock'::refcursor, INOUT _result_pgmemberasset refcursor DEFAULT 'rs_pgmemasset'::refcursor, INOUT _result_pgmembership refcursor DEFAULT 'rs_pgmemship'::refcursor, INOUT _result_pgmemberattachment refcursor DEFAULT 'rs_pgmemattach'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
/*
	Created By : Mohan S
	Created Date : 16-12-2021
	
	Updated By : Mohan S
	Updated Date : 09-08-2022
	
	SP Code : B08PGMR01
*/
begin
	-- stored procedure body
	-- PG MEMBER PROFILE
	open _result_pgmemberprofile for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('QCD_PGMEMBER_TYPE',pgmember_type_code,_lang_code) as pgmember_type_desc,
								 pgmember_name,
								 pgmember_ll_name,
								 fatherhusband_name,
								 fatherhusband_ll_name,
								 dob_date,
								 fn_get_masterdesc('QCD_GENDER',gender_code,_lang_code) gender_desc,
								 fn_get_masterdesc('QCD_CASTE',caste_code,_lang_code) caste_desc,
								 mobile_no_active,
								 mobile_no_alternative,
								 member_remark,
								 shg_id,
								 shgmember_id,
								 fn_get_masterdesc('QCD_SYNC_STATUS',sync_status_code,_lang_code) as sync_status_desc,
								 '' as pgmember_photo,
								 fn_get_masterdesc('QCD_YES_NO',dbo_available_flag,_lang_code) as dbo_available_flag,
								 age,
								 age_ason_date,
								 fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
								 pgmember_inactive_code
				  from 			 pg_mst_tpgmember 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id
				  and 			 pgmember_clas_code = 'PG';
				  
				  
	-- PG MEMBER ADDRESS	
	open _result_pgmemberaddress for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('LOKOS_MEM_ADDRTYPE',addr_type_code,_lang_code) as addr_type_desc,
								 addr_line,
								 pin_code,
								 fn_get_villagedesc(village_id) as village_desc,
								 fn_get_panchayatdesc(panchayat_id) as panchayat_desc,
								 fn_get_blockdesc(block_id) as block_desc,
								 fn_get_districtdesc(district_id) as district_desc,
								 fn_get_statedesc(state_id) as state_desc
				  from 			 pg_mst_tpgmemberaddress_view
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
				  
	-- PG MEMBER BANK	
	open _result_pgmemberbank for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('QCD_MEMBANKACC_TYPE',bankacc_type_code,_lang_code) as bankacc_type_desc,
								 ifsc_code,
								 bank_code,
								 bank_name,
								 branch_name,
								 bankacc_no,
								 fn_get_masterdesc('QCD_YES_NO',primary_flag,_lang_code) as primary_flag
				  from 			 pg_mst_tpgmemberbank_view 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
				  
	-- PG MEMBER LAND	
	open _result_pgmemberland for select 	
								 pg_id,
								 pgmember_id,
								 pgmemberland_id,
								 fn_get_masterdesc('QCD_LAND_TYPE',land_type_code,_lang_code) as land_type_desc,
								 fn_get_masterdesc('QCD_OWNERSHIP_TYPE',ownership_type_code,_lang_code) as ownership_type_desc,
								 land_size,
								 cropping_area,
								 fn_get_masterdesc('QCD_SOIL_TYPE',soil_type_code,_lang_code) as soil_type_desc,
								 fn_get_masterdesc('QCD_IRRIGATION_SOURCE',irrigation_source_code,_lang_code) as irrigation_source_desc,
								 latitude_value,
								 longitude_value
				  from 			 pg_mst_tpgmemberland_view 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
	
	-- PG MEMBER CROP	
	open _result_pgmembercrop for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('QCD_SEASON_TYPE',season_type_code,_lang_code) as season_type_desc,
								 fn_get_masterdesc('QCD_CROPTYPE',crop_type_code,_lang_code) as crop_type_desc,
				  				 crop_code,
								 crop_name,
								 sowing_area,
								 pgmemberland_id
				  from 			 pg_mst_tpgmembercrop_view 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
				  
	-- PG MEMBER LIVESTOCK	
	open _result_pgmemberlivestock for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('QCD_LIVESTOCK_TYPE',livestock_type_code,_lang_code) as livestock_type_desc,
								 fn_get_masterdesc('QCD_LIVESTOCK',livestock_code,_lang_code) as livestock_desc,
								 fn_get_masterdesc('QCD_OWNERSHIP_TYPE',ownership_type_code,_lang_code) as ownership_type_desc,
								 livestock_qty,
								 livestock_remark
				  from 			 pg_mst_tpgmemberlivestock_view 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
				  
	-- PG MEMBER ASSET	
	open _result_pgmemberasset for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('QCD_ASSET_TYPE',asset_type_code,_lang_code) as asset_type_desc,
								 fn_get_masterdesc('QCD_ASSET',asset_code,_lang_code) as asset_desc,
								 fn_get_masterdesc('QCD_OWNERSHIP_TYPE',ownership_type_code,_lang_code) as ownership_type_desc,
								 asset_count,
								 asset_desc,
								 hirer_mfg_name,
								 hirer_mfg_date
				  from 			 pg_mst_tpgmemberasset_view 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
				  
	-- PG MEMBERSHIP	
	open _result_pgmembership for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('QCD_MEMBERSHIP_TYPE',membership_type_code,_lang_code) as membership_type_desc,
								 membership_amount,
								 effective_from,
								 membership_status_code
				  from 			 pg_mst_tpgmembership_view 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
				  
	-- PG MEMBER ATTACHMENT	
	open _result_pgmemberattachment for select 	
								 pg_id,
								 pgmember_id,
								 fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
								 fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
								 file_name,
								 attachment_remark
				  from 			 pg_mst_tpgmemberattachment_view 
				  where 		 pg_id = _pg_id
				  and 			 pgmember_id = _pgmember_id;
									
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgmemberstatement(_pgmember_id udd_code, _from_date udd_datetime, _to_date udd_datetime, _lang_code udd_code, INOUT _result_pgmemberdtl refcursor DEFAULT 'rs_pgmemberdtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 28-02-2022
		SP Code : B04PMLG01
	*/
begin
	-- stored procedure body
	open _result_pgmemberdtl for select
							   		tran_date,
									tran_narration,
									fn_get_masterdesc('QCD_PAY_MODE',paymode_code,_lang_code) as paymode_desc,
									paymode_code as paymode,
									dr_amount as due_amount,
									cr_amount as paid_amount,
									0 as bal_amount
					from			pg_trn_tpgmemberledger 
					where 			tran_date >= _from_date 
					and 			tran_date <= _to_date
					and   			pgmember_id = _pgmember_id 
					and 			status_code = 'A';
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgnamelist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_pgname refcursor DEFAULT 'rs_pgnamelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan
		Created Date : 30-12-2021
		SP Code : B04PGLG02
	*/
	
	v_block_id udd_int = 0;
	
begin
	-- stored procedure body
	-- PG NAME LIST
	
-- 	select fn_get_blockid(_block_code)::udd_int into v_block_id;
	
	open _result_pgname for select 	
							pg_id,
							pg_name,
							concat(pg_id,'-',pg_name) as pg_id_name
				  from 		pg_mst_tproducergroup 
				  where 	pg_id in (select fn_get_pgid(_block_code, _role_code, _user_code))
				  and       status_code in ('A','M')
		   		  order by 	pg_name;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgnonmemberdtl(_pg_id udd_code, _pgmember_id udd_code, _lang_code udd_code, INOUT _result_memprofile refcursor DEFAULT 'rs_memprof'::refcursor, INOUT _result_address refcursor DEFAULT 'rs_address'::refcursor, INOUT _result_bank refcursor DEFAULT 'rs_bank'::refcursor, INOUT _result_memberattachment refcursor DEFAULT 'rs_memberattachment'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
Declare
	/*
		Created By : Mohan S
		Created Date : 16-08-2022
	*/
	config_path udd_text := '';
begin
	select  fn_get_configvalue('server_atm_path')
	into 	config_path;
	-- stored procedure body
	-- PROFILE --
	open _result_memprofile for select 	
							pm.pgmember_gid,
							pm.pg_id,
							pg.pg_name,
							pm.pgmember_id,
							pm.pgmember_type_code,
							fn_get_masterdesc('QCD_PGMEMBER_TYPE',pm.pgmember_type_code,_lang_code) as pgmember_type_desc,
							case when _lang_code = 'en_US' then
									pm.pgmember_name
								 when coalesce(pm.pgmember_ll_name,'') = '' then
								 	pm.pgmember_name
							else pm.pgmember_ll_name end as
							pgmember_name,
							pm.pgmember_ll_name,
							case when _lang_code = 'en_US' then 
									pm.fatherhusband_name
								 when coalesce(pm.fatherhusband_ll_name,'') = '' then
								 	pm.fatherhusband_name
							else pm.fatherhusband_ll_name end as
							fatherhusband_name,
							pm.fatherhusband_ll_name,
							pm.pgmember_clas_code,
							fn_get_masterdesc('QCD_PGMEMBER_CLAS',pm.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
							pm.dob_date,
							pm.gender_code,
							fn_get_masterdesc('QCD_GENDER',pm.gender_code,_lang_code) as gender_desc,
							pm.caste_code,
							fn_get_masterdesc('LOKOS_SOCIAL_CAT',pm.caste_code,_lang_code) as caste_desc,
							case when pm.mobile_no_active = '' then
									  pm.mobile_no_alternative
							else
									  pm.mobile_no_active
							end as 	  mobile_no_active,
							pm.mobile_no_alternative,
							pm.member_remark as remarks,
							pm.pgmember_photo,
							pm.shg_id,
							pm.shgmember_id,
							pm.sync_status_code,
							pm.dbo_available_flag,
							fn_get_masterdesc('QCD_YES_NO',pm.dbo_available_flag,_lang_code) as dbo_available_flag_desc,
							pm.age,
							pm.age_ason_date,
							pm.status_code,
							fn_get_masterdesc('QCD_STATUS',pm.status_code,_lang_code) as status_desc,
							pm.created_date,
							pm.created_by,
							pm.updated_date,
							pm.updated_by
				  from 		pg_mst_tpgmember as pm
				  inner join pg_mst_tproducergroup as pg on pm.pg_id = pg.pg_id
				  where     pm.pg_id = _pg_id 
				  and       pm.pgmember_id = _pgmember_id
				  and 		pm.pgmember_clas_code = 'NONPG_OTHERS'
		   		  order by 	pm.pgmember_gid;

	-- ADDRESS --
	open _result_address for select 
							pgmemberaddress_gid,
							pgmember_id,
							addr_type_code,
							fn_get_masterdesc('LOKOS_MEM_ADDRTYPE',addr_type_code,_lang_code) as addr_type_desc,
							addr_line,
							pin_code,
							village_id,
							fn_get_villagedesc(village_id) as village_desc,
							panchayat_id,
							fn_get_panchayatdesc(panchayat_id) as panchayat_desc,
							block_id,
							fn_get_blockdesc(block_id) as block_desc,
							district_id,
							fn_get_districtdesc(district_id) as district_desc,
							state_id,
							fn_get_statedesc(state_id) as state_desc
				  from 		pg_mst_tpgmemberaddress 
				  where pgmember_id = _pgmember_id; 	
				  
	-- BANK --
	open _result_bank for select 
						 pgmemberbank_gid,
						 pgmember_id,
						 bankacc_type_code,
						 fn_get_masterdesc('QCD_MEMBANKACC_TYPE',bankacc_type_code,_lang_code) as bankacc_type_desc,
						 ifsc_code,
						 bank_code,
						 fn_get_masterdesc('QCD_BANK',bank_code,_lang_code) as bank_desc,
						 bank_name,
						 branch_name,
						 bankacc_no
				  from 	 pg_mst_tpgmemberbank
				  where pgmember_id = _pgmember_id;

	-- NON PGMEMBER ATTACHMENT --
	open _result_memberattachment for select 
										 pgmemberattachment_gid,
										 pgmember_id,
										 doc_type_code,
										 fn_get_masterdesc('QCD_DOC_TYPE',doc_type_code,_lang_code) as doc_type_desc,
										 doc_subtype_code,
										 fn_get_masterdesc('QCD_DOC_SUBTYPE',doc_subtype_code,_lang_code) as doc_subtype_desc,
										 file_name,
										 config_path || file_path as file_path,
										 attachment_remark
							from	pg_mst_tpgmemberattachment
							where pgmember_id = _pgmember_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgnonmemberlist(_pg_id udd_code, _user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_pgmem refcursor DEFAULT 'rs_pgnonmemlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
Declare 
	/*
		Created By : Mohan S
		Created Date : 12-08-2021
		SP Code : B04PGMG01
	*/
	
	v_block_id udd_int = 0;
begin

	select fn_get_blockid(_block_code)::udd_int into v_block_id;
	-- stored procedure body
			open _result_pgmem for select 
									pgmem.pg_id,
									pgmem.pgmember_id,
									case when _lang_code = 'en_US' then
											progro.pg_name
										 when coalesce(progro.pg_ll_name,'') = '' then
											progro.pg_name
									else progro.pg_ll_name end as
									pg_name,
									progro.pg_ll_name,
									pgmem.pgmember_type_code,
									fn_get_masterdesc('QCD_PGMEMBER_TYPE',pgmem.pgmember_type_code,_lang_code) as pgmember_type_desc,
									case when _lang_code = 'en_US' then
											pgmem.pgmember_name
										 when coalesce(pgmem.pgmember_ll_name,'') = '' then
											pgmem.pgmember_name
									else pgmem.pgmember_ll_name end as
									pgmember_name,
									pgmem.pgmember_ll_name,
									case when _lang_code = 'en_US' then 
											pgmem.fatherhusband_name
										 when coalesce(pgmem.fatherhusband_ll_name,'') = '' then
											pgmem.fatherhusband_name
									else pgmem.fatherhusband_ll_name end as
									fatherhusband_name,
									pgmem.fatherhusband_ll_name,
									pgmem.pgmember_clas_code,
									fn_get_masterdesc('QCD_PGMEMBER_CLAS',pgmem.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
									pgmem.dob_date,
									pgmem.age_ason_date, 
									case when pgmem.age <> 0 then
										concat(pgmem.age,'-','(', to_char(age_ason_date::udd_date, 'DD-MM-YYYY'),')') 
									else 
										''
									end
									as age_ason_date_concat ,
									pmaddr.addr_line,
									fn_get_villagedesc(pmaddr.village_id) as village_desc,
									fn_get_panchayatdesc(pmaddr.panchayat_id) as panchayat_desc,
									fn_get_blockdesc(pmaddr.block_id) as block_desc,
									fn_get_districtdesc(pmaddr.district_id) as district_desc,
									concat(fn_get_villagedesc(pmaddr.village_id),'-',
										  fn_get_blockdesc(pmaddr.block_id),'-',
										  fn_get_districtdesc(pmaddr.district_id)) as vill_blk_dist,
									pgmem.gender_code,
									fn_get_masterdesc('QCD_GENDER',pgmem.gender_code,_lang_code) as gender_desc,
									pgmem.caste_code,
									concat(	pmaddr.addr_line,'<br>',fn_get_villagedesc(pmaddr.village_id),
													'<br>',concat(fn_get_panchayatdesc(pmaddr.panchayat_id),
													', ',fn_get_blockdesc(pmaddr.block_id),
													', ',fn_get_districtdesc(pmaddr.district_id))) as ""registered_address"",
									fn_get_masterdesc('LOKOS_SOCIAL_CAT',pgmem.caste_code,_lang_code) as caste_desc,
									case when pgmem.mobile_no_active = '' then
											  pgmem.mobile_no_alternative
									else
											  pgmem.mobile_no_active
									end as 	  mobile_no_active,
									pgmem.mobile_no_alternative,
									pgmem.member_remark,
									pgmem.shg_id,
									fn_get_shgcodename(pgmem.shg_id) as shgcode_name,
									pgmem.shgmember_id,
									pgmem.sync_status_code,
									pgmem.status_code,
									fn_get_masterdesc('QCD_STATUS',pgmem.status_code,_lang_code) as status_desc
						  from 		pg_mst_tpgmember as pgmem
						  inner join pg_mst_tproducergroup as progro 
						  on 		 pgmem.pg_id = progro.pg_id
						  and        progro.pg_id in (select fn_get_pgid(_block_code, _role_code, _user_code))
						  left join pg_mst_tpgmemberaddress as pmaddr on pgmem.pgmember_id = pmaddr.pgmember_id
						  and 		addr_type_code = '1' -- Retrives ""Primary"" Address type only
						  where 	pgmem.pg_id = _pg_id
						  and 		pgmem.pgmember_clas_code = 'NONPG_OTHERS'
						  order by 	pgmem.pgmember_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgnonmembernamelist(_pg_id udd_code, _pgmember_clas_code udd_code, _lang_code udd_code, INOUT _result_pgnonmemname refcursor DEFAULT 'rs_pgnonmemname'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 16-02-2022
		
		Updated By : Mohan S
		Updated Date : 16-08-2022
		
		SP Code : B04PGMG03
	*/
begin
	-- stored procedure body
	open _result_pgnonmemname for select 	
									 pgmember_gid,
									 pgmember_id,
									 pgmember_name,
									 fn_get_masterdesc('QCD_DESIGNATION',designation_code,_lang_code) as designation_desc,
									 designation_code,
									 fn_get_masterdesc('QCD_SIGNATORY',signatory_code,_lang_code) as signatory_desc,
									 signatory_code,
									 case when mobile_no_active = '' then
									  			mobile_no_alternative
									 else
									  			mobile_no_active
									 end as 	mobile_no_active
						  from 		 pg_mst_tpgmember
						  where 	 pg_id = _pg_id
-- 						  and 		 officebearer_flag = 'Y'
						  and 		 pgmember_clas_code = _pgmember_clas_code
						  and 		 status_code = 'A';
						  
						  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgofficebearernamelist(_pg_id udd_code, _lang_code udd_code, INOUT _result_pgoffbearername refcursor DEFAULT 'rs_pgoffbearername'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 08-09-2022
		SP Code : B04OFFG01
	*/
begin
	-- stored procedure body
	open _result_pgoffbearername for select 	
									 pgmember_gid,
									 pgmember_id,
									 pgmember_name,
									 fn_get_masterdesc('QCD_DESIGNATION',designation_code,_lang_code) as designation_desc,
									 designation_code,
									 fn_get_masterdesc('QCD_SIGNATORY',signatory_code,_lang_code) as signatory_desc,
									 signatory_code,
									 case when mobile_no_active = '' then
									  			mobile_no_alternative
									 else
									  			mobile_no_active
									 end as 	mobile_no_active
						  from 		 pg_mst_tpgmember
						  where 	 pg_id = _pg_id
						  and 		 officebearer_flag = 'Y'
-- 						  and 		 pgmember_clas_code = 'PG'
						  and 		 status_code = 'A';
						  
						  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgreport(_pg_id udd_code, _user_code udd_user, _role_code udd_code, _block_code udd_code, _lang_code udd_code, INOUT _result_pgprofile refcursor DEFAULT 'rs_pgprofile'::refcursor, INOUT _result_pgaddress refcursor DEFAULT 'rs_pgaddress'::refcursor, INOUT _result_pgbank refcursor DEFAULT 'rs_pgbank'::refcursor, INOUT _result_pgpanchayatmap refcursor DEFAULT 'rs_pggpmapping'::refcursor, INOUT _result_pgactivites refcursor DEFAULT 'rs_pgactivities'::refcursor, INOUT _result_pgproduct refcursor DEFAULT 'rs_pgproduct'::refcursor, INOUT _result_pgofficebearers refcursor DEFAULT 'rs_pgofficebearers'::refcursor, INOUT _result_pgmemprof refcursor DEFAULT 'rs_pgmemprof'::refcursor, INOUT _result_pgnonmemprof refcursor DEFAULT 'rs_pgnonmemprof'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 28-01-2022
		
		Updated By : Mohan S
		Updated Date : 16-08-2022
		
		SP Code : B08PGDR01
	*/
begin
	-- stored procedure body
	open _result_pgprofile for select 	
									pg.pg_id,
									pg.pg_name,
									to_char(pg.formation_date::udd_date, 'DD-MM-YYYY') as formation_date,
									fn_get_villagecount_pgid(_pg_id) as village_count,
									fn_get_membercount_pgid(_pg_id) as member_count,
									um.udyogmitra_name as udyogmitra_name,
									concat(	addr.addr_line,'<br>',fn_get_villagedesc(addr.village_id),
										  	'<br>',concat(fn_get_panchayatdesc(addr.panchayat_id),
								   			', ',fn_get_blockdesc(addr.block_id),
								   			', ',fn_get_districtdesc(addr.district_id))) as ""registered_address""
				  from 		pg_mst_tproducergroup as pg
				  inner join pg_mst_taddress as addr
				  on	 	 pg.pg_id = addr.pg_id
				  and 		 addr.addr_type_code = 'QCD_ADDRTYPE_REG'
				  left join  pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 		 um.tran_status_code <> 'I'
				  where 	 pg.pg_id = _pg_id
				  and 		 pg.status_code <> 'I'
		   		  order by 	 pg.pg_name ;
	
	-- ADDRESS --
	open _result_pgaddress for select 
							addr_type_code,
							fn_get_masterdesc('QCD_ADDR_TYPE',addr_type_code,_lang_code) as addr_type_desc,
							addr_line,
							fn_get_villagedesc(village_id) as village_desc,
							concat(fn_get_panchayatdesc(panchayat_id),
								   ', ',fn_get_blockdesc(block_id),
								   ', ',fn_get_districtdesc(district_id)) as gp_blk_dist,
							fn_get_statedesc(state_id) as state_desc
				  from 		pg_mst_taddress 
				  where 	pg_id = _pg_id
				  and 		addr_type_code = 'QCD_ADDRTYPE_REG'; 
				  
	-- BANK --
	open _result_pgbank for select 
						 fn_get_masterdesc('QCD_BANKACC_TYPE',bankacc_type_code,_lang_code) as bankacc_type_desc,
						 bankacc_no,
						 bank_name,
						 branch_name,
						 ifsc_code
				  from 	 pg_mst_tbank
				  where  pg_id = _pg_id;
				  
	-- PANCHAYAT -- 
	open _result_pgpanchayatmap for select 
							fn_get_statedesc(state_id) as state_desc,
							fn_get_districtdesc(district_id) as district_desc,
							fn_get_panchayatdesc(panchayat_id) as panchayat_desc,
							fn_get_blockdesc(block_id) as block_desc
				  from 		pg_mst_tpanchayatmapping 
				  where 	pg_id = _pg_id;
				  
	-- ACTIVITIES --
	open _result_pgactivites for select
								seq_no,
								fn_get_masterdesc('QCD_ACTIVITY',activity_code,_lang_code) as activity_desc
					from	    pg_mst_tactivity
					where 		pg_id = _pg_id;
					
	-- PRODUCT --  
	open _result_pgproduct for select
							promap.prod_code as prod_code,
							protran.prod_desc as prod_desc,
							fn_get_masterdesc('QCD_PROD_TYPE',pro.prod_type_code,_lang_code) as prod_type_desc,
							-- CR NO : CR0001 / Resource - Emp10138 / 23-jan-2023 / CS-002
-- 							promap.stock_reset_flag as stock_reset_flag,
-- 							fn_get_masterdesc('QCD_YES_NO',promap.stock_reset_flag,_lang_code) as stock_reset_flag_desc,
							case 
								when stock_reset_flag = 'Y' then 
									'N' 
								else 'Y' 
							end as stock_reset_flag,
							case 
								when promap.stock_reset_flag = 'Y' then
									fn_get_masterdesc('QCD_YES_NO','N',_lang_code) 
								else 
									fn_get_masterdesc('QCD_YES_NO','Y',_lang_code) 
							end as stock_reset_flag_desc,
							-- CR NO : CR0001 / Resource - Emp10138 / 23-jan-2023 / CE-002
							fn_get_masterdesc('QCD_CATEGORY',pro.category_code,_lang_code) as category_desc,
							fn_get_masterdesc('QCD_SUBCATEGORY',pro.subcategory_code,_lang_code) as subcategory_desc,
							promap.frequent_flag as frequent_flag
					from 	pg_mst_tproductmapping as promap
					inner join core_mst_tproduct as pro on promap.prod_code = pro.prod_code
					inner join core_mst_tproducttranslate as protran on pro.prod_code = protran.prod_code
					where 	promap.pg_id = _pg_id and protran.lang_code = _lang_code ;		
					
	-- OFFICE BEARERS --
	open _result_pgofficebearers for select
								   offbearer_name,
								   fn_get_masterdesc('QCD_DESIGNATION',designation_code,_lang_code) as designation_desc,
								   fn_get_masterdesc('QCD_SIGNATORY',signatory_code,_lang_code) as signatory_desc,
								   mobile_no
					from 		   pg_mst_tofficebearers
					where 		   pg_id = _pg_id;
					
	-- PG MEMBER DETAILS
	open _result_pgmemprof for select 
								 pgmem.pgmember_id,
							     pgmem.pgmember_name,
							     fn_get_masterdesc('QCD_PGMEMBER_TYPE',pgmem.pgmember_type_code,_lang_code) as membertype,
								 concat(shg.shg_code,'&',shg.shg_name)  as shgcode_name,
							     fn_get_masterdesc('QCD_GENDER',pgmem.gender_code,_lang_code) as gender,
								 pgmem.pgmember_clas_code,
								 fn_get_masterdesc('QCD_PGMEMBER_CLAS',pgmem.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
								 pgmem.mobile_no_active,
								 pgmem.mobile_no_alternative,
								 pgmem.dob_date,
								 pgmem.age_ason_date,
								 case when pgmem.age <> 0 then
									concat(pgmem.age,'-','(', to_char(age_ason_date::udd_date, 'DD-MM-YYYY'),')') 
								 else 
									''
								 end
								 as age_ason_date_concat ,
								 pgmem.fatherhusband_name,
							     fn_get_masterdesc('QCD_CASTE',pgmem.caste_code,_lang_code) as caste,
								 concat(	addr.addr_line,'<br>',fn_get_villagedesc(addr.village_id),
										  	'<br>',concat(fn_get_panchayatdesc(addr.panchayat_id),
								   			', ',fn_get_blockdesc(addr.block_id),
								   			', ',fn_get_districtdesc(addr.district_id))) as ""registered_address"",
								 addr.addr_line,
								 fn_get_villagedesc(addr.village_id) as village_desc,
								 concat(fn_get_villagedesc(addr.village_id),
										', ',fn_get_blockdesc(addr.block_id),
										', ',fn_get_districtdesc(addr.district_id)) as vill_blk_dist,
								 fn_get_blockdesc(addr.block_id) as block_desc,
								 fn_get_districtdesc(addr.district_id) as district_desc,
								 fn_get_statedesc(addr.state_id) as state_desc
				  from 		 pg_mst_tproducergroup as pg
				  inner join pg_mst_tpgmember as pgmem 
				  on 		 pg.pg_id = pgmem.pg_id 
				  and 		 pgmem.pgmember_clas_code = 'PG'
				  and		 pgmem.status_code <> 'R'
				  left  join  pg_mst_tpgmemberaddress as addr on pgmem.pgmember_id = addr.pgmember_id 
				  left join shg_profile as shg on pgmem.shg_id = shg.shg_id::udd_code  and is_active = true
				  and 		shg.state_id = addr.state_id
				  where 	pg.pg_id = _pg_id and pg.status_code <> 'I';
				  
	-- PG NONMEMBER DETAILS
	open _result_pgnonmemprof for select 
								 pgmem.pgmember_id,
							     pgmem.pgmember_name,
							     fn_get_masterdesc('QCD_PGMEMBER_TYPE',pgmem.pgmember_type_code,_lang_code) as membertype,
								 concat(shg.shg_code,'&',shg.shg_name)  as shgcode_name,
							     fn_get_masterdesc('QCD_GENDER',pgmem.gender_code,_lang_code) as gender,
								 pgmem.pgmember_clas_code,
								 fn_get_masterdesc('QCD_PGMEMBER_CLAS',pgmem.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
								 pgmem.mobile_no_active,
								 pgmem.mobile_no_alternative,
								 pgmem.dob_date,
								 pgmem.age_ason_date,
								 case when pgmem.age <> 0 then
									concat(pgmem.age,'-','(', to_char(age_ason_date::udd_date, 'DD-MM-YYYY'),')') 
								 else 
									''
								 end
								 as age_ason_date_concat ,
								 pgmem.fatherhusband_name,
							     fn_get_masterdesc('QCD_CASTE',pgmem.caste_code,_lang_code) as caste,
								 concat(	addr.addr_line,'<br>',fn_get_villagedesc(addr.village_id),
										  	'<br>',concat(fn_get_panchayatdesc(addr.panchayat_id),
								   			', ',fn_get_blockdesc(addr.block_id),
								   			', ',fn_get_districtdesc(addr.district_id))) as ""registered_address"",
								 addr.addr_line,
								 fn_get_villagedesc(addr.village_id) as village_desc,
								 concat(fn_get_villagedesc(addr.village_id),
										', ',fn_get_blockdesc(addr.block_id),
										', ',fn_get_districtdesc(addr.district_id)) as vill_blk_dist,
								 fn_get_blockdesc(addr.block_id) as block_desc,
								 fn_get_districtdesc(addr.district_id) as district_desc,
								 fn_get_statedesc(addr.state_id) as state_desc
				  from 		 pg_mst_tproducergroup as pg
				  inner join pg_mst_tpgmember as pgmem 
				  on 		 pg.pg_id = pgmem.pg_id 
				  and 		 pgmem.pgmember_clas_code = 'NONPG_OTHERS'
				  and		 pgmem.status_code <> 'R'
				  left  join  pg_mst_tpgmemberaddress as addr on pgmem.pgmember_id = addr.pgmember_id 
				  left join shg_profile as shg on pgmem.shg_id = shg.shg_id::udd_code  and is_active = true
				  and 		shg.state_id = addr.state_id
				  where 	pg.pg_id = _pg_id and pg.status_code <> 'I';
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgtovprpsynclist(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _last_sync_date udd_datetime, INOUT _result_clflist refcursor DEFAULT 'rs_clglist'::refcursor, INOUT _result_pglist refcursor DEFAULT 'rs_pglist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B01PTVG01
	*/
begin
	-- stored procedure body 
		open _result_clflist  for  select 	
										*
							from 		clf_vprp_view
							where 		pg_id = _pg_id
							and         (created_date > _last_sync_date
							or 			updated_date > _last_sync_date);
		
		open _result_pglist	for  select 	
									  *
							from 	  pg_vprp_view
							where 	  pg_code = _pg_id
							and       (created_date > _last_sync_date
							or 		  updated_date > _last_sync_date);
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgumprovlistreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _status_code udd_code, _lang_code udd_code, INOUT _result_pgumprovlist refcursor DEFAULT 'rs_pgumprovlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 21-02-2022
		SP Code : B08UMPR01
	*/
	
begin
	
	-- stored procedure body
	open _result_pgumprovlist for select 	
							pg.pg_id,
							pg.pg_name,
							pg.formation_date,
							um.udyogmitra_name as udyogmitra_name,
							um.mobile_no as mobile_no,
							fn_get_villagecount_pgid(pg.pg_id) as village_count,
							fn_get_membercount_pgid(pg.pg_id) as member_count,
							fn_get_masterdesc('QCD_ADDR_TYPE',addr.addr_type_code,_lang_code) as addr_type_desc,
				 			addr.addr_line,
							fn_get_villagedesc(addr.village_id) as village_desc,
							fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
							fn_get_blockdesc(addr.block_id) as block_desc,
							fn_get_districtdesc(addr.district_id) as district_desc,
							fn_get_statedesc(addr.state_id) as state_desc,
							fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc,
							pg.status_code as status_code
				  from 		pg_mst_tproducergroup as pg
				  inner join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
				  and 		addr.addr_type_code = 'QCD_ADDRTYPE_REG'
				  inner join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 		um.tran_status_code = 'P'
				  where 	addr.block_id = case 
												when _block_id = 0 then 
													 coalesce(addr.block_id,_block_id)
											    else 
													coalesce(_block_id,addr.block_id) 
											 end
				  and addr.panchayat_id = case 
											when _panchayat_id = 0 then 
												 coalesce(addr.panchayat_id,_panchayat_id)
											 else 
												coalesce(_panchayat_id,addr.panchayat_id) 
										  end
				 and addr.village_id = case 
											when _village_id = 0 then 
												 coalesce(addr.village_id,_village_id)
											 else 
												coalesce(_village_id,addr.village_id) 
										  end
				 and pg.status_code = case 
											when _status_code = '' then 
												 coalesce(pg.status_code,_status_code)
											 else 
												coalesce(_status_code,pg.status_code) 
										  end
				 order by 	pg_gid desc;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgwithoutbankreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _status_code udd_code, _lang_code udd_code, INOUT _result_pgwobanklist refcursor DEFAULT 'rs_pgwobanklist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 21-02-2022
		SP Code : B08WOBR01
	*/
	
begin
	
	-- stored procedure body
	open _result_pgwobanklist for select 	
							pg.pg_id,
							pg.pg_name,
							pg.formation_date,
							um.udyogmitra_name as udyogmitra_name,
							um.mobile_no as mobile_no,
							fn_get_villagecount_pgid(pg.pg_id) as village_count,
							fn_get_membercount_pgid(pg.pg_id) as member_count,
							fn_get_masterdesc('QCD_ADDR_TYPE',addr.addr_type_code,_lang_code) as addr_type_desc,
				 			addr.addr_line,
							fn_get_villagedesc(addr.village_id) as village_desc,
							fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
							fn_get_blockdesc(addr.block_id) as block_desc,
							fn_get_districtdesc(addr.district_id) as district_desc,
							fn_get_statedesc(addr.state_id) as state_desc,
							fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc,
							pg.status_code as status_code
				  from 		pg_mst_tproducergroup as pg
				  left join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
				  and 		addr.addr_type_code = 'QCD_ADDRTYPE_REG'
				  left join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  and 		um.tran_status_code <> 'I'
				  where 	addr.block_id = case 
												when _block_id = 0 then 
													 coalesce(addr.block_id,_block_id)
											    else 
													coalesce(_block_id,addr.block_id) 
											 end
				  and addr.panchayat_id = case 
											when _panchayat_id = 0 then 
												 coalesce(addr.panchayat_id,_panchayat_id)
											 else 
												coalesce(_panchayat_id,addr.panchayat_id) 
										  end
				 and addr.village_id = case 
											when _village_id = 0 then 
												 coalesce(addr.village_id,_village_id)
											 else 
												coalesce(_village_id,addr.village_id) 
										  end
				 and pg.status_code = case 
											when _status_code = '' then 
												 coalesce(pg.status_code,_status_code)
											 else 
												coalesce(_status_code,pg.status_code) 
										  end
			     and pg.pg_id not in (select pg_id from pg_mst_tbank)
				 order by 	pg_gid desc;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgwithoutumreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _status_code udd_code, _lang_code udd_code, INOUT _result_pgwoudyogmitra refcursor DEFAULT 'rs_pgwoudyogmitra'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By   : Mangai
		Created Date : 31-03-2022
		SP Code      : B08WOUR01
	*/
	
begin
	
	-- stored procedure body
	open _result_pgwoudyogmitra for select 	
											pg.pg_id,
											pg.pg_name,
											pg.formation_date,
											'' as udyogmitra_name,
											'' as mobile_no,
											fn_get_villagecount_pgid(pg.pg_id) as village_count,
											fn_get_membercount_pgid(pg.pg_id) as member_count,
											fn_get_masterdesc('QCD_ADDR_TYPE',addr.addr_type_code,_lang_code) as addr_type_desc,
											addr.addr_line,
											fn_get_villagedesc(addr.village_id) as village_desc,
											fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
											fn_get_blockdesc(addr.block_id) as block_desc,
											fn_get_districtdesc(addr.district_id) as district_desc,
											fn_get_statedesc(addr.state_id) as state_desc,
											fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc,
											pg.status_code as status_code
								  from 		pg_mst_tproducergroup as pg
								  left join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
								  and 		addr.addr_type_code = 'QCD_ADDRTYPE_REG'
--								  left join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
--								  and 		um.tran_status_code <> 'I'
								  where 	addr.block_id = case 
																when _block_id = 0 then 
																	 coalesce(addr.block_id,_block_id)
																else 
																	coalesce(_block_id,addr.block_id) 
															 end
								  and addr.panchayat_id = case 
															when _panchayat_id = 0 then 
																 coalesce(addr.panchayat_id,_panchayat_id)
															 else 
																coalesce(_panchayat_id,addr.panchayat_id) 
														  end
								 and addr.village_id = case 
															when _village_id = 0 then 
																 coalesce(addr.village_id,_village_id)
															 else 
																coalesce(_village_id,addr.village_id) 
														  end
								 and pg.status_code = case 
															when _status_code = '' then 
																 coalesce(pg.status_code,_status_code)
															 else 
																coalesce(_status_code,pg.status_code) 
														  end
								 and pg.pg_id not in (select pg_id from pg_mst_tudyogmitra)
								 order by 	pg_gid desc;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_pgwooffbearersreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _status_code udd_code, _lang_code udd_code, INOUT _result_pgwooffbearerslist refcursor DEFAULT 'rs_pgwooffbearerslist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 21-02-2022
		SP Code : B08OFBR01
	*/
	
begin
	
	-- stored procedure body
	open _result_pgwooffbearerslist for select 	
											pg.pg_id,
											pg.pg_name,
											pg.formation_date,
											um.udyogmitra_name as udyogmitra_name,
											um.mobile_no as mobile_no,
											fn_get_villagecount_pgid(pg.pg_id) as village_count,
											fn_get_membercount_pgid(pg.pg_id) as member_count,
											fn_get_masterdesc('QCD_ADDR_TYPE',addr.addr_type_code,_lang_code) as addr_type_desc,
											addr.addr_line,
											fn_get_villagedesc(addr.village_id) as village_desc,
											fn_get_panchayatdesc(addr.panchayat_id) as panchayat_desc,
											fn_get_blockdesc(addr.block_id) as block_desc,
											fn_get_districtdesc(addr.district_id) as district_desc,
											fn_get_statedesc(addr.state_id) as state_desc,
											fn_get_masterdesc('QCD_STATUS',pg.status_code,_lang_code) as status_desc,
											pg.status_code as status_code
								  from 		pg_mst_tproducergroup as pg
								  left join pg_mst_taddress as addr on pg.pg_id = addr.pg_id
								  and 		addr.addr_type_code = 'QCD_ADDRTYPE_REG'
								  left join pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
								  and 		um.tran_status_code <> 'I'
								  where 	addr.block_id = case 
																when _block_id = 0 then 
																	 coalesce(addr.block_id,_block_id)
																else 
																	coalesce(_block_id,addr.block_id) 
															 end
								  and addr.panchayat_id = case 
															when _panchayat_id = 0 then 
																 coalesce(addr.panchayat_id,_panchayat_id)
															 else 
																coalesce(_panchayat_id,addr.panchayat_id) 
														  end
								 and addr.village_id = case 
															when _village_id = 0 then 
																 coalesce(addr.village_id,_village_id)
															 else 
																coalesce(_village_id,addr.village_id) 
														  end
								 and pg.status_code = case 
															when _status_code = '' then 
																 coalesce(pg.status_code,_status_code)
															 else 
																coalesce(_status_code,pg.status_code) 
														  end
								 and pg.pg_id not in (select pg_id from pg_mst_tofficebearers)
								 order by pg_gid desc;

end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_procurecostlist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _from_date udd_date, _to_date udd_date, _pg_id udd_code, _lang_code udd_code, INOUT _result_proccostlist refcursor DEFAULT 'rs_proccostlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B01PPCG01
	*/
	
	v_block_id udd_int = 0;
begin

	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	-- PROCURE COST
	open _result_proccostlist for select
									pg.pg_name,
									pg.pg_id,
									pc.proccost_gid,
									pc.proc_date,
									to_char(pc.tran_datetime,'YYYY-MM-DD HH24:MI:SS') as tran_datetime,
									pc.package_cost,
									pc.loading_unloading_cost,
									pc.transport_cost,
									pc.other_cost,
									pc.proccost_remark
					from 		    pg_trn_tprocurecost as pc
					inner join 		pg_mst_tproducergroup as pg on pc.pg_id = pg.pg_id
					and             pg.pg_id in (select fn_get_pgid(v_block_id))
					and				pg.status_code <> 'I'
					where 			pc.proc_date >= _from_date
					and 			pc.proc_date <= _to_date
					and 			pc.pg_id = _pg_id
					and 			pc.status_code = 'A';
					
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_procureproductlist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _from_date udd_date, _to_date udd_date, _pg_id udd_code, _lang_code udd_code, INOUT _result_procprodlist refcursor DEFAULT 'rs_procprodlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		
		updated By : Mohan S
		Updated date : 12-08-2022
		
		SP Code : B01PPRG01
	*/
	
	v_block_id udd_int = 0;
begin

	select fn_get_blockid(_block_code)::udd_int into v_block_id;
	-- stored procedure body
	-- PROCURE PRODUCT
	open _result_procprodlist for select
								pg.pg_ll_name,
								s.session_date,
								s.session_id,
								pgmem.pgmember_clas_code,
							    fn_get_masterdesc('QCD_PGMEMBER_CLAS',pgmem.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
								count(distinct p.pgmember_id) as tot_members,
								count(distinct (case when pp.prod_type_code = 'P' 
												then pp.prod_code else null end)) as tot_peri_count,
								sum(case when pp.prod_type_code = 'P' then pp.proc_qty else 0 end) as tot_peri_qty,
								count(distinct (case when pp.prod_type_code = 'N' 
												then pp.prod_code else null end)) as tot_nonperi_count,
								sum(case when pp.prod_type_code = 'N' then pp.proc_qty else 0 end) as tot_nonperi_qty
					from 		pg_trn_tsession as s
					inner join 	pg_trn_tprocure as p on s.pg_id = p.pg_id 
					and 		s.session_id = p.session_id and p.status_code = 'A'
					inner join 	pg_trn_tprocureproduct as pp on	p.pg_id = pp.pg_id 
					and 		p.session_id = pp.session_id
					and 		p.pgmember_id = pp.pgmember_id 
					and 		p.proc_date = pp.proc_date
					inner join  pg_mst_tproducergroup as pg on s.pg_id = pg.pg_id 
					and         pg.pg_id in (select fn_get_pgid(v_block_id))
					and 		pg.status_code <> 'I'
					inner join  pg_mst_tpgmember as pgmem on p.pgmember_id = pgmem.pgmember_id
					and 		pgmem.status_code <> 'R'
					where 	    p.pg_id = _pg_id
					and 		s.session_date >= _from_date
					and 		s.session_date <= _to_date
					and 		s.status_code = 'A'
					group by 	s.session_date,s.session_id,pg.pg_ll_name,pg.pg_name,pgmem.pgmember_clas_code;
					
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_produceaggreport(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _pgmember_id udd_code, _from_date udd_date, _to_date udd_date, _user_code udd_user, _role_code udd_code, _lang_code udd_code, INOUT _result_produceagg refcursor DEFAULT 'rs_produceagg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 23-02-2022
		
		updated By : Mohan S
		Updated date : 12-08-2022
		
		SP Code : B08PDAR01
	*/
begin
	-- stored procedure body
	open _result_produceagg for select 	
								   pp.proc_date,
								   concat(mem.pgmember_id,'-',mem.pgmember_name) as pgmember_id_name,
								   case 
								   when mem.pgmember_type_code = 'individual' then 
								   	   'NONPG_OTHERS'
								   else
									   fn_get_masterdesc('QCD_PGMEMBER_TYPE',mem.pgmember_type_code,'en_US') 
								   end as pgmember_type_desc,
								   -- fn_get_masterdesc('QCD_PGMEMBER_TYPE',mem.pgmember_type_code,_lang_code) as pgmember_type_desc,
								   fn_get_masterdesc('QCD_PROD_TYPE',pp.prod_type_code,_lang_code) as prod_type_desc,
								   pp.prod_code,
								   fn_get_productdesc(pp.prod_code, _lang_code) as prod_desc,
								   fn_get_masterdesc('QCD_GRADE',pp.grade_code,_lang_code) as grade_desc,
								   mem.pgmember_clas_code,
								   fn_get_masterdesc('QCD_PGMEMBER_CLAS',mem.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
								   TRUNC(pp.proc_qty,2) as proc_qty,
								   TRUNC(pp.proc_rate,2) as proc_rate,
								   TRUNC(sum(pp.proc_rate * pp.proc_qty),2) as aggregation_value
						from	   pg_mst_tpgmember as mem 
						inner join pg_trn_tprocureproduct as pp 
						on 	  mem.pgmember_id = pp.pgmember_id
						where pp.proc_date >= _from_date 
						and   pp.proc_date <= _to_date
						and   pp.pg_id = _pg_id 
						and	  mem.pgmember_id =
						case 
							when _pgmember_id isnull or _pgmember_id = ''  then 
								coalesce(mem.pgmember_id,_pgmember_id)
							else 
								coalesce(_pgmember_id,mem.pgmember_id) 
						end
						group by pp.proc_date,mem.pgmember_id,mem.pgmember_name,
						mem.pgmember_type_code,pp.prod_type_code,pp.prod_code,pp.grade_code,
						pp.grade_code,pp.proc_qty,pp.proc_rate,mem.pgmember_clas_code;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_productdtl(_prod_code udd_code, _lang_code udd_code, INOUT _result_product refcursor DEFAULT 'rs_product'::refcursor, INOUT _result_language refcursor DEFAULT 'rs_language'::refcursor, INOUT _result_price refcursor DEFAULT 'rs_price'::refcursor, INOUT _result_quality refcursor DEFAULT 'rs_quality'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 29-12-2021
		SP Code : B01PRDG01
	*/
	-- stored procedure body
	-- PRODUCT --
	open _result_product for select 	
							p.prod_gid,
							p.prod_code,
							t.prod_desc,
							p.farm_prod_flag,
							fn_get_masterdesc('QCD_PG_TYPE',p.farm_prod_flag,_lang_code) as farm_prod_flag_desc,
							p.prod_type_code,
							fn_get_masterdesc('QCD_PROD_TYPE',p.prod_type_code,_lang_code) as prod_type_desc,
							p.category_code,
							fn_get_masterdesc('QCD_CATEGORY',p.category_code,_lang_code) as category_desc,
							p.subcategory_code,
							fn_get_masterdesc('QCD_SUBCATEGORY',p.subcategory_code,_lang_code) as subcategory_desc,
							p.uom_code,
							fn_get_masterdesc('QCD_UOM',p.uom_code,_lang_code) as uom_desc,
							p.prod_image,
							p.status_code,
							fn_get_masterdesc('QCD_STATUS',p.status_code,_lang_code) as status_desc,
							p.created_date,
							p.created_by,
							p.updated_date,
							p.updated_by,
							to_char(p.row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') as row_timestamp
				  from 		core_mst_tproduct p
				  inner join core_mst_tproducttranslate t on t.prod_code = p.prod_code
				  where 	t.lang_code = 'en_US'
				  and       p.prod_code = _prod_code
		   		  order by 	prod_gid;
				 
	-- LANGUAGE --
	open _result_language for select 
							p.prodtranslate_gid,
							p.prod_code,
							p.lang_code,
							l.lang_name as lang_desc,
							p.prod_desc
				  from 		core_mst_tproducttranslate p
				  inner join core_mst_tlanguage l on l.lang_code = p.lang_code
				  where p.prod_code = _prod_code
				  and	p.lang_code != 'en_US';
				  
	-- PRICE --
	open _result_price for select 
						 prodprice_gid,
						 prod_code,
						 state_id,
						 fn_get_statedesc(state_id) as state_desc,
						 grade_code,
						 fn_get_masterdesc('QCD_GRADE',grade_code,_lang_code) as grade_desc,
						 msp_price,
						 procurement_price,
						 last_modified_date
				  from 	 core_mst_tproductprice
				  where prod_code = _prod_code;
				  
	-- QUALITY --
	open _result_quality for select
				  				prodqlty_gid,
								prod_code,
								qltyparam_code,
								fn_get_masterdesc('QCD_QC_PARAMETER',qltyparam_code,_lang_code) as qltyparam_desc,
								range_from,
								range_to,
								qltyuom_code,
								fn_get_masterdesc('QCD_QC_UOM',qltyuom_code,_lang_code) as qltyuom_desc,
								threshold_value
				  	from 		core_mst_tproductquality
				  	where prod_code = _prod_code;
											
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_productlist(_user_code udd_code, _lang_code udd_code, INOUT _result_product refcursor DEFAULT 'rs_productlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 26-12-2021
		SP Code : B01PRLG01
	*/
	-- stored procedure body
	open _result_product for select distinct
								p.prod_gid,
								p.prod_code,
								t.prod_desc,
								p.prod_type_code,
								fn_get_masterdesc('QCD_PROD_TYPE',p.prod_type_code,'en_US') as prod_type_desc,
								p.category_code,
								fn_get_masterdesc('QCD_CATEGORY',p.category_code,_lang_code) as category_desc,
								p.subcategory_code,
								fn_get_masterdesc('QCD_SUBCATEGORY',p.subcategory_code,_lang_code) as subcategory_desc,
								p.uom_code,
								fn_get_masterdesc('QCD_UOM',uom_code,_lang_code) as uom_desc,
								p.status_code,
								fn_get_masterdesc('QCD_STATUS',p.status_code,_lang_code) as status_desc,
								p.created_date,
								p.created_by,
								p.updated_date,
								p.updated_by,
								p.row_timestamp
					  from 		core_mst_tproduct p
					  inner join core_mst_tproducttranslate t on t.prod_code = p.prod_code
					  and t.lang_code = _lang_code
					  order by 	p.status_code,p.prod_gid;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_productnamelist(_lang_code udd_code, INOUT _result_product refcursor DEFAULT 'rs_productlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Mohan s
		Created Date : 19-03-2022
		SP Code : B01PRLG02
	*/
	-- stored procedure body
	open _result_product for select distinct
									bp.prod_code,
									t.prod_desc
						  from 		core_mst_tproduct as p
						  inner join core_mst_tproducttranslate as t 
						  on 		t.prod_code = p.prod_code
						  and 		t.lang_code = _lang_code
						  and		p.status_code = 'A'
						  inner join pg_trn_tbussplanproduct as bp
						  on p.prod_code = bp.prod_code
						  order by 	t.prod_desc ;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_productstock(_pg_id udd_code, _prod_type_code udd_code, _prod_code udd_code, _lang_code udd_code, INOUT _result_prodstock refcursor DEFAULT 'rs_prodstock'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By   : Mangai
		Created Date : 13-05-2022
		SP Code      : 
	*/
begin
	-- stored procedure body 
	open _result_prodstock for select 
										prod_type_code,
										fn_get_masterdesc('QCD_PROD_TYPE', prod_type_code, _lang_code) as prod_type_desc,
										prod_code,
										fn_get_productdesc(prod_code, _lang_code) as prod_desc,
										uom_code,
										fn_get_masterdesc('QCD_UOM', uom_code, _lang_code) as uom_desc,
										grade_code,
										stock_qty
								from    pg_trn_tproductstock
								where   pg_id = _pg_id
								and     prod_type_code = 
										case    
												when _prod_type_code isnull or _prod_type_code = ''
												then
													coalesce(prod_type_code,_prod_type_code)
												else
													coalesce(_prod_type_code,prod_type_code)
										end
								and     prod_code = 
										case    
												when _prod_code isnull or _prod_code = ''
												then
													coalesce(prod_code,_prod_code)
												else
													coalesce(_prod_code,prod_code)
										end;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_raiseerror(_user_id udd_code)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*RAISE EXCEPTION 'Nonexistent ID --> %', _user_id
      USING HINT = 'Please check your user ID';*/
	 
	  RAISE exception 'Duplicate user ID: %', _user_id; 
	  --USING ERRCODE = 'unique_violation';
	  
	 -- RAISE division_by_zero;
	  --RAISE SQLSTATE '22012';
	  
	  -- select 1/0;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_raiseerror_old()
 LANGUAGE plpgsql
AS $procedure$
begin
	
	   select 1/0;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_reportlist(_report_code udd_code, _lang_code udd_code, INOUT _result_reportlist refcursor DEFAULT 'rs_reportlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By   : Mangai
		Created Date : 16-05-2022
		SP Code      : B01REPGET
	*/
	
	open _result_reportlist for select 
											r.report_code,
											r.report_name,
											r.sp_name,
											rp.param_code,
											rp.param_type_code,
											fn_get_masterdesc('QCD_PARAM_TYPE', param_type_code, _lang_code) as param_type_desc,
											rp.param_name,
											rp.param_desc,
											rp.param_datatype_code,
											fn_get_masterdesc('QCD_PARAM_DATATYPE', param_datatype_code, _lang_code) as param_datatype_desc,
											rp.param_order
								from 		core_mst_treport as r
								inner join  core_mst_treportparam as rp
								on          rp.report_code = r.report_code
								where       r.report_code = _report_code
								and         r.status_code = 'A';
	
END;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_rolelist(_lang_code udd_code, INOUT _result_role refcursor DEFAULT 'rs_role'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
/*
	Created By : Mohan S
	Created Date : 14-12-2021
	SP Code : B01ROLG03
*/
begin
	-- stored procedure body
	open _result_role for select 	
						 role_gid,
						 role_code,
						 role_name,
						 status_code,
						 fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc
				from 	 core_mst_trole
				where    status_code = 'A'
				and 	 role_code <> 'pla'
		   		order by role_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_rolemenulist(_lang_code udd_code, INOUT _result_rolemenu refcursor DEFAULT 'rs_rolemenu'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	-- stored procedure body
	open _result_rolemenu for select 	
						 menu.menu_gid as menu_gid,
						 menu.menu_code as menu_code,
						 menu.parent_code as parent_code,
						 menu.menu_slno as menu_slno,
						 menu.url_action_method as url_action_method,
						 menu.status_code as status_code,
						 fn_get_masterdesc('QCD_STATUS',menu.status_code,_lang_code) as status_desc,
						 menutran.menu_desc as menu_desc
				from 	 core_mst_tmenu as menu
				inner join core_mst_tmenutranslate as menutran on menu.menu_code = menutran.menu_code
				where 	 menutran.lang_code = _lang_code
				and 	 menu.status_code = 'A'
		   		order by menu.menu_slno;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_saleadjustmentlist(_pg_id udd_code, _inv_no udd_code, _lang_code udd_code, INOUT _result_saleadjust refcursor DEFAULT 'rs_saleadjlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	/*
		Created By : Mohan S
		Created Date : 12-09-2022
		
		Created By : Mohan S (Replaced from Dev)
		Created Date : 12-09-2022
		SP Code : B01SADG01
	*/
BEGIN
	
	-- stored procedure body
	open _result_saleadjust for select
									pg_id,
									inv_no,
									inv_date,
									prod_code,
									grade_code,
									prod_type_code,
									concat(fn_get_productdesc(prod_code,_lang_code),'&',
	   								fn_get_masterdesc('QCD_GRADE',grade_code,_lang_code)) as prodgrade,
									sum(case when stock_adj_flag = 'Y' then sale_qty else 0 end) as sale_qty,
									sum(case when stock_adj_flag = 'Y' then inv_qty else 0 end) as inv_qty,
									sum(sale_rate*sale_qty) as sale_amount,  
									sum(sale_rate*sale_qty) as sale_base_amount,  
									sum(sale_rate*inv_qty) as inv_amount,   
									sum(sale_rate*inv_qty)/sum(case when stock_adj_flag = 'Y' then inv_qty else 0 end) as rate,
									count(*) as record_count,
									min(rec_slno) as min_rec_slno,
									max(rec_slno) as max_rec_slno
					            from pg_trn_tsaleproduct 
								where pg_id = _pg_id 
								and   inv_no = _inv_no
								and   status_code = 'A'
								group by pg_id,inv_no,inv_date,prod_code,
								grade_code,prod_type_code,prodgrade ;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_salelist(_user_code udd_user, _role_code udd_code, _block_code udd_code, _from_date udd_date, _to_date udd_date, _pg_id udd_code, _lang_code udd_code, INOUT _result_salelist refcursor DEFAULT 'rs_salelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B01SALG01
	*/
	
	v_block_id udd_int = 0;
begin

	select fn_get_blockid(_block_code)::udd_int into v_block_id;

	-- stored procedure body
	-- SALE
	open _result_salelist for select 
									pg.pg_ll_name,
									s.pg_id,
									s.inv_date,
									count(distinct s.sale_gid) as tot_member,
									sum(case when sp.prod_type_code = 'P' 
													then sp.sale_qty else 0 end) 		as tot_peri_qty,
									count(distinct (case when sp.prod_type_code = 'P' 
													then sp.prod_code else null end)) 	as tot_peri_count,
									sum(case when sp.prod_type_code = 'N' 
													then sp.sale_qty else 0 end) 		as tot_nonperi_qty,
									count(distinct (case when sp.prod_type_code = 'N' 
													then sp.prod_code else null end)) 	as tot_nonperi_count,
									sum(sp.sale_base_amount+sp.cgst_amount+sp.sgst_amount) as sale_amount ,
									pg.pg_name
						from 		pg_trn_tsale as s 
						inner join  pg_trn_tsaleproduct as sp on s.pg_id = sp.pg_id
						and 		s.inv_date = sp.inv_date
						and 		s.inv_no = sp.inv_no
						inner join  core_mst_tproduct as p on sp.prod_code = p.prod_code 
						inner join  pg_mst_tproducergroup as pg on s.pg_id = pg.pg_id 
						and         pg.pg_id in (select fn_get_pgid(v_block_id))
						and 		pg.status_code <> 'I'
						where 		s.inv_date >= _from_date
						and 		s.inv_date <= _to_date
						and 		s.pg_id = _pg_id
						and 		s.status_code = 'A'
						group by s.pg_id,s.inv_date,pg.pg_name,pg.pg_ll_name;
					
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_screendatalist(_screen_code udd_code, _lang_code udd_code, INOUT _result_screendata refcursor DEFAULT 'rs_screendata'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 14-12-2021
		SP Code : B01SNDG01
	*/
begin
	-- stored procedure body
	/* open _result_screendata for select 	
							screendata_gid,
							screen_code,
							lang_code,
							ctrl_type_code,
							ctrl_id,
							data_field,
							label_desc,
							tooltip_desc,
							default_label_desc,
							default_tooltip_desc,
							ctrl_slno,
							created_date,
							created_by,
							updated_date,
							updated_by
				  from 		core_mst_tscreendata
				  where 	screen_code = _screen_code
				  and 		lang_code = _lang_code
		   		  order by 	ctrl_slno;*/
				  
				  
		open _result_screendata for SELECT
										 a.concat_field,
										 coalesce(a.screendata_gid,b.screendata_gid) as screendata_gid,
										 coalesce(a.screen_code,b.screen_code) as screen_code,
										 coalesce(a.lang_code,b.lang_code)as lang_code,
										 coalesce(a.ctrl_type_code,b.ctrl_type_code)as ctrl_type_code,
										 coalesce(a.ctrl_id,b.ctrl_id)as ctrl_id,
										 coalesce(a.data_field,b.data_field)as data_field,
										 coalesce(a.label_desc,b.label_desc)as label_desc,
										 coalesce(a.tooltip_desc,b.tooltip_desc)as tooltip_desc,
										 coalesce(a.default_label_desc,b.default_label_desc)as default_label_desc,
										 coalesce(a.default_tooltip_desc,b.default_tooltip_desc)as default_tooltip_desc,
										 coalesce(a.ctrl_slno,b.ctrl_slno)as ctrl_slno,
										 coalesce(a.created_date,b.created_date)as created_date,
										 coalesce(a.created_by,b.created_by)as created_by,
										 coalesce(a.updated_date,b.updated_date)as updated_date,
										 coalesce(a.updated_by,b.updated_by)as updated_by
							 from        screendata_view as b
							 left join   screendata_view as a
							 on          a.lang_code    = _lang_code
							 and 		 a.screen_code  = _screen_code
							 and 		 b.concat_field = a.concat_field
							 where 		 b.screen_code  = _screen_code
							 and 	     b.lang_code    = 'en_US'
							 order by    b.ctrl_slno,b.ctrl_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_screenlist(_lang_code udd_code, _user_code udd_code, INOUT _result_screen refcursor DEFAULT 'rs_screenlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01SCRG01
	*/
	-- stored procedure body
	open _result_screen for select 	
									screen_gid,
									screen_code,
									screen_name,
									status_code,
									fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
									created_date,
									created_by,
									updated_date,
									updated_by
							  from 		core_mst_tscreen
							  order by 	status_code,screen_code;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_screennamelist(_lang_code udd_code, INOUT _result_bankscreennamelist refcursor DEFAULT 'rs_screennamelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By   : Mangai
		Created Date : 30-03-2022
		SP Code      : B01SCRG01
	*/
begin
	-- stored procedure body
	open _result_bankscreennamelist for select
												 screen_code,
												 screen_name
									    from 	 core_mst_tscreen
										where    status_code = 'A'
										and      screen_code like 'W%' collate pg_catalog.""default"";
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_shgmemberprofilelist(_pg_id udd_code, _village_id udd_int, _panchayat_id udd_int, _shg_member_id udd_int, INOUT _result_shgmemberproflist refcursor DEFAULT 'rs_shgmemprof'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 06-01-2022
		SP Code : B04SMPG01
		
		Updated By : Vijayavel J
		Updated Date : 14-10-2022
	*/
begin
	-- stored procedure body
	
	open _result_shgmemberproflist for 	SELECT  pm.pg_id,
												shg.state_id,
												shg.district_id,
												shg.block_id,
												shg.gp_id as panchayat_id,
												shg.village_id,
												fn_get_villagedesc(shg.village_id::udd_int) as village_desc,
												shg.shg_code as shg_id,
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
														WHEN m.dob IS NOT NULL THEN 'Y'::text
														ELSE 'N'::text
													END AS dob_flag,
												m.dob,
												m.age,
												m.age_as_on,
												CASE
														WHEN m.phone1_mobile_no = 0 THEN null
														ELSE m.phone1_mobile_no
												END AS member_phone,
    											-- m.phone1_mobile_no AS member_phone,
												m.created_date,
    											m.last_updated_date AS updated_date
											-- CR NO : CR0001 / Resource - Emp10138 / 25-jan-2023 / CS-001
											FROM pg_mst_tpanchayatmapping pm
											-- CR NO : CR0001 / Resource - Emp10138 / 25-jan-2023 / CE-001
											JOIN shg_profile_consolidated shg ON pm.panchayat_id = shg.gp_id AND shg.is_active = true 
											JOIN member_profile_consolidated m ON shg.shg_code = m.shg_code AND shg.is_active = true
											where 	pm.pg_id = _pg_id
											and		shg.village_id = _village_id
											and 	shg.gp_id = _panchayat_id
											and 	case when _shg_member_id = 0
											then 
												shg.shg_code = shg.shg_code
											else 
												shg.shg_code = _shg_member_id::udd_code
											end
											order by  pm.pg_id;
	/*											
	open _result_shgmemberproflist for SELECT   pm.pg_id,
												shg.state_id,
												shg.district_id,
												shg.block_id,
												shg.panchayat_id,
												shg.village_id,
												vm.village_name_en as village_desc,
												shg.shg_id,
												shg.shg_name,
												shg.shg_name_local,
												m.member_id AS shg_member_id,
												m.member_name AS shg_member_name,
												m.member_name_local AS shg_member_name_local,
												m.father_husband AS relation_code,
												m.relation_name,
												m.relation_name_local,
												m.gender,
												m.social_category,
													CASE
														WHEN m.dob IS NOT NULL THEN 'Y'::text
														ELSE 'N'::text
													END AS dob_flag,
												m.dob,
												m.age,
												m.age_as_on,
												fn_get_lokosshgmemphone(m.state_id, m.member_id) AS member_phone,
												m.created_date,
												m.updated_date
											   FROM pg_mst_tpanchayatmapping pm
												 JOIN shg_profile shg ON pm.panchayat_id::integer = shg.panchayat_id AND shg.is_active = true
												 JOIN executive_member em ON shg.shg_id = em.ec_cbo_code::udd_int::integer AND em.ec_cbo_level = 0 AND pm.state_id::integer = em.state_id
												 JOIN member_profile m ON em.ec_member_code = m.member_id AND em.state_id = m.state_id
												 join village_master vm on shg.village_id = vm.village_id
												where 	pm.pg_id = _pg_id
												and		shg.village_id = _village_id
												and 	shg.panchayat_id = _panchayat_id
												and 	case when _shg_member_id = 0
												then 
													shg.shg_id = shg.shg_id
												else 
													shg.shg_id = _shg_member_id
												end
												order by  pm.pg_id;
*/												
	/*select 
										 pg_id,
										 state_id,
										 district_id,
										 block_id,
										 panchayat_id,
										 village_id,
										 fn_get_villagedesc(village_id) as village_desc,
										 shg_id,
										 shg_name,
										 shg_name_local,
										 shg_member_id,
										 shg_member_name,
										 shg_member_name_local,
										 relation_code,
										 relation_name,
										 relation_name_local,
										 gender,
										 social_category,
										 dob_flag,
										 age,
										 age_as_on,
										 member_phone
				  from 		shgmember_profile_view
				  where 	pg_id = _pg_id
				  and		village_id = _village_id
				  and 		panchayat_id = _panchayat_id
				  order by  pg_id*/
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_shgmemberprofilelist_old(_pg_id udd_code, INOUT _result_shgmemberproflist refcursor DEFAULT 'rs_shgmemprof'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 06-01-2022
		SP Code : B04SMPG01
	*/
begin
	-- stored procedure body
	open _result_shgmemberproflist for select 	
										 pg_id,
										 state_id,
										 district_id,
										 block_id,
										 panchayat_id,
										 village_id,
										 shg_id,
										 shg_name,
										 shg_name_local,
										 shg_member_id,
										 shg_member_name,
										 shg_member_name_local,
										 relation_code,
										 relation_name,
										 relation_name_local,
										 gender,
										 social_category,
										 dob_flag,
										 age,
										 age_as_on,
										 member_phone
				  from 		shgmember_profile_view
				  where 	pg_id = _pg_id
				  order by  pg_id;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_shgnamelist(_pg_id udd_code, _village_id udd_int, _panchayat_id udd_int, INOUT _result_shgnamelist refcursor DEFAULT 'rs_shgnamelist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 06-01-2022
		SP Code : B04SMPG01
		
		Updated By : Vijayavel J
		Updated Date : 14-10-2022
	*/
begin
	-- stored procedure body
	open _result_shgnamelist for SELECT distinct shg.shg_name ,
												shg.shg_code as shg_id,
-- 												shg.shg_name,
												shg.shg_name_local
												-- CR NO : CR0001 / Resource - Emp10138 / 25-jan-2023 / CS-001
											   	FROM pg_mst_tpanchayatmapping pm
												-- CR NO : CR0001 / Resource - Emp10138 / 25-jan-2023 / CE-001
												JOIN shg_profile_consolidated shg ON pm.panchayat_id::integer = shg.gp_id AND shg.is_active = true 
												where 	pm.pg_id = _pg_id
												and		shg.village_id = _village_id
												and 	shg.gp_id = _panchayat_id;
												

end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_smstran(INOUT _result_smstran refcursor DEFAULT 'rs_smstran'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By 	 	: Mohan S
		Created Date 	: 07-03-2022

		Modified By 	: Vijayavel
		Modified Date	: 18-03-2022

		SP Code : B01SMSG01
	*/
	v_sms_template 	udd_text;
	v_sms_url		udd_text;
	v_sms_api_key	udd_text;
	v_sms_sender_id udd_text;
	v_sms_channel	udd_text;
	v_sms_dcs		udd_text;
	v_sms_flashsms	udd_text;
	v_sms_route		udd_text;
begin
	-- stored procedure body
	-- SMS 
	v_sms_url = fn_get_configvalue('sms_url');
	v_sms_api_key = fn_get_configvalue('sms_api_key');
	v_sms_sender_id = fn_get_configvalue('sms_sender_id');
	v_sms_channel = fn_get_configvalue('sms_channel');
	v_sms_dcs = fn_get_configvalue('sms_dcs');
	v_sms_flashsms = fn_get_configvalue('sms_flashsms');
	v_sms_route = fn_get_configvalue('sms_route');
	
	open _result_smstran for select 
								smstran_gid,
								dlt_template_id,
								v_sms_url 		as sms_url,
								v_sms_api_key 	as sms_api_key,
								v_sms_sender_id as sms_sender_id,
								v_sms_channel 	as sms_channel,
								v_sms_dcs 		as sms_dcs,
								v_sms_flashsms 	as sms_flashsms,
								v_sms_route 	as sms_route,
								sms_text,
								mobile_no,
								concat
								(
									v_sms_url,
									'APIKey=',v_sms_api_key,
									'&senderid=',v_sms_sender_id,
									'&channel=',v_sms_channel,	
									'&DCS=',v_sms_dcs,
									'&flashsms=',v_sms_flashsms,
									'&number=91',mobile_no,
									'&text=',sms_text,
									'&route=',v_sms_route,
									'&EntityId&dlttemplateid=',dlt_template_id
								) as SMS
						from 	pg_trn_tsmstran
						where	status_code = 'A'
						order by smstran_gid desc;
					
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_statelist(INOUT _result_state refcursor DEFAULT 'rs_state'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 03-01-2022
		
		Updated By : Mangai
		Updated Date : 20-01-2023
		
		SP Code : B01STMG01
	*/
begin
	-- stored procedure body
	open _result_state for select 	
								state_id,
								state_code,
								state_name_en,
								state_name_hi,
								state_name_local
				  from 			state_master
				  where 		is_active = true
-- 				  order by 		is_active,state_id;
				  order by      state_name_en;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_statepgid(_state_id udd_int, INOUT _result_pgid refcursor DEFAULT 'rs_pgidlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan
		Created Date : 19-04-2022
		SP Code : B01LOCG01
	*/
	
begin
	-- stored procedure body
	-- PG ID LIST
	open _result_pgid for select 
							Distinct
							pg_id,
							'2022-01-01 00:00:00'::udd_date as from_date,
							now()::udd_date as to_date
				  from 		pg_locationcode_view 
				  where 	state_id = _state_id
				  and       state_is_active = true
		   		  order by 	pg_id;
				  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_syncscripts(_pg_id udd_code, _last_modified_date udd_date, _sync_group_name udd_code, _role_code udd_code, INOUT _result_sync refcursor DEFAULT 'rs_sync'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 17-01-2022
		SP Code : B01SYNG01
	*/
begin
	-- stored procedure body 
	/*open _result_sync for select 	
							 generate_sync_script(
							 	db_schema_name collate pg_catalog.""default"",
								src_table_name::text,
								case when pg_flag = 'Y' then concat('pg_id=','''',_pg_id,'''',case 
									   					when date_flag = 'Y' then 
									   						concat(' and (created_date >= ',chr(39),_last_modified_date,chr(39),' 
																   or updated_date >=',chr(39),_last_modified_date,chr(39),')') 
									   					else '' end)
								else '' end ::text,
								dest_table_name::text,
								conflict_key::text[],
								ignore_fields_onupdate::text[],
								ignore_fields::text[])::text
				  from 		 core_mst_tmobilesynctable 
				  where 	 sync_group_name = _sync_group_name collate pg_catalog.""default""
				  and 		 role_code = _role_code 
				  and 		 status_code = 'A' ;*/
				  
	
		open _result_sync for select 	
							 generate_mobilesync_script(
							 	db_schema_name collate pg_catalog.""default"",
								src_table_name::text,
								concat('1 = 1 ',coalesce(default_condition,''),
								case 
									when pg_flag = 'Y' then concat(' and pg_id=',chr(39),_pg_id,chr(39)) 
									else '' 
								end,
								case 
									 when date_flag = 'Y' then concat(' and (created_date >= ',chr(39),_last_modified_date,chr(39),'
																		or updated_date >=',chr(39),_last_modified_date,chr(39),')')
									 else '' 
								end)::text,
								dest_table_name::text,
								ignore_fields::text[])::text
				  from 		 core_mst_tmobilesynctable 
				  where 	 sync_group_name = _sync_group_name collate pg_catalog.""default""
				  and 		 role_code = _role_code 
				  and 		 status_code = 'A' ;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_syncscripts_old(_sync_group_name udd_code, INOUT _result_sync refcursor DEFAULT 'rs_sync'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 17-01-2022
		SP Code : B01SYNG01
	*/
begin
	-- stored procedure body 
	open _result_sync for select 	
							 generate_sync_script(
							 	db_schema_name collate pg_catalog.""default"",
								src_table_name::text,
								'1=1'::text,
								dest_table_name::text,
								conflict_key::text[],
								ignore_fields_onupdate::text[],
								ignore_fields::text[])::text
				  from 		 core_mst_tmobilesynctable 
				  where 	 sync_group_name = _sync_group_name collate pg_catalog.""default""
				  and 		 status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_syncwtm(_user_code udd_code, _pg_id udd_code, _last_sync_date udd_date, _role_code udd_code, _mobile_no udd_code, INOUT _result_syncwtm refcursor DEFAULT 'rs_syncwtm'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 05-02-2022
		SP Code : B01SYNG02
	*/
	
	v_last_sync_date udd_datetime;
begin
	select 	last_sync_date into v_last_sync_date 
	from 	core_mst_tmobilesync
	where 	pg_id			= _pg_id
	and		user_code		= _user_code
	and		role_code		= _role_code
	and 	mobile_no 		= _mobile_no
	and		sync_type_code	= 'WTM'	
	and		status_code		= 'A';
	
	insert into core_mst_tmobilesync
	(
		pg_id,
		role_code,
		user_code,
		mobile_no,
		sync_type_code,
		last_sync_date,
		prev_last_sync_date,
		status_code,
	 	created_date,
		created_by
	)
	values
	(
		_pg_id,
		_role_code,
		_user_code,
		_mobile_no,
		'WTM',
		now(),
		now(),
		'A',
		now(),
		_user_code
	)
	on conflict
		(pg_id,user_code,role_code,mobile_no,sync_type_code)
	do update set 
		last_sync_date 		= now(),
		prev_last_sync_date = v_last_sync_date,
		updated_date 		= now(),
		updated_by 			= _user_code;
	
	-- stored procedure body 
	open _result_syncwtm for 
							select 	
							    generate_mobilesync_script(
							 	db_schema_name collate pg_catalog.""default"",
								src_table_name::text,
								concat('1 = 1 ',coalesce(default_condition,''),
								case 
									when pg_flag = 'Y' then concat(' and pg_id=',chr(39),_pg_id,chr(39)) 
									else '' 
								end,
								case 
									when user_flag = 'Y' then concat(' and user_code=',chr(39),_user_code,chr(39)) 
									else '' 
								end,
								case 
									when role_flag = 'Y' then concat(' and role_code=',chr(39),_role_code,chr(39)) 
									else '' 
								end,
								case 
									when mobile_flag = 'Y' then concat(' and mobile_no=',chr(39),_mobile_no,chr(39)) 
									else '' 
								end,
								case 
									 when date_flag = 'Y' then concat(' and (created_date >= ',chr(39),_last_sync_date,chr(39),'
																		or updated_date >=',chr(39),_last_sync_date,chr(39),')')
									 else '' 
								end)::text,
								dest_table_name::text,
								ignore_fields::text[])::text
				  from 		 core_mst_tmobilesynctable 
				  where 	 role_code = _role_code 
				  and 		 status_code = 'A'
				  
				  union all 
				  select patch_qry from core_mst_tpatchqry
				  		 where 	 role_code = _role_code
						 and	(created_date::udd_date  >= _last_sync_date
						 or 	 updated_date::udd_date  >= _last_sync_date)
				  		 and 	 status_code = 'A';

end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_udyogmitra_pgid(_udyogmitra_id udd_code, INOUT _result_udyogmitrapgid refcursor DEFAULT 'rs_umpgid'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 09-02-2022
		SP Code : B04UDMG01
	*/
begin
	-- stored procedure body
	open _result_udyogmitrapgid for select 	
									  pg_id
				  from 			pg_mst_tudyogmitra
				  where 		udyogmitra_id = _udyogmitra_id
				  and 			tran_status_code <> 'I';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_umblock_pgid(_udyogmitra_id udd_code, _role_code udd_code, _block_code udd_code, _mobile_no udd_mobile, INOUT _result_umblockpgid refcursor DEFAULT 'rs_umblockpgid'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022
		SP Code : B04BLKG02
	*/
begin
	-- stored procedure body
	if _role_code = 'udyogmitra' then
		open _result_umblockpgid for select 	
										  pg.pg_id,
										  pg.pg_name
					  		from 		  pg_mst_tproducergroup as pg
							inner join 	  pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  			where 		  um.udyogmitra_id = _udyogmitra_id
				 		    and 		  um.tran_status_code <> 'I'
							and 		  pg.status_code <> 'I';
		else if _role_code = 'bo' then
			open _result_umblockpgid for select Distinct	
											  pg.pg_id,
											  pg.pg_name
								from 		  block_master as b
								-- CR NO : CR0001 / Resource - Emp10138 / 25-jan-2023 / CS-001
								inner join 	  pg_mst_tpanchayatmapping as pm on b.block_id = pm.block_id 
								-- CR NO : CR0001 / Resource - Emp10138 / 25-jan-2023 / CE-001
								inner join 	  pg_mst_tproducergroup as pg on pm.pg_id = pg.pg_id
								where 		  b.block_code = _block_code::udd_code 
								and 		  b.is_active = true 
								and 		  pg.status_code <> 'I';
		end if;
	end if;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_villagelist(_panchayat_id udd_int, INOUT _result_village refcursor DEFAULT 'rs_village'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 03-01-2022
		SP Code : B01VGMG01
	*/
begin
	-- stored procedure body
	open _result_village for select 	
								village_id,
								state_id,
								district_id,
								block_id,
								panchayat_id,
								village_code,
								village_name_en,
								village_name_local
				  from 			village_master
				  where 		panchayat_id = _panchayat_id
				  and 			is_active = true
				  order by 		village_name_en;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_wtom_appmst(INOUT _result_appmst refcursor DEFAULT 'rs_appmst'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 12-01-2022
		SP Code : *********
	*/
begin
	-- stored procedure body
	open _result_appmst for select 
						   dump1('public',
								 'pg_mst_tproducergroup',
								 '1=1',
								 'pg_mst_tproducergroup',
								 '{pg_id}',
								 '{}')
								union all
							select 
						    dump1( 'public',
							   'pg_mst_tproductmapping',
							   '1=1',
							   'pg_mst_tproductmapping',
							   '{pg_id,prod_code}',
							   '{}')
								union all
							select 
						    dump1( 'public',
							   'pg_mst_tudyogmitra',
							   '1=1',
							   'pg_mst_tudyogmitra',
							   '{pg_id,udyogmitra_id}',
							   '{}')
						   		 union all
							select 
						    dump1( 'public',
							   'pg_mst_tactivity',
							   '1=1',
							   'pg_mst_tactivity',
							   '{pg_id,seq_no}',
							   '{}')
								 union all
							select 
						    dump1( 'public',
							   'pg_mst_tclf',
							   '1=1',
							   'pg_mst_tclf',
							   '{pg_id,clf_officer_id}',
							   '{}')
							   	 union all
							select 
						    dump1( 'public',
							   'pg_mst_tcollectionpoint',
							   '1=1',
							   'pg_mst_tcollectionpoint',
							   '{pg_id,collpoint_no}',
							   '{}')
							     union all
							select 
						    dump1( 'public',
							   'pg_mst_tpanchayatmapping',
							   '1=1',
							   'pg_mst_tpanchayatmapping',
							   '{pg_id,panchayat_id}',
							   '{}');
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_wtom_core(INOUT _result_core refcursor DEFAULT 'rs_core'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 12-01-2022
		SP Code : *********
	*/
begin
	-- stored procedure body
	open _result_core for select 
						   dump1('public',
								 'core_mst_tlanguage',
								 '1=1',
								 'core_mst_tlanguage',
								 '{lang_code}',
								 '{}')
								union all
							select 
						    dump1( 'public',
							   'core_mst_tmaster',
							   '1=1',
							   'core_mst_tmaster',
							   '{parent_code,master_code}',
							   '{}')
								union all
							select 
						    dump1( 'public',
							   'core_mst_tmastertranslate',
							   '1=1',
							   'core_mst_tmastertranslate',
							   '{parent_code,master_code,lang_code}',
							   '{}')
						   		 union all
							select 
						    dump1( 'public',
							   'core_mst_tmessage',
							   '1=1',
							   'core_mst_tmessage',
							   '{msg_code}',
							   '{}')
								 union all
							select 
						    dump1( 'public',
							   'core_mst_tmessagetranslate',
							   '1=1',
							   'core_mst_tmessagetranslate',
							   '{msg_code,lang_code}',
							   '{}')
							   	 union all
							select 
						    dump1( 'public',
							   'core_mst_tproduct',
							   '1=1',
							   'core_mst_tproduct',
							   '{prod_code}',
							   '{}')
							     union all
							select 
						    dump1( 'public',
							   'core_mst_tproductprice',
							   '1=1',
							   'core_mst_tproductprice',
							   '{prodprice_gid}',
							   '{}')
							   	 union all
							select 
						    dump1( 'public',
							   'core_mst_tproductquality',
							   '1=1',
							   'core_mst_tproductquality',
							   '{prodqlty_gid}',
							   '{}')
							     union all
							select 
						    dump1( 'public',
							   'core_mst_tproducttranslate',
							   '1=1',
							   'core_mst_tproducttranslate',
							   '{prod_code,lang_code}',
							   '{}')
							   	  union all
							select 
						    dump1( 'public',
							   'core_mst_tscreen',
							   '1=1',
							   'core_mst_tscreen',
							   '{screen_code}',
							   '{}')
							   	  union all
							select 
						    dump1( 'public',
							   'core_mst_tscreendata',
							   '1=1',
							   'core_mst_tscreendata',
							   '{screen_code,ctrl_id,lang_code}',
							   '{}');
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_get_wtom_lokos(INOUT _result_lokos refcursor DEFAULT 'rs_lokos'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 12-01-2022
		SP Code : *********
	*/
begin
	-- stored procedure body
	open _result_lokos for select 
						   dump1('public',
								 'pg_bank_branch_view',
								 '1=1',
								 'pg_bank_branch',
								 '{bank_branch_id}',
								 '{}')
								union all
							select 
						    dump1( 'public',
							   'pg_location_view',
							   '1=1',
							   'pg_location',
							   '{village_id}',
							   '{}')
								union all
							select 
						    dump1( 'public',
							   'shgmember_profile_view',
							   '1=1',
							   'shgmember_profile',
							   '{shg_member_id}',
							   '{}')
						   		 union all
							select 
						    dump1( 'public',
							   'shgmember_bank_view',
							   '1=1',
							   'shgmember_bank',
							   '{shg_member_id,bank_code,account_no}',
							   '{}')
								 union all
							select 
						    dump1( 'public',
							   'shgmember_addressdesc_view',
							   '1=1',
							   'shgmember_address',
							   '{member_address_id,state_id}',
							   '{}');
							   
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bankbranchmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B04BBMCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	

begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											bank_branch_id	 bigint,
											bank_id 		 integer,
											bank_code 		 varchar(10),
											bank_branch_code integer,
											bank_branch_name varchar(200),
											ifsc_code 		 varchar(20),
											bank_branch_address varchar(255),
											rural_urban_branch  varchar(1),
											village_id		 integer,
											block_id		 integer,
											district_id		 integer,
											state_id		 integer,
											pincode			 varchar(6),
											branch_merged_with	integer,
											is_active 		 boolean,
											created_date 	 text,
											created_by 		 integer,
											updated_date 	 text,
											updated_by 		 integer,
											entity_code		 varchar(30)									
										)
		  loop
		  	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
		  	  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  		  		
		      insert into bank_branch_master(
			  								bank_branch_id,
											bank_id,
											bank_code,
											bank_branch_code,
											bank_branch_name,
											ifsc_code,
											bank_branch_address,
											rural_urban_branch,
											village_id,
											block_id,
											district_id,
											state_id,
											pincode,
											branch_merged_with,
											is_active,
											created_date,
											created_by,
											updated_date,
											updated_by,
											entity_code 
			  							)
								values  (											
			  								v_colrec.bank_branch_id,
											v_colrec.bank_id,
											v_colrec.bank_code,
											v_colrec.bank_branch_code,
											v_colrec.bank_branch_name,
											v_colrec.ifsc_code,
											v_colrec.bank_branch_address,
											v_colrec.rural_urban_branch,
											v_colrec.village_id,
											v_colrec.block_id,
											v_colrec.district_id,
											v_colrec.state_id,
											v_colrec.pincode,
											v_colrec.branch_merged_with,
											v_colrec.is_active,
											v_created_date,
											v_colrec.created_by,
											v_updated_date,
											v_colrec.updated_by,
											v_colrec.entity_code
								       )
										
				on conflict (
								bank_branch_id
							)
							do update set   bank_branch_id			= v_colrec.bank_branch_id,
											bank_id					= v_colrec.bank_id,
											bank_code				= v_colrec.bank_code,
											bank_branch_code		= v_colrec.bank_branch_code,
											bank_branch_name		= v_colrec.bank_branch_name,
											ifsc_code				= v_colrec.ifsc_code,
											bank_branch_address		= v_colrec.bank_branch_address,
											rural_urban_branch		= v_colrec.rural_urban_branch,
											village_id				= v_colrec.village_id,
											block_id				= v_colrec.block_id,
											district_id				= v_colrec.district_id,
											state_id				= v_colrec.state_id,
											pincode					= v_colrec.pincode,
											branch_merged_with		= v_colrec.branch_merged_with,
											is_active				= v_colrec.is_active,
											updated_date			= v_updated_date,
											updated_by				= v_colrec.updated_by,
											entity_code 			= v_colrec.entity_code;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bankmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B04BAMCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											bank_id 		 integer,
											language_id 	 varchar(2),
											bank_code 		 varchar(10),
											bank_name 		 varchar(100),
											bank_shortname 	 varchar(20),
											bank_type 		 smallint,
											ifsc_mask 		 varchar(11),
											bank_merged_with varchar(20),
											bank_level 	     smallint,
											is_active 		 smallint,
											created_date 	 text,
											created_by 		 integer,
											updated_date 	 text,
											updated_by 		 integer,
											bank_account_len varchar(20)									
										)
		  loop
		  	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
		  	  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  		  
		      insert into bank_master  (
			  								bank_id,
											language_id,
											bank_code,
											bank_name,
											bank_shortname,
											bank_type,
											ifsc_mask,
											bank_merged_with,
											bank_level,
											is_active,
											created_date,
											created_by,
											updated_date,
											updated_by,
											bank_account_len 
			  							)
								values  (											
			  								v_colrec.bank_id,
											v_colrec.language_id,
											v_colrec.bank_code,
											v_colrec.bank_name,
											v_colrec.bank_shortname,
											v_colrec.bank_type,
											v_colrec.ifsc_mask,
											v_colrec.bank_merged_with,
											v_colrec.bank_level,
											v_colrec.is_active,
											v_created_date,
											v_colrec.created_by,
											v_updated_date,
											v_colrec.updated_by,
											v_colrec.bank_account_len
								       )
										
				on conflict (
								bank_id
							)
							do update set   bank_id				=	v_colrec.bank_id,
											language_id			=	v_colrec.language_id,
											bank_code			=	v_colrec.bank_code,
											bank_name			=	v_colrec.bank_name,
											bank_shortname		=	v_colrec.bank_shortname,
											bank_type			=	v_colrec.bank_type,
											ifsc_mask			=	v_colrec.ifsc_mask,
											bank_merged_with	=	v_colrec.bank_merged_with,
											bank_level			=	v_colrec.bank_level,
											is_active			=	v_colrec.is_active,
											updated_date		=	v_updated_date,
											updated_by			=	v_colrec.updated_by,
											bank_account_len	=	v_colrec.bank_account_len;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_blockmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Mohan s
		Created Date : 24-03-2022
		SP Code : B01BKMCUX
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														block_id integer,
														state_id integer,
														district_id integer,
														block_code varchar(7),
														block_name_en varchar(100),
														block_name_local varchar(200),
														block_short_name_en varchar(20),
														block_short_name_local varchar(40),
														rural_urban_area varchar(1),
														language_id varchar(2),
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
				
				insert into block_master (
											block_id,
											state_id,
											district_id,
											block_code,
											block_name_en,
											block_name_local,
											block_short_name_en,
											block_short_name_local,
											rural_urban_area,
											language_id,
											is_active,
											created_date,
											created_by,
											updated_date,
											updated_by)
					values              (
											v_colrec.block_id,
											v_colrec.state_id,
											v_colrec.district_id,
											v_colrec.block_code,
											v_colrec.block_name_en,
											v_colrec.block_name_local,
											v_colrec.block_short_name_en,
											v_colrec.block_short_name_local,
											v_colrec.rural_urban_area,
											v_colrec.language_id,
											v_colrec.is_active,
											v_created_date,
											v_colrec.created_by,
											v_updated_date,
											v_colrec.updated_by)
							
		on CONFLICT ( block_id )  do update set  
											block_id = v_colrec.block_id,
											state_id = v_colrec.state_id,
											district_id = v_colrec.district_id,
											block_code = v_colrec.block_code,
											block_name_en = v_colrec.block_name_en,
											block_name_local = v_colrec.block_name_local,
											block_short_name_en = v_colrec.block_short_name_en,
											rural_urban_area = v_colrec.rural_urban_area,
											language_id = v_colrec.language_id,
											is_active = v_colrec.is_active,
											updated_date = v_updated_date,
											updated_by = v_colrec.updated_by;
		END LOOP;
		open result_succ_msg for select 	
   			'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplan(INOUT _bussplan_gid udd_int, INOUT _pg_id udd_code, _blockofficer_id udd_code, INOUT _bussplan_id udd_code, _period_from udd_date, _period_to udd_date, _reviewer_type_code udd_code, _clf_block_id udd_int, _reviewer_code udd_code, _reviewer_name udd_desc, _bussplan_review_flag udd_flag, _bussplan_remark udd_text, _ops_exp_amount udd_amount, _net_pl_amount udd_amount, _fundreq_id udd_code, _last_action_date udd_datetime, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, _row_timestamp udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 23-12-2021
		SP Code : B04BUPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_seqno udd_int := 0;
	v_pg_name udd_code := '';
	v_from_date udd_date := null;
	v_to_date udd_date := null;
	v_count_month udd_int := 0;
	v_status_code udd_code := '';
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- blockofficer cannot be blank
	if _blockofficer_id = '' then
		v_err_code := v_err_code || 'VB04BUPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- period from cannot be blank
	if _period_from is Null then
		v_err_code := v_err_code || 'VB04BUPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- period to cannot be blank
	if _period_to is Null then
		v_err_code := v_err_code || 'VB04BUPCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- period to validation
	if _period_to < _period_from then
		v_err_code := v_err_code || 'EB04BUPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BUPCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- period from cannot be past date
	if _status_code <> 'A' then
		if _period_from < (now() :: udd_date) then
				v_err_code := v_err_code || 'VB04BUPCUD_012' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_012', _lang_code)|| v_new_line;					
		end if ;
	end if ;
	
	-- period to cannot be past date
	if _period_to < (now() :: udd_date)
	then
			v_err_code := v_err_code || 'VB04BUPCUD_013' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_013', _lang_code)|| v_new_line;					
	end if ;
	
	select EXTRACT(year FROM age(_period_to, _period_from))*12 
	+ EXTRACT(month FROM age(_period_to, _period_from)) into v_count_month;
	
	-- 3 years validaion
	if v_count_month > 36 then
			v_err_code := v_err_code || 'VB04BUPCUD_014' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_014', _lang_code) || v_new_line;
	end if;
	
	-- reviewer type code invalid
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_REVIEWER_TYPE'
				   and 		master_code = _reviewer_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BUPCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_006', _lang_code) || v_new_line;	
	end if;
	
	/*if _reviewer_type_code = 'QCD_CLF' then
		-- clf block id cannot be blank
		if _clf_block_id <= 0 then
			v_err_code := v_err_code || 'VB04BUPCUD_007' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_007', _lang_code) || v_new_line;
		end if;
	end if;*/
	
	-- reviewer code cannot be blank
	if _reviewer_code = '' then
		v_err_code := v_err_code || 'VB04BUPCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_008', _lang_code) || v_new_line;
	end if;
	
	-- reviewer name cannot be blank
	if _reviewer_name = '' then
		v_err_code := v_err_code || 'VB04BUPCUD_010' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_010', _lang_code) || v_new_line;
	end if;
	
	-- bussplan reviewflag cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _bussplan_review_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BUPCUD_009' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_009', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan review flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _bussplan_review_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01QCMCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCMCUD_005', _lang_code) || v_new_line;	
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code)|| v_new_line;		
	end if;
	
	-- getting existing status_code 
	select status_code into v_status_code 
	from   pg_trn_tbussplan
	where  pg_id 		= _pg_id
	and    bussplan_id  = _bussplan_id;
	 
    v_status_code := coalesce(v_status_code,'');

	if v_status_code = 'D' then
		if _status_code = 'S' then
			if _period_from < now()::udd_date then
				v_err_code := v_err_code || 'VB04BUPCUD_012' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_012', _lang_code)|| v_new_line;					
			end if ;
		end if;
	end if;
	
	--Attachment Validation 
	if _status_code = 'S' then
		if not exists (	select '*' from pg_trn_tbussplanattachment
						where 	pg_id 		= _pg_id
						and  	bussplan_id = _bussplan_id
					  ) then
			v_err_code := v_err_code || 'VB04BUPCUD_011' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_011', _lang_code)|| v_new_line;					
		end if ;
	end if ;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	-- timestamp check for concurrency
	select 	to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') into v_timestamp 
	from 	pg_trn_tbussplan
	where	bussplan_gid = _bussplan_gid;
	
	v_timestamp	:= coalesce(v_timestamp, '');
	
	IF (v_timestamp != _row_timestamp) 
	then
		-- Record modified since last fetch so Kindly refetch and continue
		v_err_code := v_err_code || 'VB00CMNCMN_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_002', _lang_code) || v_new_line;	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _bussplan_gid <> 0 then
		_mode_flag := 'U';
	end if;
	
	if _mode_flag = 'U' then
	
		delete from pg_trn_tbussplanproduce
		where 	 pg_id = _pg_id
		and 	 bussplan_id = _bussplan_id
		and 	 produce_month < _period_from - INTERVAL '1 MONTH' + INTERVAL '1 day';
		
		delete from pg_trn_tbussplanproduce
		where 	 pg_id = _pg_id
		and 	 bussplan_id = _bussplan_id
		and 	 produce_month > _period_to;
		
		v_from_date := _period_from::date  - INTERVAL '1 year';
		v_to_date 	:= _period_to::date  + INTERVAL '1 year';
		
		delete   from pg_trn_tbussplanfinyear
		where 	 pg_id = _pg_id
		and 	 bussplan_id = _bussplan_id
		and		 finyear_id not in (select a.finyear_id from (	 select 	finyear_id 
																 from 	core_mst_tfinyear 
																 where 	finyear_start_date > v_from_date
																 and 	status_code = 'A') as a 
								 inner join (select  finyear_id 
								 from 	core_mst_tfinyear 
								 where 	finyear_end_date < v_to_date
								 and 	status_code = 'A') as b on a.finyear_id = b.finyear_id );
								 
		delete from pg_trn_tbussplanexpenses
		where 	 pg_id = _pg_id
		and 	 bussplan_id = _bussplan_id
		and 	 finyear_id not in (select a.finyear_id from (	 select 	finyear_id 
																 from 	core_mst_tfinyear 
																 where 	finyear_start_date > v_from_date
																 and 	status_code = 'A') as a 
								 inner join (select  finyear_id 
								 from 	core_mst_tfinyear 
								 where 	finyear_end_date < v_to_date
								 and 	status_code = 'A') as b on a.finyear_id = b.finyear_id );
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tbussplan
				  where 	bussplan_gid = _bussplan_gid
				  and 		pg_id = _pg_id
				  and 		status_code <> 'I'
				 ) then
			Update 	pg_trn_tbussplan
			set		status_code = 'I',
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	bussplan_gid = _bussplan_gid
			and 	status_code <> 'I';
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tbussplan
					  where		bussplan_gid = _bussplan_gid
					  and 		pg_id = _pg_id 
					  and 		bussplan_id = _bussplan_id 
					  and 		status_code = 'A'
					 ) then
					  
			insert into pg_trn_tbussplan 
			(
				pg_id,
				blockofficer_id,
				bussplan_id,
				period_from,
				period_to,
				reviewer_type_code,
				clf_block_id,
				reviewer_code,
				reviewer_name,
				bussplan_review_flag,
				bussplan_remark,
				ops_exp_amount,
				net_pl_amount,
				fundreq_id,
				last_action_date,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				_pg_id,
				_blockofficer_id,
				_bussplan_id,
				_period_from,
				_period_to,
				_reviewer_type_code,
				_clf_block_id,
				_reviewer_code,
				_reviewer_name,
				_bussplan_review_flag,
				_bussplan_remark,
				_ops_exp_amount,
				_net_pl_amount,
				_fundreq_id,
				now(),
				_status_code,
				_user_code,
				now(),
				now()
			) returning bussplan_gid into _bussplan_gid;
			
			v_succ_code := 'SB04BUPCUD_001';
			
			--BP id generation
			-- select fn_get_docseqno('BPID') into v_seqno ;
			select upper(substring(pg_name,1,2)) into v_pg_name
			from pg_mst_tproducergroup where pg_id = _pg_id;
			select CONCAT(upper(substring 
								 (regexp_replace(v_pg_name collate pg_catalog.""default"", '[^a-zA-Z]', '', 'g')
								  ,1,2)),
						  case 
								when length(_bussplan_gid::udd_text)>5 then _bussplan_gid::udd_text 
						  else 
						  to_char(_bussplan_gid,'fm00000') end) into _bussplan_id ;
						  
			update 	pg_trn_tbussplan 
			set 	bussplan_id  = _bussplan_id
			where 	bussplan_gid = _bussplan_gid;
			
			-- PG ID and BUSS plan ID value Setted
			select	 pg_id,bussplan_id 
			into 	_pg_id,_bussplan_id
			from 	 pg_trn_tbussplan
			where 	 pg_id = _pg_id
			and      bussplan_id = _bussplan_id;
						
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tbussplan
				   where	bussplan_gid = _bussplan_gid
				   and 		status_code <> 'I'
				   ) then
			update	pg_trn_tbussplan 
			set 	pg_id = _pg_id,
					blockofficer_id = _blockofficer_id,
				    bussplan_id = _bussplan_id,
					period_from = _period_from,
					period_to = _period_to,
					reviewer_type_code = _reviewer_type_code,
					clf_block_id = _clf_block_id,
					reviewer_code = _reviewer_code,
					reviewer_name = _reviewer_name,
					bussplan_review_flag = _bussplan_review_flag,
					bussplan_remark = _bussplan_remark,
-- 					ops_exp_amount = _ops_exp_amount,
					net_pl_amount = _net_pl_amount,
					fundreq_id = _fundreq_id,
					last_action_date = now(),
					status_code = _status_code,
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	bussplan_gid = _bussplan_gid
			and 	status_code <> 'I';
			
			v_succ_code := 'SB04BUPCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_trn_tbussplan
			    where 	bussplan_id = _bussplan_id 
				group	by bussplan_id
				having	count('*') > 1) 
	then
		-- buss plan id cannot be duplicated
		v_err_code := v_err_code || 'EB04BUPCUD_003';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04BUPCUD_003', _lang_code),_bussplan_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		 if _status_code = 'D' then
				v_succ_code := 'SB04BUPCUD_001';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
			elseif _status_code = 'R' then
				v_succ_code := 'SB04BUPCUD_003';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
			elseif _status_code = 'S' then
				v_succ_code := 'SB04BUPCUD_004';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
			elseif _status_code = 'A' then
				v_succ_code := 'SB04BUPCUD_005';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
		 end if;
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanattachment(INOUT _bussplanattachment_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _doc_type_code udd_code, _doc_subtype_code udd_code, _file_path udd_text, _file_name udd_desc, _attachment_remark udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 24-12-2021
		SP Code : B04BPACUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_bussplan_id udd_code := '';
	v_pg_id udd_code := '';v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id cannot be blank
	if _pg_id = '' then
		v_err_code := v_err_code || 'VB04BPACUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPACUD_001', _lang_code) || v_new_line;
	end if;
	
	select 		pg_id into v_pg_id 
	from 		pg_mst_tproducergroup
	where 		pg_id = _pg_id;
	
	-- pg id invalid check
	if v_pg_id = '' or v_pg_id is Null  then
		v_err_code := v_err_code || 'EB04BPACUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BPACUD_001', _lang_code) || v_new_line;
	end if;
	
	select 		bussplan_id into v_bussplan_id 
	from 		pg_trn_tbussplan
	where 		bussplan_id = _bussplan_id
	and 		pg_id = _pg_id;
	
	-- bussplan id invalid check
	if v_bussplan_id = '' or v_bussplan_id is Null  then
		v_err_code := v_err_code || 'VB04BPACUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPACUD_002', _lang_code) || v_new_line;
	end if;
	
	-- Doctype code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where	parent_code = 'QCD_DOC_TYPE'
				   and 		master_code = _doc_type_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPACUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPACUD_003', _lang_code) || v_new_line;
	end if;	
	
	-- DocSubtype code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where	parent_code = 'QCD_DOC_SUBTYPE'
				   and 		master_code = _doc_subtype_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPACUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPACUD_004', _lang_code) || v_new_line;
	end if;	
	
	-- filepath cannot be balnk
	if _file_path = '' then
		v_err_code := v_err_code || 'VB04BPACUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPACUD_005', _lang_code) || v_new_line;
	end if;
	
	-- filename cannot be balnk
	if _file_name = '' then
		v_err_code := v_err_code || 'VB04BPACUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPACUD_006', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tbussplanattachment
				  where 	bussplanattachment_gid = _bussplanattachment_gid
				 ) then
				 
			delete   from 	pg_trn_tbussplanattachment
			where 	bussplanattachment_gid = _bussplanattachment_gid;
			
			v_succ_code := 'SB04BPACUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tbussplanattachment
					  where		bussplanattachment_gid = _bussplanattachment_gid
					 ) then
			insert into pg_trn_tbussplanattachment 
			(
				pg_id,
				bussplan_id,
				doc_type_code,
				doc_subtype_code,
				file_path,
				file_name,
				attachment_remark,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_doc_type_code,
				_doc_subtype_code,
				_file_path,
				_file_name,
				_attachment_remark,
				_user_code,
				now()
			) returning bussplanattachment_gid into _bussplanattachment_gid;
			
			v_succ_code := 'SB04BPACUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tbussplanattachment
				   where	bussplanattachment_gid = _bussplanattachment_gid
				   ) then
			update	pg_trn_tbussplanattachment 
			set 	pg_id = _pg_id,
					--bussplan_id = _bussplan_id,
					doc_type_code = _doc_type_code,
					doc_subtype_code = _doc_subtype_code,
					file_path = _file_path,
					file_name = _file_name,
					attachment_remark = _attachment_remark,
					updated_by = _user_code,
					updated_date = now()
			where 	bussplanattachment_gid = _bussplanattachment_gid;
			
			v_succ_code := 'SB04BPACUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplancommodity(INOUT _bussplanprod_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _prod_type_code udd_code, _prod_code udd_code, _jan_sowing_flag udd_flag, _jan_harvesting_qty udd_qty, _feb_sowing_flag udd_flag, _feb_harvesting_qty udd_qty, _mar_sowing_flag udd_flag, _mar_harvesting_qty udd_qty, _apr_sowing_flag udd_flag, _apr_harvesting_qty udd_qty, _may_sowing_flag udd_flag, _may_harvesting_qty udd_qty, _jun_sowing_flag udd_flag, _jun_harvesting_qty udd_qty, _jul_sowing_flag udd_flag, _jul_harvesting_qty udd_qty, _aug_sowing_flag udd_flag, _aug_harvesting_qty udd_qty, _sep_sowing_flag udd_flag, _sep_harvesting_qty udd_qty, _oct_sowing_flag udd_flag, _oct_harvesting_qty udd_qty, _nov_sowing_flag udd_flag, _nov_harvesting_qty udd_qty, _dec_sowing_flag udd_flag, _dec_harvesting_qty udd_qty, _lang_code udd_code, _user_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 22-01-2022
		SP Code : B04BPCCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';

begin	
	-- validation
	-- pg id cannot be blank 
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'EB04BPPCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BPPCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- prod code cannot be blank
	if _prod_code = '' then
		v_err_code := v_err_code || 'VB04BPPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- prod code validation
	if not exists (select 	* 
				   from 	core_mst_tproduct 
				   where 	prod_code = _prod_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'EB04BPPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BPPCUD_002', _lang_code) || v_new_line;	
	end if;
	
	-- prod type code validation
	if(_prod_type_code = '')then 
		select 		prod_type_code into _prod_type_code
		from 		core_mst_tproduct 
		where 		prod_code = _prod_code
	    and 		status_code = 'A';
		
	else
		if not exists (select 		*
						from 		core_mst_tproduct
						where 		prod_type_code = _prod_type_code
					    and         prod_code = _prod_code
	    				and 		status_code = 'A')then
		v_err_code := v_err_code || 'EB04BPPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BPPCUD_003', _lang_code) || v_new_line;
		end if;
	end if;
			
	-- jansowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _jan_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_004', _lang_code) || v_new_line;	
	end if;
	
	-- janharvesting qty validation
	if _jan_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- febsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _feb_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_006', _lang_code) || v_new_line;	
	end if;
	
	-- febharvesting qty validation
	if _feb_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_007', _lang_code) || v_new_line;
	end if;
	
	-- marsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _mar_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_008', _lang_code) || v_new_line;	
	end if;
	
	-- marharvesting qty validation
	if _mar_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_009' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_009', _lang_code) || v_new_line;
	end if;
	
	-- aprsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _apr_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_010' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_010', _lang_code) || v_new_line;	
	end if;
	
	-- aprharvesting qty validation
	if _apr_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_011' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_011', _lang_code) || v_new_line;
	end if;
	
	-- maysowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _may_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_012' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_012', _lang_code) || v_new_line;	
	end if;
	
	-- mayharvesting qty validation
	if _may_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_013', _lang_code) || v_new_line;
	end if;
	
	-- junsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _jun_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_014' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_014', _lang_code) || v_new_line;	
	end if;
	
	-- junharvesting qty validation
	if _jun_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_015', _lang_code) || v_new_line;
	end if;
	
	-- julsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _jul_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_016' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_016', _lang_code) || v_new_line;	
	end if;
	
	-- julharvesting qty validation
	if _jul_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_017', _lang_code) || v_new_line;
	end if;
	
	-- augsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _aug_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_018' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_018', _lang_code) || v_new_line;	
	end if;
	
	-- augharvesting qty validation
	if _aug_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_019' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_019', _lang_code) || v_new_line;
	end if;
	
	-- sepsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _sep_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_020' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_020', _lang_code) || v_new_line;	
	end if;
	
	-- sepharvesting qty validation
	if _sep_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_021' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_021', _lang_code) || v_new_line;
	end if;
	
	-- octsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _oct_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_022', _lang_code) || v_new_line;	
	end if;
	
	-- octharvesting qty validation
	if _oct_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_023' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_023', _lang_code) || v_new_line;
	end if;
	
	-- novsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _nov_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_024' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_024', _lang_code) || v_new_line;	
	end if;
	
	-- novharvesting qty validation
	if _nov_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_025' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_025', _lang_code) || v_new_line;
	end if;

	-- decsowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _dec_sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_026' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_026', _lang_code) || v_new_line;	
	end if;
	
	-- decharvesting flag validation
	if _dec_harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_027' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_027', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
			insert into pg_trn_tbussplanproduct 
			(
				pg_id,
				bussplan_id,
				prod_type_code,
				prod_code,
				jan_sowing_flag,
				jan_harvesting_qty,
				feb_sowing_flag,
				feb_harvesting_qty,
				mar_sowing_flag,
				mar_harvesting_qty,
				apr_sowing_flag,
				apr_harvesting_qty,
				may_sowing_flag,
				may_harvesting_qty,
				jun_sowing_flag,
				jun_harvesting_qty,
				jul_sowing_flag,
				jul_harvesting_qty,
				aug_sowing_flag,
				aug_harvesting_qty,
				sep_sowing_flag,
				sep_harvesting_qty,
				oct_sowing_flag,
				oct_harvesting_qty,
				nov_sowing_flag,
				nov_harvesting_qty,
				dec_sowing_flag,
				dec_harvesting_qty,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_prod_type_code,
				_prod_code,
				_jan_sowing_flag,
				_jan_harvesting_qty,
				_feb_sowing_flag,
				_feb_harvesting_qty,
				_mar_sowing_flag,
				_mar_harvesting_qty,
				_apr_sowing_flag,
				_apr_harvesting_qty,
				_may_sowing_flag,
				_may_harvesting_qty,
				_jun_sowing_flag,
				_jun_harvesting_qty,
				_jul_sowing_flag,
				_jul_harvesting_qty,
				_aug_sowing_flag,
				_aug_harvesting_qty,
				_sep_sowing_flag,
				_sep_harvesting_qty,
				_oct_sowing_flag,
				_oct_harvesting_qty,
				_nov_sowing_flag,
				_nov_harvesting_qty,
				_dec_sowing_flag,
				_dec_harvesting_qty,
				_user_code,
				now()
			) on CONFLICT (pg_id,bussplan_id,prod_code) do update 
					set  	pg_id = _pg_id,
							bussplan_id = _bussplan_id,
							prod_type_code = _prod_type_code,
							prod_code = _prod_code,
							jan_sowing_flag = _jan_sowing_flag,
							jan_harvesting_qty = _jan_harvesting_qty,
							feb_sowing_flag = _feb_sowing_flag,
							feb_harvesting_qty = _feb_harvesting_qty,
							mar_sowing_flag = _mar_sowing_flag,
							mar_harvesting_qty = _mar_harvesting_qty,
							apr_sowing_flag = _apr_sowing_flag,
							apr_harvesting_qty = _apr_harvesting_qty,
							may_sowing_flag = _may_sowing_flag,
							may_harvesting_qty = _may_harvesting_qty,
							jun_sowing_flag = _jun_sowing_flag,
							jun_harvesting_qty = _jun_harvesting_qty,
							jul_sowing_flag = _jul_sowing_flag,
							jul_harvesting_qty = _jul_harvesting_qty,
							aug_sowing_flag = _aug_sowing_flag,
							aug_harvesting_qty = _aug_harvesting_qty,
							sep_sowing_flag = _sep_sowing_flag,
							sep_harvesting_qty = _sep_harvesting_qty,
							oct_sowing_flag = _oct_sowing_flag,
							oct_harvesting_qty = _oct_harvesting_qty,
							nov_sowing_flag = _nov_sowing_flag,
							nov_harvesting_qty = _nov_harvesting_qty,
							dec_sowing_flag = _dec_sowing_flag,
							dec_harvesting_qty = _dec_harvesting_qty,
							updated_by = _user_code,
							updated_date = now()
							
			returning bussplanprod_gid into _bussplanprod_gid;
			
			v_succ_code := 'SB00CMNCMN_001';
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplandownloadlog(INOUT _bussplandownloadlog_gid udd_int, _bussplanattachment_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _downloaded_date udd_date, _downloaded_by udd_code, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 19-01-2022
		SP Code : B04BPDCRE
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
			insert into pg_trn_tbussplandownloadlog 
			(
				bussplanattachment_gid,
				pg_id,
				bussplan_id,
				downloaded_date,
				downloaded_by
			)
			values
			(
				_bussplanattachment_gid,
				_pg_id,
				_bussplan_id,
				now()::timestamp,
				_downloaded_by
				
			) returning bussplandownloadlog_gid into _bussplandownloadlog_gid;
			
			v_succ_code := 'SB00CMNCMN_001';
			
			if(v_succ_code <> '' )then
				_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
			end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanexpenses(INOUT _bussplanexpenses_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _finyear_id udd_code, _operating_expenses udd_amount, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 08-03-2021
		SP Code : B04BEXCUX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_018' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_018', _lang_code) || v_new_line;	
	end if;
	
	-- Finyear id validation
	if not exists (select 	* 
				   from 	core_mst_tfinyear 
				   where 	finyear_id  = _finyear_id
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BEXCUX_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BEXCUX_002', _lang_code) || v_new_line;	
	end if;
	
	-- ope amount validation
	if _operating_expenses < 0 then 
		v_err_code := v_err_code || 'VB04BEXCUX_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BEXCUX_003', _lang_code) || v_new_line;	
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if ( _mode_flag = 'I' ) then
	
		if not exists(select 	* 
					  from		pg_trn_tbussplanexpenses
					  where		pg_id = _pg_id 
					  and 		bussplan_id = _bussplan_id
					  and 		finyear_id = _finyear_id
					 ) then
			insert into pg_trn_tbussplanexpenses 
			(
				pg_id,
				bussplan_id,
				finyear_id,
				operating_expenses,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_finyear_id,
				_operating_expenses,
				_user_code,
				now()
			) returning bussplanexpenses_gid into _bussplanexpenses_gid;
			
			v_succ_code := 'SB04BEXCUX_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tbussplanexpenses
				   where		 bussplanexpenses_gid = _bussplanexpenses_gid
				   and 			 pg_id = _pg_id )
		then 
		update pg_trn_tbussplanexpenses
		set		pg_id					= _pg_id,
				bussplan_id	    		= _bussplan_id,
				finyear_id 	    		= _finyear_id,
				operating_expenses		= _operating_expenses,
				updated_date			= now(),
				updated_by				= _user_code
		where   bussplanexpenses_gid    = _bussplanexpenses_gid;
		
		v_succ_code	:= 'SB04BEXCUX_002';
		
		else
			 v_err_code := v_err_code || 'EB00CMNCMN_003';
			 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	

				RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_trn_tbussplanexpenses
			    where 	pg_id = _pg_id
			    and 	bussplan_id = _bussplan_id
			   	and     finyear_id = _finyear_id
				group	by pg_id,bussplan_id,finyear_id
				having	count('*') > 1) 
	then
		-- Duplicated Validation
		v_err_code := v_err_code || 'E04BEXCUX_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('E04BEXCUX_001', _lang_code),_finyear_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanexpensesjson(_bussplanexpenses udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 08-03-2022
		SP Code : B04BEXCUX
	*/
	
	v_colrec record;

begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_bussplanexpenses::udd_jsonb) as items 
													(
														bussplanexpenses_gid udd_int,
														pg_id udd_code,
														bussplan_id udd_code,
														finyear_id udd_code,
														operating_expenses udd_amount,
														lang_code udd_code,
														user_code udd_code,
														mode_flag udd_flag,
														succ_msg udd_text
														) 
												
			LOOP 
			
			call pr_iud_bussplanexpenses(
									   v_colrec.bussplanexpenses_gid,
									   v_colrec.pg_id,
									   v_colrec.bussplan_id,
									   v_colrec.finyear_id,
									   v_colrec.operating_expenses,
									   v_colrec.lang_code,
									   v_colrec.user_code,
									   v_colrec.mode_flag,
									   v_colrec.succ_msg);
			
			END LOOP;
			
	select 'Bussplan Expenses Created Successfully' into _succ_msg;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanfinproj(INOUT _bussplanprod_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _prod_type_code udd_code, _prod_code udd_code, _revenue_amount udd_amount, _procure_amount udd_amount, _prod_rate udd_rate, _lang_code udd_code, _user_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S 
		Created Date : 22-01-2022 
		SP Code : B04BPFCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id cannot be blank 
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'EB04BPPCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BPPCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- prod code cannot be blank
	if _prod_code = '' then
		v_err_code := v_err_code || 'VB04BPPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- prod code validation
	if not exists (select 	* 
				   from 	core_mst_tproduct 
				   where 	prod_code = _prod_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'EB04BPPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BPPCUD_002', _lang_code) || v_new_line;	
	end if;
	
	-- prod type code validation
	if(_prod_type_code = '')then 
		select 		prod_type_code into _prod_type_code
		from 		core_mst_tproduct 
		where 		prod_code = _prod_code
	    and 		status_code = 'A';
		
	else
		if not exists (select 		*
						from 		core_mst_tproduct
						where 		prod_type_code = _prod_type_code
					    and         prod_code = _prod_code
	    				and 		status_code = 'A')then
		v_err_code := v_err_code || 'EB04BPPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BPPCUD_003', _lang_code) || v_new_line;
		end if;
	end if;
	
	-- revenue amount validation
	if _revenue_amount < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_028' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_028', _lang_code) || v_new_line;
	end if;
	
	-- procure amount validation
	if _procure_amount < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_029' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_029', _lang_code) || v_new_line;
	end if;
	
	-- prod rate validation
	if _prod_rate < 0 then
		v_err_code := v_err_code || 'VB04BPPCUD_030' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_030', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
			insert into pg_trn_tbussplanproduct 
			(
				pg_id,
				bussplan_id,
				prod_type_code,
				prod_code,
				revenue_amount,
				procure_amount,
				prod_rate,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_prod_type_code,
				_prod_code,
				_revenue_amount,
				_procure_amount,
				_prod_rate,
				_user_code,
				now()
			) on CONFLICT (pg_id,bussplan_id,prod_code) do update 
					set  	pg_id = _pg_id,
							bussplan_id = _bussplan_id,
							prod_type_code = _prod_type_code,
							prod_code = _prod_code,
							revenue_amount = _revenue_amount,
							procure_amount = _procure_amount,
							prod_rate = _prod_rate,
							updated_by = _user_code,
							updated_date = now()
							
			returning bussplanprod_gid into _bussplanprod_gid;
			
			v_succ_code := 'SB00CMNCMN_002';
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanfinyear(INOUT _bussplancalender_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _finyear_id udd_code, _prod_type_code udd_code, _prod_code udd_code, _uom_code udd_code, _prod_rate udd_rate, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 15-02-2021
		SP Code : B04BPFCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FDBCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_018' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_018', _lang_code) || v_new_line;	
	end if;
	
	-- prod code validation
	if not exists (select 	* 
				   from 	core_mst_tproduct 
				   where 	prod_code = _prod_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_016', _lang_code) || v_new_line;	
	end if;
	
	-- prod type code validation
	if(_prod_type_code = '')then 
		select 		prod_type_code into _prod_type_code
		from 		core_mst_tproduct 
		where 		prod_code = _prod_code
	    and 		status_code = 'A';
		
	else
		if not exists (select 		*
						from 		core_mst_tproduct
						where 		prod_type_code = _prod_type_code
					    and         prod_code = _prod_code
	    				and 		status_code = 'A')then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;
		end if;
	end if;
	
	-- uom code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_UOM'
				   and 		master_code = _uom_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_019' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_019', _lang_code)|| v_new_line;	
	end if;
	
	-- finyear id validation 
	if not exists (select   * 
				   from 	core_mst_tfinyear
				   where 	finyear_id = _finyear_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB04BPFCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPFCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- prod rate validation
	if _prod_rate <= 0 then
		v_err_code := v_err_code || 'VB04BPFCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPFCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tbussplanfinyear
				  where 	bussplancalender_gid = _bussplancalender_gid
				  and 		pg_id = _pg_id
				 ) then
				 
			delete   from 	pg_trn_tbussplanfinyear
			where 	bussplancalender_gid = bussplancalender_gid;
			
			v_succ_code := 'SB04BPFCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tbussplanfinyear
					  where		bussplancalender_gid = _bussplancalender_gid
					  and 		pg_id = _pg_id 
					 ) then
			insert into pg_trn_tbussplanfinyear 
			(
				pg_id,
				bussplan_id,
				finyear_id,
				prod_type_code,
				prod_code,
				uom_code,
				prod_rate,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_finyear_id,
				_prod_type_code,
				_prod_code,
				_uom_code,
				_prod_rate,
				_user_code,
				now()
			) returning bussplancalender_gid into _bussplancalender_gid;
			
			v_succ_code := 'SB04BPFCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tbussplanfinyear
				   where	bussplancalender_gid = _bussplancalender_gid
				   ) then
			update	pg_trn_tbussplanfinyear 
			set 	pg_id = _pg_id,
					bussplan_id = _bussplan_id,
					finyear_id = _finyear_id,
					prod_type_code = _prod_type_code,
					prod_code = _prod_code,
					uom_code = _uom_code,
					prod_rate = _prod_rate,
					updated_by = _user_code,
					updated_date = now()
			where 	bussplancalender_gid = _bussplancalender_gid;
			
			v_succ_code := 'SB04BPFCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
		
	if exists (	select	count(*)
				from 	pg_trn_tbussplanfinyear
			    where 	pg_id = _pg_id
			    and 	bussplan_id = _bussplan_id
			    and 	finyear_id = _finyear_id
			    and 	prod_code = _prod_code
				group	by pg_id,bussplan_id,finyear_id,prod_code
				having	count('*') > 1) 
	then
		-- pg id cannot be duplicated
		v_err_code := v_err_code || 'EB04BPPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04BPPCUD_001', _lang_code),_pg_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanfinyearjson(_bussplanfinjson udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By 	 : Mohan S
		Created Date : 10-03-2022
		
		Updated By 	 : Vijayavel J
		Updated Date : 13-03-2022

		SP Code 	 : B04BPFCUX
	*/
	
	v_colrec record;
    v_updated_date udd_datetime;
    v_created_date udd_datetime;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_bussplanfinjson::udd_jsonb) as items 
													(
														bussplancalender_gid udd_int,
														pg_id udd_code,
														bussplan_id udd_code,
														finyear_id udd_code,
														prod_type_code udd_code,
														prod_code udd_code,
														uom_code udd_code,
														prodrevenue_rate udd_rate,
														prodprocure_rate udd_text,
														created_date udd_text,
														created_by udd_code,
														updated_date udd_text,
														updated_by udd_code
														) 
												
LOOP 
	select fn_text_todatetime(v_colrec.updated_date)
	into   v_updated_date;
				
	select fn_text_todatetime(v_colrec.created_date)
	into   v_created_date;
				
		if (v_colrec.prodprocure_rate = 'Revenue') then 
			insert into pg_trn_tbussplanfinyear (
														--- bussplancalender_gid, comment by Vijayavel
														pg_id ,
														bussplan_id ,
														finyear_id ,
														prod_type_code ,
														prod_code ,
														uom_code ,
														prodrevenue_rate ,
														created_date ,
														created_by,
														updated_date,
														updated_by
													)
										values		(
														-- v_colrec.bussplancalender_gid, comment by Vijayavel
														v_colrec.pg_id ,
														v_colrec.bussplan_id ,
														v_colrec.finyear_id ,
														v_colrec.prod_type_code ,
														v_colrec.prod_code ,
														v_colrec.uom_code ,
														v_colrec.prodrevenue_rate ,
														now(), 
														v_colrec.created_by,
														v_updated_date,
														v_colrec.updated_by
													)
						on CONFLICT ( pg_id,
									  bussplan_id,
									  finyear_id,
									  prod_code
									)  
									 do update set  
									 				--bussplancalender_gid = v_colrec.bussplancalender_gid, comment by vijayavel
													pg_id = v_colrec.pg_id,
													bussplan_id = v_colrec.bussplan_id,
													finyear_id = v_colrec.finyear_id,
													prodrevenue_rate = v_colrec.prodrevenue_rate,
													updated_date = now(),
													updated_by = v_colrec.updated_by;
													
			else if (v_colrec.prodprocure_rate = 'Procurement') then 
				insert into pg_trn_tbussplanfinyear (
														-- bussplancalender_gid ,
														pg_id ,
														bussplan_id ,
														finyear_id ,
														prod_type_code ,
														prod_code ,
														uom_code ,
														prodrevenue_rate ,
														created_date ,
														created_by,
														updated_date,
														updated_by
													)
										values		(
														-- v_colrec.bussplancalender_gid ,
														v_colrec.pg_id ,
														v_colrec.bussplan_id ,
														v_colrec.finyear_id ,
														v_colrec.prod_type_code ,
														v_colrec.prod_code ,
														v_colrec.uom_code ,
														v_colrec.prodrevenue_rate ,
														now(), 
														v_colrec.created_by,
														v_updated_date,
														v_colrec.updated_by
													)
						on CONFLICT ( pg_id,
									  bussplan_id,
									  finyear_id,
									  prod_code
									)  
									 do update set  
									 				-- bussplancalender_gid = v_colrec.bussplancalender_gid,
													pg_id = v_colrec.pg_id,
													bussplan_id = v_colrec.bussplan_id,
													finyear_id = v_colrec.finyear_id,
													prodprocure_rate = v_colrec.prodrevenue_rate,
													updated_date = now(),
													updated_by = v_colrec.updated_by;
			end if;
		end if;

END LOOP;
			
			select 	'Bussplan Finyear Updated Successfully' 
			into	 _succ_msg;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanprodjson(_bussplanprod udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 01-03-2022
		SP Code : B04BPPCUD
	*/
	v_pg_id			udd_code	:= '';
	v_bussplan_id	udd_code	:= '';
	
	v_colrec record;
	v_colrec1 record;
 	v_delete_flag udd_flag := 'N';
begin
		 select 
		 	max(items.pg_id),max(items.bussplan_id)
		 into
		 	v_pg_id,v_bussplan_id
		 from jsonb_to_recordset(_bussplanprod::udd_jsonb) as items 
													(
														bussplanprod_gid udd_int,
														pg_id udd_code,
														bussplan_id udd_code,
														prod_type_code udd_code,
														prod_code udd_code,
														uom_code udd_code,
														from_date udd_date,
														to_date udd_date,
														selection_flag udd_flag,
														lang_code udd_code,
														user_code udd_code,
														mode_flag udd_flag,
														succ_msg udd_text
														);

	
	 for v_colrec1 IN 	select prod_code from pg_trn_tbussplanproduct 
					 	where pg_id = v_pg_id
						and bussplan_id = v_bussplan_id
						and prod_code not in 
	 (
		 select items.prod_code from jsonb_to_recordset(_bussplanprod::udd_jsonb) as items 
													(
														bussplanprod_gid udd_int,
														pg_id udd_code,
														bussplan_id udd_code,
														prod_type_code udd_code,
														prod_code udd_code,
														uom_code udd_code,
														from_date udd_date,
														to_date udd_date,
														selection_flag udd_flag,
														lang_code udd_code,
														user_code udd_code,
														mode_flag udd_flag,
														succ_msg udd_text
														) 
	 )
	 loop
	 
	 call pr_set_bussplandelete(v_pg_id,v_bussplan_id,v_colrec1.prod_code);
	 
	 end loop;
	 
	 FOR v_colrec IN select * from jsonb_to_recordset(_bussplanprod::udd_jsonb) as items 
													(
														bussplanprod_gid udd_int,
														pg_id udd_code,
														bussplan_id udd_code,
														prod_type_code udd_code,
														prod_code udd_code,
														uom_code udd_code,
														from_date udd_date,
														to_date udd_date,
														selection_flag udd_flag,
														lang_code udd_code,
														user_code udd_code,
														mode_flag udd_flag,
														succ_msg udd_text
														) 
												
			LOOP 
			
			/*
		    if v_delete_flag = 'N' then 
				delete from pg_trn_tbussplanproduct
				where  pg_id = v_colrec.pg_id
				and    bussplan_id 	= v_colrec.bussplan_id;
	 		--  call pr_set_bussplandelete(v_colrec.pg_id,v_colrec.bussplan_id,v_colrec.from_date,v_colrec.to_date);
			   v_delete_flag := 'Y';
			end if;
			*/
			
			v_colrec.mode_flag := 'I';
			
-- 			if (v_colrec.bussplanprod_gid = 0 and v_colrec.selection_flag = 'Y')then
-- 				v_colrec.mode_flag := 'I';
-- 			end if;
			
-- 			if (v_colrec.bussplanprod_gid <> 0 and v_colrec.selection_flag = 'Y')then
-- 				v_colrec.mode_flag := 'U';
-- 			end if;
			
			/*if (v_colrec.bussplanprod_gid <> 0 and v_colrec.selection_flag <> 'Y')then
				v_colrec.mode_flag := 'D';
			end if;*/
			
			call pr_iud_bussplanproduct(
									   v_colrec.bussplanprod_gid,
									   v_colrec.pg_id,
									   v_colrec.bussplan_id,
									   v_colrec.prod_type_code,
									   v_colrec.prod_code,
									   v_colrec.uom_code,
									   v_colrec.from_date,
									   v_colrec.to_date,
									   v_colrec.selection_flag,
									   v_colrec.lang_code,
									   v_colrec.user_code,
									   v_colrec.mode_flag,
									   v_colrec.succ_msg);
			
			END LOOP;
			
	select 'Bussplan Product Created Successfully' into _succ_msg;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanprodjsonb(_bussplanprod udd_jsonb, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 01-03-2022
		SP Code : B04BPPCUD
	*/
	
	v_colrec record;

begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_bussplanprod::udd_jsonb) as items 
													(
														bussplanprod_gid udd_int,
														pg_id udd_code,
														bussplan_id udd_code,
														prod_type_code udd_code,
														prod_code udd_code,
														uom_code udd_code,
														from_date udd_date,
														to_date udd_date,
														selection_flag udd_flag,
														lang_code udd_code,
														user_code udd_code,
														mode_flag udd_flag,
														succ_msg udd_text
														) 
												
			LOOP 
			
			if (v_colrec.bussplanprod_gid = 0 and v_colrec.selection_flag = 'Y')then
				v_colrec.mode_flag := 'I';
			end if;
			
			if (v_colrec.bussplanprod_gid <> 0 and v_colrec.selection_flag = 'N')then
				v_colrec.mode_flag := 'D';
			end if;
			
			if (v_colrec.bussplanprod_gid <> 0 and v_colrec.selection_flag = 'Y')then
				v_colrec.mode_flag := 'U';
			end if;
			
			
			call pr_iud_bussplanproduct(
									   v_colrec.bussplanprod_gid,
									   v_colrec.pg_id,
									   v_colrec.bussplan_id,
									   v_colrec.prod_type_code,
									   v_colrec.prod_code,
									   v_colrec.uom_code,
									   v_colrec.from_date,
									   v_colrec.to_date,
									   v_colrec.selection_flag,
									   v_colrec.lang_code,
									   v_colrec.user_code,
									   v_colrec.mode_flag,
									   v_colrec.succ_msg);
			
			END LOOP;
			
	select 'Bussplan Product Created Successfully' into _succ_msg;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanproduce(INOUT _bussplanproduce_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _finyear_id udd_code, _produce_month udd_date, _prod_type_code udd_code, _prod_code udd_code, _uom_code udd_code, _sowing_flag udd_flag, _harvesting_qty udd_qty, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 14-02-2021
		SP Code : B04BPECUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
		
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FDBCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_018' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_018', _lang_code) || v_new_line;	
	end if;
	
	-- prod code validation
	if not exists (select 	* 
				   from 	core_mst_tproduct 
				   where 	prod_code = _prod_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_016', _lang_code) || v_new_line;	
	end if;
	
	-- prod type code validation
	if(_prod_type_code = '')then 
		select 		prod_type_code into _prod_type_code
		from 		core_mst_tproduct 
		where 		prod_code = _prod_code
	    and 		status_code = 'A';
		
	else
		if not exists (select 		*
						from 		core_mst_tproduct
						where 		prod_type_code = _prod_type_code
					    and         prod_code = _prod_code
	    				and 		status_code = 'A')then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;
		end if;
	end if;
	
	-- uom code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_UOM'
				   and 		master_code = _uom_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_019' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_019', _lang_code)|| v_new_line;	
	end if;
	
	-- finyear id validation 
	if not exists (select   * 
				   from 	core_mst_tfinyear
				   where 	finyear_id = _finyear_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB04BPECUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- produce month validation
	if _produce_month is null then
		v_err_code := v_err_code || 'VB04BPECUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_002', _lang_code) || v_new_line;
	end if;
	
	-- harvesting qty validation
	if _harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPECUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_003', _lang_code) || v_new_line;
	end if;
	
	-- sowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPECUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_004', _lang_code);	
	end if;
	
	-- sowing and harvesting validation
	/*if _sowing_flag = 'Y' and _harvesting_qty > 0 then
		v_err_code := v_err_code || 'VB04BPECUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_005', _lang_code);	
	end if;*/
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tbussplanproduce
				  where 	bussplanproduce_gid = _bussplanproduce_gid
				  and 		pg_id = _pg_id
				 ) then
				 
			delete   from 	pg_trn_tbussplanproduce
			where 	bussplanproduce_gid = _bussplanproduce_gid;
			
			v_succ_code := 'SB04BPECUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tbussplanproduce
					  where		bussplanproduce_gid = _bussplanproduce_gid
					  and 		pg_id = _pg_id 
					 ) then
			insert into pg_trn_tbussplanproduce 
			(
				pg_id,
				bussplan_id,
				finyear_id,
				produce_month,
				prod_type_code,
				prod_code,
				uom_code,
				sowing_flag,
				harvesting_qty,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_finyear_id,
				_produce_month,
				_prod_type_code,
				_prod_code,
				_uom_code,
				_sowing_flag,
				_harvesting_qty,
				_user_code,
				now()
			) returning bussplanproduce_gid into _bussplanproduce_gid;
			
			v_succ_code := 'SB04BPECUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tbussplanproduce
				   where	bussplanproduce_gid = _bussplanproduce_gid
				   ) then
			update	pg_trn_tbussplanproduce 
			set 	pg_id = _pg_id,
					bussplan_id = _bussplan_id,
					finyear_id = _finyear_id,
					produce_month = _produce_month,
					prod_type_code = _prod_type_code,
					prod_code = _prod_code,
					uom_code = _uom_code,
					sowing_flag = _sowing_flag,
					harvesting_qty = _harvesting_qty,
					updated_by = _user_code,
					updated_date = now()
			where 	bussplanproduce_gid = _bussplanproduce_gid;
			
			v_succ_code := 'SB04BPECUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
		
	if exists (	select	count(*)
				from 	pg_trn_tbussplanproduce
			    where 	pg_id = _pg_id
			   	and 	bussplan_id = _bussplan_id
			   	and		finyear_id = _finyear_id
			   	and 	prod_code = _prod_code
			    and 	produce_month = _produce_month
				group	by pg_id,bussplan_id,finyear_id,prod_code,produce_month
				having	count('*') > 1) 
	then
		-- pg id cannot be duplicated
		v_err_code := v_err_code || 'EB04BPPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04BPPCUD_001', _lang_code),_pg_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_bussplanproduct(INOUT _bussplanprod_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _prod_type_code udd_code, _prod_code udd_code, _uom_code udd_code, _from_date udd_date, _to_date udd_date, _selection_flag udd_flag, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 23-12-2021
		SP Code : B04BPPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_add_month udd_date := null;
	v_count_month udd_int;
	v_finyear_id udd_code := '';
	colrec record;
	colrec1 record;
	v_to_date udd_date := null;
	v_from_date udd_date := null;
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
		
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_018' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_018', _lang_code) || v_new_line;	
	end if;
	
	-- prod code validation
	if not exists (select 	* 
				   from 	core_mst_tproduct 
				   where 	prod_code = _prod_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_016', _lang_code) || v_new_line;	
	end if;
	
	-- prod type code validation
	if(_prod_type_code = '')then 
		select 		prod_type_code into _prod_type_code
		from 		core_mst_tproduct 
		where 		prod_code = _prod_code
	    and 		status_code = 'A';
		
	else
		if not exists (select 		*
						from 		core_mst_tproduct
						where 		prod_type_code = _prod_type_code
					    and         prod_code = _prod_code
	    				and 		status_code = 'A')then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;
		end if;
	end if;
	
	-- uom code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_UOM'
				   and 		master_code = _uom_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_019' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_019', _lang_code)|| v_new_line;	
	end if;
	
	-- From date cannot be null
	if _from_date is Null then
		v_err_code := v_err_code || 'VB04BUPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- To date cannot be blank
	if _to_date is Null then
		v_err_code := v_err_code || 'VB04BUPCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BUPCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- period to validation
	if _from_date > _to_date then
		v_err_code := v_err_code || 'EB04BUPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB04BUPCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- Selection Flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _selection_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPPCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPPCUD_001', _lang_code)|| v_new_line;	
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tbussplanproduct
				  where bussplanprod_gid = _bussplanprod_gid)
			then
			delete  from pg_trn_tbussplanproduct
			where 	bussplanprod_gid = _bussplanprod_gid;
			
			v_succ_code := 'SB04BPPCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif ( _mode_flag = 'I' ) then
-- 		if not exists(select 	* 
-- 					  from		pg_trn_tbussplanproduct
-- 					  where		bussplanprod_gid = _bussplanprod_gid
-- 					  and 		pg_id = _pg_id 
-- 					 ) then
			insert into pg_trn_tbussplanproduct 
			(
				pg_id,
				bussplan_id,
				prod_type_code,
				prod_code,
				uom_code,
				selection_flag,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_prod_type_code,
				_prod_code,
				_uom_code,
				_selection_flag,
				_user_code,
				now()
			)
			on CONFLICT ( pg_id,
						  bussplan_id,
						  prod_code) 
		    do update set   pg_id = _pg_id,
							bussplan_id = _bussplan_id,
							prod_type_code = _prod_type_code,
							prod_code = _prod_code,
							uom_code = _uom_code,
							updated_date = now(),
							updated_by = _user_code
			returning bussplanprod_gid into _bussplanprod_gid;
			
			
			-- for loop (Produce table)
			v_count_month := (select 
								EXTRACT(year FROM age(_to_date,_from_date))*12 +
								EXTRACT(month FROM age(_to_date,_from_date)));

			v_count_month := v_count_month + 1;					
			v_add_month := date_trunc('month', _from_date) ;

			while v_count_month > 0 loop

				select 	finyear_id into v_finyear_id 
				from 	core_mst_tfinyear 
				where 	v_add_month between finyear_start_date 
				and 	finyear_end_date
				and 	status_code = 'A';

				--insert operation 
				insert into pg_trn_tbussplanproduce (   pg_id,
														bussplan_id,
														finyear_id,
														produce_month,
														prod_type_code,
														prod_code,
														uom_code,
														sowing_flag,
														harvesting_qty,
														created_date,
														created_by)

												values(
														 _pg_id,
														 _bussplan_id,
														 v_finyear_id,
														 v_add_month,
														 _prod_type_code,
														 _prod_code,
														 _uom_code,
														 'N',
														 0,
														 now(),
														 _user_code)
								on CONFLICT ( pg_id,
											  bussplan_id,
											  finyear_id ,
											  produce_month,
											  prod_type_code,
											  prod_code) 
							 do update set   updated_date = now();
											 
								v_add_month := v_add_month + INTERVAL '1 MONTH';
								v_count_month := v_count_month - 1;
			end loop;

			-- For loop (finyear table)
		    v_from_date := _from_date::date  - INTERVAL '1 year';
			v_to_date := _to_date::date  + INTERVAL '1 year';

			 <<label0>>
			 FOR colrec IN select a.finyear_id from (select 	finyear_id 
														from 	core_mst_tfinyear 
														where 	finyear_start_date > v_from_date
														and 	status_code = 'A') as a 
											inner join (select  finyear_id 
														from 	core_mst_tfinyear 
														where 	finyear_end_date < v_to_date
														and 	status_code = 'A') as b on a.finyear_id = b.finyear_id 
			 LOOP
			    -- Bussplan finyear table insert 
				insert into pg_trn_tbussplanfinyear (
													 pg_id,
													 bussplan_id,
													 finyear_id,
													 prod_type_code,
													 prod_code,
													 uom_code,
													 prodrevenue_rate,
													 prodprocure_rate,
													 created_date,
													 created_by
													)
											Values (_pg_id,
													_bussplan_id,
													colrec.finyear_id,
													_prod_type_code,
													_prod_code,
													_uom_code,
													0,
													0,
													now(),
													_user_code
													)
								on CONFLICT ( pg_id,
									 		  bussplan_id,
									  		  finyear_id ,
									 		  prod_code) 
									 do update set   pg_id = _pg_id,
													 bussplan_id = _bussplan_id,
													 finyear_id = colrec.finyear_id,
													 prod_type_code = _prod_type_code,
													 prod_code = _prod_code,
													 uom_code = _uom_code;
													
			-- Bussplan expenses table insert
			if not exists  (select '*' from pg_trn_tbussplanexpenses
						   	where 	pg_id 		= _pg_id
						   	and		bussplan_id = _bussplan_id
						   	and 	finyear_id 	= colrec.finyear_id)
			then
				insert into pg_trn_tbussplanexpenses (
														 pg_id,
														 bussplan_id,
														 finyear_id,
														 operating_expenses,
														 created_date,
														 created_by
														)
												Values (_pg_id,
														_bussplan_id,
														colrec.finyear_id,
														0,
														now(),
														_user_code
														);

			 End if;
			 End Loop label0;
	
			v_succ_code := 'SB04BPPCUD_001';
-- 		else
-- 			-- Record already exists
-- 			v_err_code := v_err_code || 'EB00CMNCMN_002';
-- 			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
-- 			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
-- 	elseif _mode_flag = 'U' then
-- 		if exists (select * from pg_trn_tbussplanproduct
-- 				   where		 bussplanprod_gid = _bussplanprod_gid
-- 				   and 			 pg_id = _pg_id )
-- 		then 
-- 		update pg_trn_tbussplanproduct
-- 		set		pg_id				= _pg_id,
-- 				bussplan_id	   	 	= _bussplan_id,
-- 				prod_type_code 		= _prod_type_code,
-- 				prod_code			= _prod_code,
-- 				uom_code			= _uom_code,
-- 				selection_flag		= _selection_flag,
-- 				updated_date		= now(),
-- 				updated_by			= _user_code
-- 		where   bussplanprod_gid    = _bussplanprod_gid;
		
-- 		v_succ_code	:= 'SB04BPPCUD_002';
		
-- 		else
-- 			 v_err_code := v_err_code || 'EB00CMNCMN_003';
-- 			 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	

-- 				RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
-- 		end if;
-- 	end if;
	
	if v_succ_code <> '' then
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_collection(INOUT _coll_gid udd_int, _pg_id udd_code, _coll_no udd_int, _coll_date udd_date, _coll_amount udd_amount, _pay_mode_code udd_code, _pay_ref_no udd_desc, _inv_no udd_code, _coll_remark udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 08-08-2022
		SP Code      : B06COLCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	
	v_sale_date udd_date := null;
	v_collected_amount udd_amount := 0;
	v_coll_amount udd_amount := 0;
	v_coll_amount_ins udd_amount := 0;
	v_coll_amount_upd udd_amount := 0;
	v_coll_amount_dlt udd_amount := 0;
	v_inv_amount  udd_amount := 0; 
	v_newinv_amount udd_amount := 0;
begin
	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- collection No Validation
	if _coll_no <= 0
	then
		v_err_code := v_err_code || 'VB06COLCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_001', _lang_code) || v_new_line;	
	end if;	
	
	-- Collection Date Validation
	if _coll_date isnull
	then
		v_err_code := v_err_code || 'VB06COLCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_002', _lang_code) || v_new_line;	 
	end if;

	-- Collection Amount Validation
	if _coll_amount <= 0
	then
		v_err_code := v_err_code || 'VB06COLCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_003', _lang_code) || v_new_line;	 
	end if;

	-- paymode code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PAY_MODE'
				   and 		master_code = _pay_mode_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB06COLCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06COLCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- Invoice No Validation
	if not exists (select * from pg_trn_tsale
				   where pg_id       = _pg_id
				   and   inv_no      = _inv_no
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB06COLCUD_006' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_006', _lang_code) || v_new_line;	
	else
		-- Get collected amount
		select 	collected_amount into v_collected_amount
		from 	pg_trn_tsale 
		where 	pg_id 		= _pg_id 
		and 	inv_no 		= _inv_no
		and 	status_code = 'A';

		v_collected_amount := coalesce(v_collected_amount,0);

		-- Get coll amount
		if exists ( select 	* 
					from 	pg_trn_tcollection
					where 	pg_id 	= _pg_id
					and 	inv_no 	= _inv_no) then 
			select 	sum(coll_amount) into v_coll_amount 
			from 	pg_trn_tcollection
			where 	pg_id 	= _pg_id
			and 	inv_no 	= _inv_no;
		end if;

		v_coll_amount := coalesce(v_coll_amount,0);

		-- Get coll amount and sale date
		select 	inv_amount,inv_date into v_inv_amount,v_sale_date 
		from 	pg_trn_tsale
		where 	pg_id 	= _pg_id
		and 	inv_no 	= _inv_no;
		
		if v_sale_date > _coll_date then
				v_err_code := v_err_code || 'VB06COLCUD_007' || ',';
				v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_007', _lang_code) || v_new_line;	 
		end if;

		v_inv_amount := coalesce(v_inv_amount,0);

		v_coll_amount_ins := v_coll_amount + _coll_amount;
		v_coll_amount_dlt := v_coll_amount - _coll_amount;

-- 		if _mode_flag = 'U' then 
-- 			if exists ( select 	*
-- 						from 	pg_trn_tcollection
-- 						where 	pg_id = _pg_id
-- 					    and     coll_gid = _coll_gid) then

-- 				select 	sum(coll_amount) into v_coll_amount 
-- 				from 	pg_trn_tcollection
-- 				where 	pg_id = _pg_id 
-- 				and 	coll_gid = _coll_gid;
-- 			else 
-- 				v_coll_amount := 0;
-- 			end if;

-- 				v_coll_amount := v_coll_amount + _coll_amount;

-- 				if v_coll_amount > v_inv_amount then
-- 					v_err_code := v_err_code || 'VB06COLCUD_005' || ',';
-- 					v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_005', _lang_code) || v_new_line;	 
-- 				end if;
-- 		end if;

		-- Coll amount validation
		if _mode_flag = 'I' then
			if v_coll_amount_ins > v_inv_amount then
				v_err_code := v_err_code || 'VB06COLCUD_005' || ',';
				v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_005', _lang_code) || v_new_line;	 
			end if;
		end if;
	end if;
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code = _lang_code
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
		
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tcollection
				  where coll_gid = _coll_gid)
			then
				delete from pg_trn_tcollection 
				where coll_gid = _coll_gid;
				
		  -- Sale collected amt updation
		  update	pg_trn_tsale 
		  set 	 	collected_amount = v_coll_amount_dlt
		  where 	pg_id = _pg_id
		  and 		inv_no = _inv_no
		  and 		status_code = 'A';
				
			v_succ_code := 'SB06COLCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tcollection
				   where coll_gid = _coll_gid)
		 then
			insert into pg_trn_tcollection
			(
				pg_id,
				coll_no,
				coll_date,
				coll_amount,
				pay_mode_code,
				pay_ref_no,
				inv_no,
				coll_remark,
				created_date,
				created_by
			)
			values
			(
				_pg_id,
				_coll_no,
				_coll_date,
				_coll_amount,
				_pay_mode_code,
				_pay_ref_no,
				_inv_no,
				_coll_remark,
				now(),
				_user_code
			  ) returning coll_gid into _coll_gid;
			  v_succ_code := 'SB06COLCUD_001';
			  
			  -- Sale collected amt updation
			  update	pg_trn_tsale 
			  set 	 	collected_amount = v_coll_amount_ins
			  where 	pg_id = _pg_id
			  and 		inv_no = _inv_no
			  and 		status_code = 'A';
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tcollection
				   where coll_gid   = _coll_gid)
		then
			if exists ( select 	*
						from 	pg_trn_tcollection
						where 	pg_id = _pg_id
					    and     coll_gid = _coll_gid) then

				select 	sum(coll_amount) into v_coll_amount 
				from 	pg_trn_tcollection
				where 	pg_id = _pg_id 
				and 	coll_gid = _coll_gid;
			end if;
			if v_coll_amount = v_inv_amount or v_coll_amount < v_inv_amount
			then
				update pg_trn_tcollection
				set		pg_id 				=   _pg_id,
						coll_no 			=   _coll_no,
						coll_date 			=   _coll_date,
						coll_amount 		=   _coll_amount,
						pay_mode_code 		=   _pay_mode_code,
						pay_ref_no 			=   _pay_ref_no,
						inv_no 				=   _inv_no,
						coll_remark 		=   _coll_remark,
						updated_date		=	now(),
						updated_by			=	_user_code
				 where  coll_gid			=	_coll_gid;
				 
		        select 	sum(coll_amount) into v_coll_amount 
				from 	pg_trn_tcollection
				where 	pg_id = _pg_id 
				and 	coll_gid = _coll_gid;
				
		 v_coll_amount := v_coll_amount + _coll_amount;

				if v_coll_amount > v_inv_amount then
					v_err_code := v_err_code || 'VB06COLCUD_005' || ',';
					v_err_msg  := v_err_msg || fn_get_msg ('VB06COLCUD_005', _lang_code) || v_new_line;	 
				end if;
			end if;
		 v_succ_code	:= 'SB06COLCUD_002';
		 
		 select 	sum(coll_amount) into v_coll_amount 
		 from 		pg_trn_tcollection
		 where 		pg_id = _pg_id
		 and		inv_no = _inv_no;
		 
		 select     sale_rate * inv_qty into v_newinv_amount
		 from       pg_trn_tsaleproduct 
		 where      pg_id  = _pg_id  
		 and        inv_no = _inv_no ; 
		 
		 -- Sale collected amt updation
		  update	pg_trn_tsale 
		  set 	 	collected_amount = v_coll_amount
-- 		            inv_amount       = v_newinv_amount
		  where 	pg_id = _pg_id
		  and 		inv_no = _inv_no
		  and 		status_code = 'A';
		 
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_districtmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Thianeswaran
		Created Date : 28-02-2022
		SP Code : B01DTMCUX  
		Updated By : Mangai
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;
begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														district_id integer,
														state_id integer,
														district_code char(4),
														district_name_en varchar(100),
														district_name_local varchar(200),
														district_short_name_en varchar(20),
														district_short_name_local varchar(40),
														fundrelease_flag boolean,
														language_id varchar(2),
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer,
														district_name_hi varchar(255)
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
				
				insert into district_master (
														district_id,
														state_id,
														district_code,
														district_name_en,
														district_name_local,
														district_short_name_en,
														district_short_name_local,
														fundrelease_flag,
														language_id,
														is_active,
														created_date,
														created_by,
														updated_date,
														updated_by,
														district_name_hi
												)
							values              (
													v_colrec.district_id,
													v_colrec.state_id,
													v_colrec.district_code,
													v_colrec.district_name_en,
													v_colrec.district_name_local,
													v_colrec.district_short_name_en,
													v_colrec.district_short_name_local,
													v_colrec.fundrelease_flag,
													v_colrec.language_id,
													v_colrec.is_active,
													v_created_date,
													v_colrec.created_by,
													v_updated_date,
													v_colrec.updated_by,
													v_colrec.district_name_hi
							)
							
		on CONFLICT (district_id )  do update set  
													district_id = v_colrec.district_id,
													state_id = v_colrec.state_id,
													district_code = v_colrec.district_code,
													district_name_en = v_colrec.district_name_en,
													district_name_local = v_colrec.district_name_local,
													district_short_name_en = v_colrec.district_short_name_en,
													district_short_name_local = v_colrec.district_short_name_local,
													fundrelease_flag = v_colrec.fundrelease_flag,
													language_id = v_colrec.language_id,
													is_active = v_colrec.is_active,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by,
													district_name_hi = v_colrec.district_name_hi;
		END LOOP;
		
				open result_succ_msg for select 	
   										'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_excplog(INOUT _excplog_gid udd_int, _pg_id udd_code, _role_code udd_code, _user_code udd_code, _mobile_no udd_mobile, _excp_date udd_datetime, _excp_from udd_code, _excp_code udd_code, _excp_text udd_text, _lang_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 22-03-2022
		SP Code      : B04SLACXX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where 	pg_id  = _pg_id 
				   and 		status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where 	lang_code   = _lang_code
				   and   	status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'I' then
		if not exists (select * from pg_trn_texcplog
				   	   where 	excplog_gid = _excplog_gid
				   	   and   	pg_id		= _pg_id)
		 then
			insert into pg_trn_texcplog(
										pg_id,
										role_code,
										user_code,
										mobile_no,
										excp_date,
										excp_from,
										excp_code,
										excp_text
													)
							values(
									_pg_id,
									_role_code,
									_user_code,
									_mobile_no,
									_excp_date,
									_excp_from,
									_excp_code,
									_excp_text
									) returning excplog_gid into _excplog_gid;
									v_succ_code := 'SB00CMNCMN_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_executivememberjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B04EXMCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											executive_member_id bigint,
											cbo_id				bigint,
											cbo_level			smallint,
											ec_cbo_level		smallint,
											ec_cbo_code			varchar(50),
											ec_cbo_id			bigint,
											ec_member_code		bigint,
											designation			smallint,
											joining_date		date,
											leaving_date		date,
											status				smallint,
											is_active			boolean,
											state_id			integer,
											created_date  		text,
											updated_date		text
										)
		  loop
		   select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
		   select fn_text_todatetime(v_colrec.created_date) into v_created_date;
		   		  
		      insert into executive_member(
			  								executive_member_id,
											cbo_id,
											cbo_level,
											ec_cbo_level,
											ec_cbo_code,
											ec_cbo_id,
											ec_member_code,
											designation,
											joining_date,
											leaving_date,
											status,
											is_active,
											state_id,
				  							created_date,
				  							updated_date
			  							)
								values  (											
			  								v_colrec.executive_member_id,
											v_colrec.cbo_id,
											v_colrec.cbo_level,
											v_colrec.ec_cbo_level,
											v_colrec.ec_cbo_code,
											v_colrec.ec_cbo_id,
											v_colrec.ec_member_code,
											v_colrec.designation,
											v_colrec.joining_date,
											v_colrec.leaving_date,
											v_colrec.status,
											v_colrec.is_active,
											v_colrec.state_id,
											v_created_date,
											v_updated_date
											
								       )
										
				on conflict (
								ec_member_code,
								state_id,
								cbo_id,
								cbo_level,
								ec_cbo_code,
								executive_member_id
							)
							do update set   executive_member_id	= v_colrec.executive_member_id,
											cbo_id				= v_colrec.cbo_id,
											cbo_level			= v_colrec.cbo_level,
											ec_cbo_level		= v_colrec.ec_cbo_level,
											ec_cbo_code			= v_colrec.ec_cbo_code,
											ec_cbo_id			= v_colrec.ec_cbo_id,
											ec_member_code		= v_colrec.ec_member_code,
											designation			= v_colrec.designation,
											joining_date		= v_colrec.joining_date,
											leaving_date		= v_colrec.leaving_date,
											status				= v_colrec.status,
											is_active			= v_colrec.is_active,
											state_id			= v_colrec.state_id,
											updated_date 		= v_updated_date;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_federationprofilejson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B01FEPCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											federation_id 			bigint,
											federation_code 		bigint,
											state_id 				integer,
											district_id 			integer,
											block_id 				integer,
											village_id 				integer,
											panchayat_id 			integer,
											federation_name 		varchar(200),
											federation_type_code 	smallint,
											cbo_type 				smallint,
											cbo_level 				smallint,
											child_level 			smallint,
											federation_name_local 	varchar(120),
											promoted_by 			smallint,
											parent_cbo_code 		bigint,
											parent_cbo_type 		smallint,
											is_active 				boolean,
											status 					smallint,
											promoter_code 			varchar(5),
											created_date 			text,
											updated_date 			text											
										)
		  loop
		  	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
		  	  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  		  
		      insert into federation_profile(
			  								federation_id,
											federation_code,
											state_id,
											district_id,
											block_id,
											village_id,
											panchayat_id,
											federation_name,
											federation_type_code,
											cbo_type,
											cbo_level,
											child_level,
											federation_name_local,
											promoted_by,
											parent_cbo_code,
											parent_cbo_type,
											is_active,
											status,
											promoter_code,
											created_date,
											updated_date 
			  							)
								values  (											
			  								v_colrec.federation_id,
											v_colrec.federation_code,
											v_colrec.state_id,
											v_colrec.district_id,
											v_colrec.block_id,
											v_colrec.village_id,
											v_colrec.panchayat_id,
											v_colrec.federation_name,
											v_colrec.federation_type_code,
											v_colrec.cbo_type,
											v_colrec.cbo_level,
											v_colrec.child_level,
											v_colrec.federation_name_local,
											v_colrec.promoted_by,
											v_colrec.parent_cbo_code,
											v_colrec.parent_cbo_type,
											v_colrec.is_active,
											v_colrec.status,
											v_colrec.promoter_code,
											v_created_date,
											v_updated_date 
										)
										
				on conflict (
								federation_id
							)
							do update set   federation_id		= v_colrec.federation_id,
											federation_code		= v_colrec.federation_code,
											state_id			= v_colrec.state_id,
											district_id			= v_colrec.district_id,
											block_id			= v_colrec.block_id,
											village_id			= v_colrec.village_id,
											panchayat_id		= v_colrec.panchayat_id,
											federation_name		= v_colrec.federation_name,
											federation_type_code= v_colrec.federation_type_code,
											cbo_type			= v_colrec.cbo_type,
											cbo_level			= v_colrec.cbo_level,
											child_level			= v_colrec.child_level,
											federation_name_local= v_colrec.federation_name_local,
											promoted_by			= v_colrec.promoted_by,
											parent_cbo_code		= v_colrec.parent_cbo_code,
											parent_cbo_type		= v_colrec.parent_cbo_type,
											is_active			= v_colrec.is_active,
											status				= v_colrec.status,
											promoter_code		= v_colrec.promoter_code,
											updated_date		= v_updated_date;
						END LOOP;
						
						open result_succ_msg for select 	
   									'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_funddisbtranche(INOUT _funddisbtranche_gid udd_int, _pg_id udd_code, _funddisb_id udd_code, _tranche_no udd_int, _tranche_amount udd_amount, _tranche_date udd_date, _tranche_status_code udd_code, _received_date udd_date, _received_ref_no udd_code, _sync_status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare	
	/*
		Created By : Mohan S
		Created Date : 31-12-2021
		SP Code : B05FDTCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_tot_trancheamt udd_amount := 0;
	v_tot_sanction_amount udd_amount := 0;
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FDTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- funddisbu id validation
		if not exists (select   * 
				   from 	pg_trn_tfunddisbursement
				   where 	pg_id = _pg_id
				   and		funddisb_id = _funddisb_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FDTCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_002', _lang_code) || v_new_line;	
	end if;
	
	-- trancheno cannot be blank
	if _tranche_no <= 0 then
		v_err_code := v_err_code || 'VB05FDTCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- tranche amount cannot be blank
	if _tranche_amount <= 0 then
		v_err_code := v_err_code || 'VB05FDTCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- Getting total fundisb amt
	select  coalesce(sum(sanctioned_amount),0) into v_tot_sanction_amount
	from 	pg_trn_tfunddisbursement
	where 	pg_id = _pg_id
	and     funddisb_id = _funddisb_id
	and 	status_code = 'A';
	
	-- Getting total tranche amt
	select  coalesce(sum(tranche_amount),0) into v_tot_trancheamt
	from 	pg_trn_tfunddisbtranche 
	where 	pg_id = _pg_id 
	and     funddisb_id = _funddisb_id
	and 	funddisbtranche_gid <> _funddisbtranche_gid;
	
	
	-- tranche amount validation
	v_tot_trancheamt := v_tot_sanction_amount - v_tot_trancheamt ;
	
	if v_tot_trancheamt < _tranche_amount then
		v_err_code := v_err_code || 'VB05FDTCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_008', _lang_code) || v_new_line;
	end if;
	
	-- tranche date cannot be null
	if _tranche_date is null  then
		v_err_code := v_err_code || 'VB05FDTCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- tranche status code validation
	if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = 'QCD_TRANCHE_STATUS'
					   and 		master_code = _tranche_status_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB05FDTCUD_006' || ',';	
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_006', _lang_code) || v_new_line;	
	end if;
	
	-- sync status code validation
	if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = 'QCD_SYNC_STATUS'
					   and 		master_code = _sync_status_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB05FDTCUD_007' || ',';	
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_007', _lang_code) || v_new_line;	
	end if;
		
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tfunddisbtranche
				  where 	funddisbtranche_gid = _funddisbtranche_gid
				  and 		tranche_status_code = 'QCD_DISB'
				 ) then
			delete from 	pg_trn_tfunddisbtranche 
			where 			funddisbtranche_gid = _funddisbtranche_gid;
			
			v_succ_code := 'SB05FDTCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tfunddisbtranche
					  where		funddisbtranche_gid = _funddisbtranche_gid
					  and 		pg_id = _pg_id
					 ) then
			insert into  pg_trn_tfunddisbtranche
			(
				pg_id,
				funddisb_id,
				tranche_no,
				tranche_amount,
				tranche_date,
				tranche_status_code,
				received_date,
				received_ref_no,
				sync_status_code,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_funddisb_id,
				_tranche_no,
				_tranche_amount,
				_tranche_date,
				_tranche_status_code,
				_received_date,
				_received_ref_no,
				'W',
				_user_code,
				now()
				
			) returning funddisbtranche_gid into _funddisbtranche_gid;
			
			v_succ_code := 'SB05FDTCUD_001';
			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tfunddisbtranche
				   where	funddisbtranche_gid = _funddisbtranche_gid
				   and 		tranche_status_code = 'QCD_DISB'
				   ) then
			update	pg_trn_tfunddisbtranche 
			set 	pg_id = _pg_id,
					funddisb_id = _funddisb_id,
					tranche_no = _tranche_no,
					tranche_amount = _tranche_amount,
					tranche_date = _tranche_date,
					tranche_status_code = _tranche_status_code,
					received_date = _received_date,
					received_ref_no = _received_ref_no,
					sync_status_code = _sync_status_code,
					updated_by = _user_code,
					updated_date = now()
			where 	funddisbtranche_gid = _funddisbtranche_gid 
			and		tranche_status_code = 'QCD_DISB';
			
			v_succ_code := 'SB05FDTCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_trn_tfunddisbtranche
			    where 	pg_id = _pg_id
			   	and 	funddisb_id = _funddisb_id
			   	and 	tranche_no = _tranche_no
				group	by pg_id
				having	count('*') > 1) 
	then
		-- Duplicated Record
		v_err_code := v_err_code || 'VB00CMNCMN_008';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_008', _lang_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_funddisbtranche_update(_funddisbtranche_gid udd_int, _received_date udd_date, _received_ref_no udd_code, _lang_code udd_code, _user_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare	
	/*
		Created By : Mohan S
		Created Date : 16-02-2022
		SP Code : B05FTUXUX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation	
	-- recieved date cannot be blank
	if _received_date is null then
		v_err_code := v_err_code || 'VB05FTUXUX_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FTUXUX_001', _lang_code) || v_new_line;
	end if;
	
	-- recieved refno cannot be blank
	if _received_ref_no = '' then
		v_err_code := v_err_code || 'VB05FTUXUX_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FTUXUX_002', _lang_code) || v_new_line;
	end if;
	
	-- Disbusrsement status check
	if not exists(select 	*
				   from 	pg_trn_tfunddisbtranche
				   where	funddisbtranche_gid = _funddisbtranche_gid
				   and 		tranche_status_code = 'QCD_DISB')then
		v_err_code := v_err_code || 'VB05FTUXUX_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FTUXUX_003', _lang_code) || v_new_line;	   
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
		
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	

		if  exists(select 	*
				   from 	pg_trn_tfunddisbtranche
				   where	funddisbtranche_gid = _funddisbtranche_gid
				   ) then
			update	pg_trn_tfunddisbtranche 
			set 	
					tranche_status_code = 'QCD_RCVD',
					received_date = _received_date,
					received_ref_no = _received_ref_no,
					updated_by = _user_code,
					updated_date = now()
			where 	funddisbtranche_gid = _funddisbtranche_gid 
			and		tranche_status_code = 'QCD_DISB';
			
			v_succ_code := 'SB05FDTCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	
	if v_succ_code <> '' then
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_funddisbursement(INOUT _funddisb_gid udd_int, _pg_id udd_code, _fundreq_id udd_code, INOUT _funddisb_id udd_code, _loan_acc_no udd_code, _routing_inst_code udd_code, _source_inst_code udd_code, _funddisb_type_code udd_code, _sanctioned_date udd_date, _sanctioned_amount udd_amount, _interest_rate udd_rate, _repymt_tenure udd_numeric, _repymt_freq_code udd_code, _collateral_type_code udd_code, _collateral_amount udd_amount, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, _row_timestamp udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare	
	/*
		Created By : Mohan S
		Created Date : 31-12-2021
		SP Code : B05FDBCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_seqno udd_int := 0;
    v_pg_name udd_code := '';
	v_tot_sancamt udd_amount := 0;
	v_tot_fundreq_amount udd_amount := 0;
	v_tranche_amount udd_amount := 0;
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FDBCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- fundreq id validation
		if not exists (select   * 
				   from 	pg_trn_tfundrequisition
				   where 	pg_id = _pg_id
				   and		fundreq_id = _fundreq_id 
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FDBCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_002', _lang_code) || v_new_line;	
	end if;
	
	-- routing inst code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ROUTE_INST'
				   and 		master_code = _routing_inst_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05FDBCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_003', _lang_code) || v_new_line;	
	end if;
	
	-- source inst code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_FUND_SOURCE'
				   and 		master_code = _source_inst_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05FDBCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_004', _lang_code) || v_new_line;	
	end if;
	
	-- fiunddisb type code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_FUND_TYPE'
				   and 		master_code = _funddisb_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05FDBCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_005', _lang_code) || v_new_line;	
	end if;
	
	-- sanctioned date cannot be null
	if _sanctioned_date is null  then
		v_err_code := v_err_code || 'VB05FDBCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_006', _lang_code) || v_new_line;
	end if;
	
	-- sanctioned amt cannot be blank
	if _sanctioned_amount <= 0 then
		v_err_code := v_err_code || 'VB05FDBCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_007', _lang_code) || v_new_line;
	end if;
	
	-- Getting total funreq amt
	select  coalesce(sum(fundreq_amount),0) into v_tot_fundreq_amount
	from 	pg_trn_tfundrequisitiondtl
	where 	pg_id = _pg_id
	and     fundreq_id = _fundreq_id;
	
	-- Getting total sanctioned amt
	select  coalesce(sum(sanctioned_amount),0) into v_tot_sancamt
	from 	pg_trn_tfunddisbursement 
	where 	pg_id = _pg_id 
	and     fundreq_id = _fundreq_id
	and 	funddisb_gid <> _funddisb_gid
	and 	status_code = 'A';
	
	-- Getting total tranche amt
	select  coalesce(sum(tranche_amount),0) into v_tranche_amount
	from 	pg_trn_tfunddisbtranche
	where 	pg_id = _pg_id
	and     funddisb_id = _funddisb_id;
	
	-- tranche amt should not be greater than sanction amount
	if _mode_flag = 'U' then
		if _sanctioned_amount < v_tranche_amount   then
			v_err_code := v_err_code || 'VB05FDBCUD_013' || ',';
			v_err_msg  := v_err_msg ||   fn_get_msg('VB05FDBCUD_013', _lang_code) || v_new_line;
		end if;	
	end if;	
	
	-- Sanctioned amount validation
	v_tot_sancamt := v_tot_fundreq_amount - v_tot_sancamt ;
	
	if v_tot_sancamt < _sanctioned_amount then
		v_err_code := v_err_code || 'VB05FDBCUD_012' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_012', _lang_code) || v_new_line;
	end if;
	
if _funddisb_type_code <> 'GRANT' then
	-- intrested rate cannot be blank
	if _interest_rate <= 0 then
		v_err_code := v_err_code || 'VB05FDBCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_008', _lang_code) || v_new_line;
	end if;
	
	-- repayment tenure cannot be blank
	if _repymt_tenure <= 0 then
		v_err_code := v_err_code || 'VB05FDBCUD_009' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_009', _lang_code) || v_new_line;
	end if;
	
	-- repayment freqcode validation
	if(_repymt_freq_code <> '')then
		if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = 'QCD_PYMT_FREQ'
					   and 		master_code = _repymt_freq_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB05FDBCUD_010' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_010', _lang_code) || v_new_line;	
		end if;
	end if;
	
	-- collateral typecode validation
	if(_collateral_type_code <> '') then
		if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = 'QCD_COLLATERAL_TYPE'
					   and 		master_code = _collateral_type_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB05FDBCUD_011' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_011', _lang_code) || v_new_line;	
		end if;
	end if;
end if;
	
	-- status code validation
	if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = 'QCD_FUNDDISB_STATUS'
					   and 		master_code = _status_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;	
	end if;
	
	-- timestamp check for concurrency
	select 	to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') into v_timestamp 
	from 	pg_trn_tfunddisbursement
	where	funddisb_gid = _funddisb_gid;
	
	v_timestamp	:= coalesce(v_timestamp, '');
	
	IF (v_timestamp != _row_timestamp) 
	then
		-- Record modified since last fetch so Kindly refetch and continue
		v_err_code := v_err_code || 'VB00CMNCMN_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_002', _lang_code) || v_new_line;	
	end if;
		
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tfunddisbursement
				  where 	funddisb_gid = _funddisb_gid
				 ) then
			update 			pg_trn_tfunddisbursement 
			set 			status_code = 'I',
							updated_date = now(),
							updated_by = _user_code,
							row_timestamp = now()
			where 			funddisb_gid = _funddisb_gid;
			
			v_succ_code := 'SB05FDBCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tfunddisbursement
					  where		funddisb_gid = _funddisb_gid
					  and 		pg_id = _pg_id
					 ) then
		
		--Funddisb id generation
		select fn_get_docseqno('FDID') into v_seqno ;
		select upper(substring(pg_name,1,2)) into v_pg_name
		from pg_mst_tproducergroup where pg_id = _pg_id;
		select CONCAT(upper(substring 
							 (regexp_replace(v_pg_name collate pg_catalog.""default"", '[^a-zA-Z]', '', 'g')
							  ,1,2)),
					  case 
							when length(v_seqno::udd_text)>5 then v_seqno::udd_text 
					  else 
					  to_char(v_seqno,'fm00000') end) into _funddisb_id ;
					  
			insert into  pg_trn_tfunddisbursement
			(
				pg_id,
				fundreq_id,
				funddisb_id,
				loan_acc_no,
				routing_inst_code,
				source_inst_code,
				funddisb_type_code,
				sanctioned_date,
				sanctioned_amount,
				interest_rate,
				repymt_tenure,
				repymt_freq_code,
				collateral_type_code,
				collateral_amount,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				_pg_id,
				_fundreq_id,
				_funddisb_id,
				_loan_acc_no,
				_routing_inst_code,
				_source_inst_code,
				_funddisb_type_code,
				_sanctioned_date,
				_sanctioned_amount,
				_interest_rate,
				_repymt_tenure,
				_repymt_freq_code,
				_collateral_type_code,
				_collateral_amount,
				_status_code,
				_user_code,
				now(),
				now()
				
			) returning funddisb_gid,funddisb_id into _funddisb_gid,_funddisb_id;
			
			v_succ_code := 'SB05FDBCUD_001';
			
			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tfunddisbursement
				   where	funddisb_gid = _funddisb_gid 
				   ) then
			update	pg_trn_tfunddisbursement 
			set 	pg_id = _pg_id,
					fundreq_id = _fundreq_id,
					funddisb_id = _funddisb_id,
					loan_acc_no = _loan_acc_no,
					routing_inst_code = _routing_inst_code,
					source_inst_code = _source_inst_code,
					funddisb_type_code = _funddisb_type_code,
					sanctioned_date = _sanctioned_date,
					sanctioned_amount = _sanctioned_amount,
					interest_rate = _interest_rate,
					repymt_tenure = _repymt_tenure,
					repymt_freq_code = _repymt_freq_code,
					collateral_type_code = _collateral_type_code,
					collateral_amount = _collateral_amount,
					status_code = _status_code,
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	funddisb_gid = _funddisb_gid ;
			
			v_succ_code := 'SB05FDBCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_trn_tfunddisbursement
			    where 	pg_id = _pg_id
			    and 	funddisb_gid = _funddisb_gid
				group	by pg_id
				having	count('*') > 1) 
	then
		-- duplicated record 
		v_err_code := v_err_code || 'VB00CMNCMN_008';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_008', _lang_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_fundrepymt(INOUT _fundrepymt_gid udd_int, _pg_id udd_code, _loan_acc_no udd_code, _pymt_date udd_date, _pay_mode_code udd_code, _paid_amount udd_amount, _pymt_ref_no udd_code, _principal_amount udd_amount, _interest_amount udd_amount, _other_amount udd_amount, _pymt_remarks udd_text, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 03-01-2021
		SP Code : B05FRPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id				  
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)|| v_new_line;
	end if;
	
	-- loc acc no validation
	if not exists (select 	* 
				   from 	pg_trn_tfunddisbursement 
				   where 	pg_id 		= _pg_id	
					and 	loan_acc_no = _loan_acc_no
				  ) then
		v_err_code := v_err_code || 'VB05FRPCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_001', _lang_code)|| v_new_line;
	end if;
	
	-- payment date cannot be blank
	if _pymt_date is Null then
		v_err_code := v_err_code || 'VB05FRPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- payment date cannot future
	if _pymt_date > CAST(now() AS DATE) 
	 then
		v_err_code := v_err_code || 'VB05FRPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_003', _lang_code)  || v_new_line;	
	end if;
	
	-- pay_mode_code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PAY_MODE'
				   and 		master_code = _pay_mode_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05FRPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_004', _lang_code) || v_new_line;	
	end if;
		
	-- paid amount validation
	_paid_amount := _principal_amount + _interest_amount + _other_amount;
	
	if _paid_amount <= 0 
	 then
		v_err_code := v_err_code || 'VB05FRPCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_005', _lang_code)  || v_new_line;	
	end if;
	
	
	
	-- pymt_ref_no cannot be blank
	if _pymt_ref_no = '' then
		v_err_code := v_err_code || 'VB05FRPCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_006', _lang_code) || v_new_line;
	end if;
	
	-- principal_amount validation
	if _principal_amount < 0 
	 then
		v_err_code := v_err_code || 'VB05FRPCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_007', _lang_code)  || v_new_line;	
	end if;
	
	-- interest_amount validation
	if _interest_amount < 0 
	 then
		v_err_code := v_err_code || 'VB05FRPCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_008', _lang_code)  || v_new_line;	
	end if;
	
	-- other_amount validation
	if _other_amount < 0 
	 then
		v_err_code := v_err_code || 'VB05FRPCUD_009' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRPCUD_009', _lang_code)  || v_new_line;	
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tfundrepymt
				  where 	fundrepymt_gid = _fundrepymt_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	pg_trn_tfundrepymt
			set		status_code 		= 'I',
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	fundrepymt_gid 		= _fundrepymt_gid 
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB05FRPCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tfundrepymt
					  where		fundrepymt_gid 		= _fundrepymt_gid
					  and 		status_code = 'A'
					 ) then
			insert into pg_trn_tfundrepymt 
			(
				pg_id,
				loan_acc_no,
				pymt_date,
				pay_mode_code,
				paid_amount,
				pymt_ref_no,
				principal_amount,
				interest_amount,
				other_amount,
				pymt_remarks,
				status_code,
				created_by,
				created_date			
			)
			values
			(
				_pg_id,
				_loan_acc_no,
				_pymt_date,
				_pay_mode_code,
				_paid_amount,
				_pymt_ref_no,
				_principal_amount,
				_interest_amount,
				_other_amount,
				_pymt_remarks,
				_status_code,
				_user_code,
				now()
				
			) returning fundrepymt_gid into _fundrepymt_gid;			
			v_succ_code := 'SB05FRPCUD_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;	
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tfundrepymt
				   where	fundrepymt_gid 	= _fundrepymt_gid 
				   and 		status_code = 'A'
				   ) then
			update	pg_trn_tfundrepymt 
			set	    loan_acc_no			= _loan_acc_no,
					pymt_date 			= _pymt_date,
					pay_mode_code  		= _pay_mode_code ,
					paid_amount  		= _paid_amount ,
					pymt_ref_no  		= _pymt_ref_no ,
					principal_amount  	= _principal_amount ,
					interest_amount 	= _interest_amount,
					other_amount 		= _other_amount,
					pymt_remarks 		= _pymt_remarks,
					status_code 		= _status_code,
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	fundrepymt_gid	= _fundrepymt_gid
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB05FRPCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;		
	end if;
	
	if exists (	select	count(*)
				from 	pg_trn_tfundrepymt
			    where 	pg_id 			= _pg_id 
			    and     loan_acc_no 	= _loan_acc_no
				and     pymt_date 		= _pymt_date
				and     pay_mode_code 	= _pay_mode_code
				and     paid_amount 	= _paid_amount
				and     pymt_ref_no 	= _pymt_ref_no
				group	by pg_id,loan_acc_no, pymt_date, pay_mode_code, paid_amount, pymt_ref_no
				having	count('*') > 1) 
	then
		-- pg id cannot be duplicated
		v_err_code := v_err_code || 'VB00CMNCMN_008';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('VB00CMNCMN_008', _lang_code),_pg_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
			
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_fundreqattachment(INOUT _fundreqattachment_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _fundreq_id udd_code, _doc_type_code udd_code, _doc_subtype_code udd_code, _file_path udd_text, _file_name udd_desc, _attachment_remark udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 01-02-2022
		SP Code : B05FRACUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- bp id validation
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	pg_id = _pg_id
				   and 		bussplan_id = _bussplan_id
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_010' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_010', _lang_code) || v_new_line;	
	end if;
	
	-- fundreq id validation
	if not exists (select   * 
				   from 	pg_trn_tfundrequisition
				   where 	pg_id = _pg_id
				   and 		bussplan_id = _bussplan_id
				   and 		fundreq_id = _fundreq_id
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_011' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_011', _lang_code) || v_new_line;	
	end if;
	
	-- Doctype code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where	parent_code = 'QCD_DOC_TYPE'
				   and 		master_code = _doc_type_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05FRACUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRACUD_001', _lang_code) || v_new_line;
	end if;	
	
	-- DocSubtype code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where	parent_code = 'QCD_DOC_SUBTYPE'
				   and 		master_code = _doc_subtype_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05FRACUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRACUD_002', _lang_code) || v_new_line;
	end if;	
	
	/*-- filepath cannot be balnk
	if _file_path = '' then
		v_err_code := v_err_code || 'VB05FRACUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRACUD_003', _lang_code) || v_new_line;
	end if;*/
	
	-- filename cannot be balnk
	if _file_name = '' then
		v_err_code := v_err_code || 'VB05FRACUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRACUD_004', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tfundreqattachment
				  where 	fundreqattachment_gid = _fundreqattachment_gid
				 ) then
				 
			delete   from 	pg_trn_tfundreqattachment
			where 	fundreqattachment_gid = _fundreqattachment_gid;
			
			v_succ_code := 'SB05FRACUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tfundreqattachment
					  where		fundreqattachment_gid = _fundreqattachment_gid
					 ) then
			insert into pg_trn_tfundreqattachment 
			(
				pg_id,
				bussplan_id,
				fundreq_id,
				doc_type_code,
				doc_subtype_code,
				file_path,
				file_name,
				attachment_remark,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bussplan_id,
				_fundreq_id,
				_doc_type_code,
				_doc_subtype_code,
				_file_path,
				_file_name,
				_attachment_remark,
				_user_code,
				now()
			) returning fundreqattachment_gid into _fundreqattachment_gid;
			
			v_succ_code := 'SB05FRACUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tfundreqattachment
				   where	fundreqattachment_gid = _fundreqattachment_gid
				   ) then
			update	pg_trn_tfundreqattachment 
			set 	pg_id = _pg_id,
					bussplan_id = _bussplan_id,
					fundreq_id = _fundreq_id,
					doc_type_code = _doc_type_code,
					doc_subtype_code = _doc_subtype_code,
					file_path = _file_path,
					file_name = _file_name,
					attachment_remark = _attachment_remark,
					updated_by = _user_code,
					updated_date = now()
			where 	fundreqattachment_gid = _fundreqattachment_gid;
			
			v_succ_code := 'SB05FRACUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_fundrequisition(INOUT _fundreq_gid udd_int, INOUT _pg_id udd_code, _blockofficer_id udd_code, INOUT _bussplan_id udd_code, INOUT _fundreq_id udd_code, _tot_fundreq_amount udd_amount, _reviewer_type_code udd_code, _clf_block_id udd_int, _reviewer_code udd_code, _reviewer_name udd_desc, _fundreq_remark udd_text, _fundreq_purpose udd_text, _last_action_date udd_datetime, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, _row_timestamp udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 29-12-2021
		SP Code : B04FRQCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_seqno udd_int := 0;
    v_pg_name udd_code := '';
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB05FRQCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- block officer id cannot be blank
	if _blockofficer_id = '' then
		v_err_code := v_err_code || 'VB05FRQCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB05FRQCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_003', _lang_code) || v_new_line;	
	end if;
	
	-- total fundreq amt cannot be blank
	if _tot_fundreq_amount <= 0 then
		v_err_code := v_err_code || 'VB05FRQCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- reviewer type code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_REVIEWER_TYPE'
				   and 		master_code = _reviewer_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05FRQCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_005', _lang_code)|| v_new_line;	
	end if;

	/*if _reviewer_type_code = 'QCD_CLF' then
		-- clf block id cannot be blank
		if _clf_block_id <= 0 then
			v_err_code := v_err_code || 'VB05FRQCUD_006' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_006', _lang_code) || v_new_line;
		end if;
	end if;*/
	
	-- reviewer code cannot be blank
	if _reviewer_code = '' then
		v_err_code := v_err_code || 'VB05FRQCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_007', _lang_code) || v_new_line;
	end if;
	
	-- reviewer name cannot be blank
	if _reviewer_name = '' then
		v_err_code := v_err_code || 'VB05FRQCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRQCUD_008', _lang_code) || v_new_line;
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code);	
	end if;

	-- timestamp check for concurrency
	select 	to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') into v_timestamp 
	from 	pg_trn_tfundrequisition
	where	fundreq_gid = _fundreq_gid;
	
	v_timestamp	:= coalesce(v_timestamp, '');
	
	IF (v_timestamp != _row_timestamp) 
	then
		-- Record modified since last fetch so Kindly refetch and continue
		v_err_code := v_err_code || 'VB00CMNCMN_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_002', _lang_code) || v_new_line;	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tfundrequisition
				  where 	fundreq_gid = _fundreq_gid
				  and 		pg_id = _pg_id
				 ) then
			Update 	pg_trn_tfundrequisition
			set		status_code = 'I',
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	fundreq_gid = _fundreq_gid
			and 	pg_id = _pg_id;
			
			v_succ_code := 'SB05FRQCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tfundrequisition
					  where		fundreq_gid = _fundreq_gid
					  and 		pg_id = _pg_id
					 ) then
					 
		--Fundreq id generation
		select fn_get_docseqno('FRID') into v_seqno ;
		select upper(substring(pg_name,1,2)) into v_pg_name
		from pg_mst_tproducergroup where pg_id = _pg_id;
		select CONCAT(upper(substring 
							 (regexp_replace(v_pg_name collate pg_catalog.""default"", '[^a-zA-Z]', '', 'g')
							  ,1,2)),
					  case 
							when length(v_seqno::udd_text)>5 then v_seqno::udd_text 
					  else 
					  to_char(v_seqno,'fm00000') end) into _fundreq_id ;
					  
			insert into pg_trn_tfundrequisition 
			(
				pg_id,
				blockofficer_id,
				bussplan_id,
				fundreq_id,
				tot_fundreq_amount,
				reviewer_type_code,
				clf_block_id,
				reviewer_code,
				reviewer_name,
				fundreq_remark,
				fundreq_purpose,
				last_action_date,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				_pg_id,
				_blockofficer_id,
				_bussplan_id,
				_fundreq_id,
				_tot_fundreq_amount,
				_reviewer_type_code,
				_clf_block_id,
				_reviewer_code,
				_reviewer_name,
				_fundreq_remark,
				_fundreq_purpose,
				now(),
				_status_code,
				_user_code,
				now(),
				now()
			) returning fundreq_gid into _fundreq_gid;
			
			-- pg_id,bussplan_id,fundreq_id value Setted
			select	 pg_id,bussplan_id,fundreq_id 
			into 	_pg_id,_bussplan_id,_fundreq_id
			from 	 pg_trn_tfundrequisition
			where 	 fundreq_gid = _fundreq_gid;
			
			--Fundreq_id updated in Bussplan table
			update  pg_trn_tbussplan 
			set     fundreq_id = _fundreq_id
			where   bussplan_id = _bussplan_id
			and 	pg_id = _pg_id;
			
			v_succ_code := 'SB05FRQCUD_001';
			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tfundrequisition
				   where	fundreq_gid = _fundreq_gid 
				   ) then
			update	pg_trn_tfundrequisition 
			set 	pg_id = _pg_id,
					blockofficer_id = _blockofficer_id,
					bussplan_id = _bussplan_id,
					fundreq_id = _fundreq_id,
					tot_fundreq_amount = _tot_fundreq_amount,
					reviewer_type_code = _reviewer_type_code,
					clf_block_id = _clf_block_id,
					reviewer_code = _reviewer_code,
					reviewer_name = _reviewer_name,
					fundreq_remark = _fundreq_remark,
					fundreq_purpose = _fundreq_purpose,
					last_action_date = now(),
					status_code = _status_code,
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	fundreq_gid = _fundreq_gid ;
			
			v_succ_code := 'SB05FRQCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_trn_tfundrequisition
			    where 	pg_id = _pg_id
			    and 	fundreq_id = _fundreq_id
				group	by pg_id
				having	count('*') > 1) 
	then
		-- duplicated record
		v_err_code := v_err_code || 'VB00CMNCMN_008';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_008', _lang_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		if _status_code = 'D' then
				v_succ_code := 'SB05FRQCUD_001';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
			elseif _status_code = 'R' then
				v_succ_code := 'SB05FRQCUD_003';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
			elseif _status_code = 'S' then
				v_succ_code := 'SB05FRQCUD_004';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
			elseif _status_code = 'A' then
				v_succ_code := 'SB05FRQCUD_005';
				_succ_msg := v_succ_code || '-' ||fn_get_msg(v_succ_code,_lang_code);
		 end if;
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_fundrequisitiondtl(INOUT _fundreqdtl_gid udd_int, _pg_id udd_code, _blockofficer_id udd_code, _bussplan_id udd_code, _fundreq_id udd_code, _routing_inst_code udd_code, _fundreq_head_code udd_code, _fundreq_amount udd_amount, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 31-12-2021
		SP Code : B05FRDCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FRDCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRDCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- block officer id cannot be blank
	if _blockofficer_id = '' then
		v_err_code := v_err_code || 'VB05FRDCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRDCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB05FRDCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRDCUD_003', _lang_code) || v_new_line;	
	end if;
	
	-- fundreq id validation
	if not exists (select   * 
				   from 	pg_trn_tfundrequisition
				   where 	fundreq_id = _fundreq_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB05FRDCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRDCUD_004', _lang_code) || v_new_line;	
	end if;
	
	-- routing inst code validation
	if not exists (select   * 
				   from 	core_mst_tmaster
				   where 	parent_code = 'QCD_ROUTE_INST'
				   and 		master_code = _routing_inst_code 
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FRDCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRDCUD_005', _lang_code) || v_new_line;	
	end if;
	
	-- fundreq head code validation
	if not exists (select   * 
				   from 	core_mst_tmaster
				   where 	parent_code = 'QCD_FUNDREQ_HEAD'
				   and 		master_code = _fundreq_head_code 
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FRDCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRDCUD_006', _lang_code) || v_new_line;	
	end if;
	
	-- fundreq amt cannot be blank
	if _fundreq_amount <= 0 then
		v_err_code := v_err_code || 'VB05FRDCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FRDCUD_007', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tfundrequisitiondtl
				  where 	fundreq_gid = _fundreqdtl_gid
				 ) then
			delete from		pg_trn_tfundrequisitiondtl
			where 			fundreq_gid = _fundreqdtl_gid;
			
			v_succ_code := 'SB05FRDCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tfundrequisitiondtl
					  where		fundreq_gid = _fundreqdtl_gid
					  and 		pg_id = _pg_id
					 ) then
			insert into pg_trn_tfundrequisitiondtl 
			(
				pg_id,
				blockofficer_id,
				bussplan_id,
				fundreq_id,
				routing_inst_code,
				fundreq_head_code,
				fundreq_amount,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_blockofficer_id,
				_bussplan_id,
				_fundreq_id,
				_routing_inst_code,
				_fundreq_head_code,
				_fundreq_amount,
				_user_code,
				now()
			) returning fundreq_gid into _fundreqdtl_gid;
			
			v_succ_code := 'SB05FRDCUD_001';
			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tfundrequisitiondtl
				   where	fundreq_gid = _fundreqdtl_gid 
				   ) then
			update	pg_trn_tfundrequisitiondtl 
			set 	pg_id = _pg_id,
					blockofficer_id = _blockofficer_id,
					bussplan_id = _bussplan_id,
					fundreq_id = _fundreq_id,
					routing_inst_code = _routing_inst_code,
					fundreq_head_code = _fundreq_head_code,
					fundreq_amount = _fundreq_amount,
					updated_by = _user_code,
					updated_date = now()
			where 	fundreq_gid = _fundreqdtl_gid ;
			
			v_succ_code := 'SB05FRDCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_trn_tfundrequisitiondtl
			    where 	pg_id = _pg_id  
			    and 	fundreq_id = _fundreq_id
			    and 	routing_inst_code = _routing_inst_code
			    and 	fundreq_head_code = _fundreq_head_code
				group	by pg_id
				having	count('*') > 1) 
	then
		-- duplicated record
		v_err_code := v_err_code || 'VB00CMNCMN_008';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_008', _lang_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg('SB05FRQCUD_002',_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_honorarium(INOUT _honorarium_gid udd_int, _pg_id udd_code, _udyogmitra_id udd_code, _record_date udd_date, _period_from udd_date, _period_to udd_date, _honorarium_amount udd_amount, _honorarium_remark udd_text, _sync_status_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 07-02-2022
		SP Code      : B06PPQCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id       = _pg_id 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- Udyogmitra ID Validation
	if not exists (select * from pg_mst_tudyogmitra
				   where udyogmitra_id    = _udyogmitra_id)
	then
		v_err_code := v_err_code || 'VB00CMNCMN_014' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_014', _lang_code) || v_new_line;
	end if;	
	
-- Record Date Validation
	if _record_date isnull
	then
		v_err_code := v_err_code || 'VB06HONCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06HONCUD_001', _lang_code) || v_new_line;
	end if;
	
-- Period From Validation
	if _period_from isnull
	then
		v_err_code := v_err_code || 'VB06HONCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06HONCUD_002', _lang_code) || v_new_line;
	end if;
	
-- Period From Validation
	if _period_to isnull
	then
		v_err_code := v_err_code || 'VB06HONCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06HONCUD_003', _lang_code) || v_new_line;
	end if;
	
-- Honorarium Amount Validation
	if _honorarium_amount < 0
	then
		v_err_code := v_err_code || 'VB06HONCUD_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06HONCUD_004', _lang_code) || v_new_line;
	end if;
	
-- Honorarium Remark Validation
	if _honorarium_remark = ''
	then
		v_err_code := v_err_code || 'VB06HONCUD_005' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06HONCUD_005', _lang_code) || v_new_line;
	end if;
	
-- Sync Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_SYNC_STATUS' 
				   and master_code = _sync_status_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_013', _lang_code) || v_new_line;		
	end if;
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_STATUS' and master_code = _status_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;

-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;

	if _mode_flag = 'D' then
		if exists(select * from pg_trn_thonorarium
				  where honorarium_gid = _honorarium_gid
				  and status_code <> 'I')
			then
			update pg_trn_thonorarium 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where honorarium_gid 	= _honorarium_gid;
			v_succ_code := 'SB06HONCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;

	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_thonorarium
				       where  honorarium_gid = _honorarium_gid
				       and    pg_id 		 = _pg_id)
		 then
			insert into pg_trn_thonorarium(
				pg_id,
				udyogmitra_id,
				record_date,
				period_from,
				period_to,
				honorarium_amount,
				honorarium_remark,
				sync_status_code,
				status_code,
				created_date,
				created_by)
			values(
				_pg_id,
				_udyogmitra_id,
				_record_date,
				_period_from,
				_period_to,
				_honorarium_amount,
				_honorarium_remark,
				_sync_status_code,
				_status_code,
				now(),
				_user_code) returning honorarium_gid into _honorarium_gid;
				v_succ_code := 'SB06HONCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if; 

	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_thonorarium
				   where honorarium_gid = _honorarium_gid)
		then
		update pg_trn_thonorarium
		set		pg_id			= _pg_id,
				udyogmitra_id	= _udyogmitra_id,
				record_date		= _record_date,
				period_from		= _period_from,
				period_to		= _period_to,
				honorarium_amount	= _honorarium_amount,
				honorarium_remark	= _honorarium_remark,
				sync_status_code	= _sync_status_code,
				status_code			= _status_code,
				updated_date		= now(),
				updated_by			= _user_code
		where   honorarium_gid        = _honorarium_gid;
		v_succ_code	:= 'SB06HONCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
		 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_thonorarium
			     where 	pg_id			= _pg_id
				and     udyogmitra_id	= _udyogmitra_id
				and     period_from		= _period_from
				and     period_to		= _period_to
			    group	by pg_id, udyogmitra_id, period_from, period_to
				having	count('*') > 1) 
	then
		-- pg id,udyogmitra_id, period_from and period_to cannot be duplicated
		v_err_code := v_err_code || 'EB06HONCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06HONCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_incomeexpense(INOUT _incomeexpense_gid udd_int, _pg_id udd_code, _acchead_type_code udd_code, _acchead_code udd_code, _tran_date udd_date, _dr_amount udd_amount, _cr_amount udd_amount, _narration_code udd_code, _tran_ref_no udd_text, _tran_remark udd_text, _pay_mode_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 03-01-2021
		SP Code : B05IEXCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id				  
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)|| v_new_line;
	end if;
	
	-- acchead_type_code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ACC_HEAD_TYPE'
				   and 		master_code = _acchead_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05IEXCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- acchead_code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ACC_HEAD'
				   and 		master_code = _acchead_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05IEXCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_002', _lang_code) || v_new_line;	
	end if;
	
	-- tran_date cannot be blank
	if _tran_date is Null then
		v_err_code := v_err_code || 'VB05IEXCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- tran_date cannot future
	if _tran_date > CAST(now() AS DATE) 
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_004', _lang_code)  || v_new_line;	
	end if;
	
	/*-- dr_amount cannot be blank
	if _dr_amount < 0 
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_005', _lang_code)  || v_new_line;	
	end if;
	
	-- cr_amount cannot be blank
	if _cr_amount < 0 
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_006', _lang_code)  || v_new_line;
	end if;*/
	
	-- Debit Amount Validation
	if _acchead_type_code = 'QCD_EXPENSE'
	then 
		if _dr_amount <= 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_005' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_005', _lang_code) || v_new_line;		
		end if;
		if _cr_amount <> 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_010' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_010', _lang_code) || v_new_line;		
		end if;
	end if;
	
	-- Credit Amount Validation
	if _acchead_type_code = 'QCD_INCOME'
	then 
		if _cr_amount <= 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_006' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_006', _lang_code) || v_new_line;		
		end if;
		if _dr_amount <> 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_011' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_011', _lang_code) || v_new_line;		
		end if;
	end if;
	
	-- either debit or cr_amount validation
	if _cr_amount < 0  or  _dr_amount < 0
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_007', _lang_code)  || v_new_line;
	end if;
	
	-- narration code validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_ACC_NARRATION' 
				   and master_code = _narration_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB05IEXCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_008', _lang_code) || v_new_line;		
	end if;
	
	-- paymode validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_PAY_MODE' 
				   and master_code = _pay_mode_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB05IEXCUD_009' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_009', _lang_code) || v_new_line;		
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tincomeexpense
				  where 	incomeexpense_gid = _incomeexpense_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	pg_trn_tincomeexpense
			set		status_code 		= 'I',
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	incomeexpense_gid 	= _incomeexpense_gid 
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB05IEXCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tincomeexpense
					  where		incomeexpense_gid = _incomeexpense_gid
					  and 		pg_id 		= _pg_id
					  and 		status_code = 'A'
					 ) then
			insert into pg_trn_tincomeexpense 
			(
				pg_id,
				acchead_type_code,
				acchead_code,
				tran_date,
				dr_amount,
				cr_amount,
				narration_code,
				tran_ref_no,
				tran_remark,
				pay_mode_code,
				status_code,
				created_by,
				created_date			
			)
			values
			(
				_pg_id,
				_acchead_type_code,
				_acchead_code,
				_tran_date,
				_dr_amount,
				_cr_amount,
				_narration_code,
				_tran_ref_no,
				_tran_remark,
				_pay_mode_code,
				_status_code,
				_user_code,
				now()
				
			) returning incomeexpense_gid into _incomeexpense_gid;			
			v_succ_code := 'SB05IEXCUD_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;	
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tincomeexpense
				   where	incomeexpense_gid 	= _incomeexpense_gid 
				   and 		status_code = 'A'
				   ) then
			update	pg_trn_tincomeexpense 
			set	    acchead_type_code	= _acchead_type_code,
					acchead_code 		= _acchead_code,
					tran_date 			= _tran_date,
					dr_amount 			= _dr_amount,
					cr_amount 			= _cr_amount,
					narration_code 		= _narration_code,
					tran_ref_no 		= _tran_ref_no,
					tran_remark 		= _tran_remark,
					pay_mode_code		= _pay_mode_code,
					status_code 		= _status_code,
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	incomeexpense_gid	= _incomeexpense_gid
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB05IEXCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;			
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
			
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_incomeexpense_old(INOUT _incomeexpense_gid udd_int, _pg_id udd_code, _acchead_type_code udd_code, _acchead_code udd_code, _tran_date udd_date, _dr_amount udd_amount, _cr_amount udd_amount, _narration_code udd_code, _tran_ref_no udd_text, _tran_remark udd_text, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 03-01-2021
		SP Code : B05IEXCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id				  
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)|| v_new_line;
	end if;
	
	-- acchead_type_code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ACC_HEAD_TYPE'
				   and 		master_code = _acchead_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05IEXCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- acchead_code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ACC_HEAD'
				   and 		master_code = _acchead_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB05IEXCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_002', _lang_code) || v_new_line;	
	end if;
	
	-- tran_date cannot be blank
	if _tran_date is Null then
		v_err_code := v_err_code || 'VB05IEXCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- tran_date cannot future
	if _tran_date > CAST(now() AS DATE) 
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_004', _lang_code)  || v_new_line;	
	end if;
	
	-- dr_amount cannot be blank
	if _dr_amount < 0 
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_005', _lang_code)  || v_new_line;	
	end if;
	
	-- cr_amount cannot be blank
	if _cr_amount < 0 
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_006', _lang_code)  || v_new_line;
	end if;
	
	-- either debit or cr_amount validation
	if _cr_amount < 0  or  _dr_amount < 0
	 then
		v_err_code := v_err_code || 'VB05IEXCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_007', _lang_code)  || v_new_line;
	end if;
	
	-- narration code validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_ACC_NARRATION' 
				   and master_code = _narration_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB05IEXCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05IEXCUD_008', _lang_code) || v_new_line;		
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tincomeexpense
				  where 	incomeexpense_gid = _incomeexpense_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	pg_trn_tincomeexpense
			set		status_code 		= 'I',
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	incomeexpense_gid 	= _incomeexpense_gid 
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB05IEXCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tincomeexpense
					  where		incomeexpense_gid = _incomeexpense_gid
					  and 		pg_id 		= _pg_id
					  and 		status_code = 'A'
					 ) then
			insert into pg_trn_tincomeexpense 
			(
				pg_id,
				acchead_type_code,
				acchead_code,
				tran_date,
				dr_amount,
				cr_amount,
				narration_code,
				tran_ref_no,
				tran_remark,
				status_code,
				created_by,
				created_date			
			)
			values
			(
				_pg_id,
				_acchead_type_code,
				_acchead_code,
				_tran_date,
				_dr_amount,
				_cr_amount,
				_narration_code,
				_tran_ref_no,
				_tran_remark,
				_status_code,
				_user_code,
				now()
				
			) returning incomeexpense_gid into _incomeexpense_gid;			
			v_succ_code := 'SB05IEXCUD_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;	
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tincomeexpense
				   where	incomeexpense_gid 	= _incomeexpense_gid 
				   and 		status_code = 'A'
				   ) then
			update	pg_trn_tincomeexpense 
			set	    acchead_type_code	= _acchead_type_code,
					acchead_code 		= _acchead_code,
					tran_date 			= _tran_date,
					dr_amount 			= _dr_amount,
					cr_amount 			= _cr_amount,
					narration_code 		= _narration_code,
					tran_ref_no 		= _tran_ref_no,
					tran_remark 		= _tran_remark,
					status_code 		= _status_code,
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	incomeexpense_gid	= _incomeexpense_gid
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB05IEXCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;			
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
			
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_loginhistory(INOUT _loginhistory_gid udd_int, _user_code udd_code, _ip_address udd_desc, _login_date udd_datetime, _login_mode udd_code, _login_status udd_code, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 29-04-2022
		SP Code      : B01LGHCXX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- user code validation
	if _user_code = '' then
		v_err_code := v_err_code || 'VB01LGHCXX_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01LGHCXX_001', _lang_code) || v_new_line;	
	end if;
	
	if _ip_address = '' then
		v_err_code := v_err_code || 'VB01LGHCXX_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01LGHCXX_002', _lang_code) || v_new_line;	
	end if;
	
	if _login_date is null then
		v_err_code := v_err_code || 'VB01LGHCXX_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01LGHCXX_003', _lang_code) || v_new_line;	
	end if;
	
	if _login_mode = '' then
		v_err_code := v_err_code || 'VB01LGHCXX_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01LGHCXX_004', _lang_code) || v_new_line;	
	end if;
	
	if _login_status = '' then
		v_err_code := v_err_code || 'VB01LGHCXX_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01LGHCXX_005', _lang_code) || v_new_line;	
	end if;
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where 	lang_code   = _lang_code
				   and   	status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	-- Login history table insert
	insert into pg_trn_tloginhistory(
								user_code,
								ip_address,
								login_date,
								login_mode,
								login_status)
						values(
								_user_code,
								_ip_address,
								_login_date,
								_login_mode,
								_login_status
								) returning loginhistory_gid into _loginhistory_gid;
								v_succ_code := 'SB00CMNCMN_001';
			  
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_bankbranchmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B04BBMCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	

begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											bank_branch_id	 bigint,
											bank_id 		 integer,
											bank_code 		 varchar(10),
											bank_branch_code integer,
											bank_branch_name varchar(200),
											ifsc_code 		 varchar(20),
											bank_branch_address varchar(255),
											rural_urban_branch  varchar(1),
											village_id		 integer,
											block_id		 integer,
											district_id		 integer,
											state_id		 integer,
											pincode			 varchar(6),
											branch_merged_with	integer,
											is_active 		 boolean,
											created_date 	 text,
											created_by 		 integer,
											updated_date 	 text,
											updated_by 		 integer,
											entity_code		 varchar(30)									
										)
		  loop
		  	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
		  	  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  		  		
		      insert into bank_branch_master(
			  								bank_branch_id,
											bank_id,
											bank_code,
											bank_branch_code,
											bank_branch_name,
											ifsc_code,
											bank_branch_address,
											rural_urban_branch,
											village_id,
											block_id,
											district_id,
											state_id,
											pincode,
											branch_merged_with,
											is_active,
											created_date,
											created_by,
											entity_code 
			  							)
								values  (											
			  								v_colrec.bank_branch_id,
											v_colrec.bank_id,
											v_colrec.bank_code,
											v_colrec.bank_branch_code,
											v_colrec.bank_branch_name,
											v_colrec.ifsc_code,
											v_colrec.bank_branch_address,
											v_colrec.rural_urban_branch,
											v_colrec.village_id,
											v_colrec.block_id,
											v_colrec.district_id,
											v_colrec.state_id,
											v_colrec.pincode,
											v_colrec.branch_merged_with,
											'true',
											now(),
											99,
											v_colrec.entity_code
								       )
										
				on conflict (
								bank_branch_id
							)
							do update set   bank_branch_id			= v_colrec.bank_branch_id,
											bank_id					= v_colrec.bank_id,
											bank_code				= v_colrec.bank_code,
											bank_branch_code		= v_colrec.bank_branch_code,
											bank_branch_name		= v_colrec.bank_branch_name,
											ifsc_code				= v_colrec.ifsc_code,
											bank_branch_address		= v_colrec.bank_branch_address,
											rural_urban_branch		= v_colrec.rural_urban_branch,
											village_id				= v_colrec.village_id,
											block_id				= v_colrec.block_id,
											district_id				= v_colrec.district_id,
											state_id				= v_colrec.state_id,
											pincode					= v_colrec.pincode,
											branch_merged_with		= v_colrec.branch_merged_with,
											updated_date			= now(),
											updated_by				= 99,
											entity_code 			= v_colrec.entity_code;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_bankmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B04BAMCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											bank_id 		 integer,
											language_id 	 varchar(2),
											bank_code 		 varchar(10),
											bank_name 		 varchar(100),
											bank_shortname 	 varchar(20),
											bank_type 		 smallint,
											ifsc_mask 		 varchar(11),
											bank_merged_with varchar(20),
											bank_level 	     smallint,
											is_active 		 smallint,
											created_date 	 text,
											created_by 		 integer,
											updated_date 	 text,
											updated_by 		 integer,
											bank_account_len varchar(20)									
										)
		  loop
		  	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
		  	  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  		  
		      insert into bank_master  (
			  								bank_id,
											language_id,
											bank_code,
											bank_name,
											bank_shortname,
											bank_type,
											ifsc_mask,
											bank_merged_with,
											bank_level,
											is_active,
											created_date,
											created_by,
											bank_account_len 
			  							)
								values  (											
			  								v_colrec.bank_id,
											v_colrec.language_id,
											v_colrec.bank_code,
											v_colrec.bank_name,
											v_colrec.bank_shortname,
											v_colrec.bank_type,
											v_colrec.ifsc_mask,
											v_colrec.bank_merged_with,
											v_colrec.bank_level,
											v_colrec.is_active,
											now(),
											99,
											v_colrec.bank_account_len
								       )
										
				on conflict (
								bank_id
							)
							do update set   bank_id				=	v_colrec.bank_id,
											language_id			=	v_colrec.language_id,
											bank_code			=	v_colrec.bank_code,
											bank_name			=	v_colrec.bank_name,
											bank_shortname		=	v_colrec.bank_shortname,
											bank_type			=	v_colrec.bank_type,
											ifsc_mask			=	v_colrec.ifsc_mask,
											bank_merged_with	=	v_colrec.bank_merged_with,
											bank_level			=	v_colrec.bank_level,
											is_active			=	v_colrec.is_active,
											updated_date		=	now(),
											updated_by			=	99,
											bank_account_len	=	v_colrec.bank_account_len;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_blockmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Mangai
		Created Date : 24-03-2022
		SP Code : B01BKMCUX
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														block_id integer,
														state_id integer,
														district_id integer,
														block_code varchar(7),
														block_name_en varchar(100),
														block_name_local varchar(200),
														block_short_name_en varchar(20),
														block_short_name_local varchar(40),
														rural_urban_area varchar(1),
														language_id varchar(2),
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
				
				insert into block_master (
											block_id,
											state_id,
											district_id,
											block_code,
											block_name_en,
											block_name_local,
											block_short_name_en,
											block_short_name_local,
											rural_urban_area,
											language_id,
											is_active,
											created_date,
											created_by)
					values              (
											v_colrec.block_id,
											v_colrec.state_id,
											v_colrec.district_id,
											v_colrec.block_code,
											v_colrec.block_name_en,
											v_colrec.block_name_local,
											v_colrec.block_short_name_en,
											v_colrec.block_short_name_local,
											v_colrec.rural_urban_area,
											v_colrec.language_id,
											'true',
											now(),
											99)
							
		on CONFLICT ( block_id )  do update set  
											block_id = v_colrec.block_id,
											state_id = v_colrec.state_id,
											district_id = v_colrec.district_id,
											block_code = v_colrec.block_code,
											block_name_en = v_colrec.block_name_en,
											block_name_local = v_colrec.block_name_local,
											block_short_name_en = v_colrec.block_short_name_en,
											rural_urban_area = v_colrec.rural_urban_area,
											language_id = v_colrec.language_id,
											is_active = 'true',
											updated_date = now(),
											updated_by = 99;
		END LOOP;
		open result_succ_msg for select 	
   			'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_memberaddressjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 29-06-2022
		SP Code      : B04MADCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_address_id	integer,
											cbo_id				bigint,
											member_code			bigint,
											address_type		smallint,
											address_line1		varchar(255),
											address_line2		varchar(255),
											village_id			integer,
											state_id			integer,
											district_id			integer,
											postal_code			integer,
											status              smallint,
											is_active			boolean,
											block_id			integer,
											panchayat_id       	integer,
											created_date   		text,
											updated_date		text
										)
			loop
			  	v_updated_date := now();
				v_created_date := now();
			  			
		      insert into member_address(
			  								member_address_id,
											cbo_id,
											member_code,
											address_type,
											address_line1,
											address_line2,
											village,
											state,
											district,
											postal_code,
											status,
											is_active,
											block_id,
											panchayat_id,
											state_id,
											created_date
			  							)
								values  (											
			  								v_colrec.member_address_id,
											v_colrec.cbo_id,
											v_colrec.member_code,
											v_colrec.address_type,
											v_colrec.address_line1,
											v_colrec.address_line2,
											v_colrec.village_id,
											v_colrec.state_id,
											v_colrec.district_id,
											v_colrec.postal_code,
											v_colrec.status,
											v_colrec.is_active,
											v_colrec.block_id,
											v_colrec.panchayat_id,
											v_colrec.state_id,
											v_created_date
								       )
										
				on conflict (
								member_address_id,
								state_id
							)
							do update set   member_address_id	=	v_colrec.member_address_id,
											cbo_id				=	v_colrec.cbo_id,
											member_code			=	v_colrec.member_code,
											address_type		=	v_colrec.address_type,
											address_line1		=	v_colrec.address_line1,
											address_line2		=	v_colrec.address_line2,
											village				=	v_colrec.village_id,
											state				=	v_colrec.state_id,
											district			=	v_colrec.district_id,
											postal_code			=	v_colrec.postal_code,
											status				=	v_colrec.status,
											is_active			=	v_colrec.is_active,
											block_id			=	v_colrec.block_id,
											panchayat_id		=	v_colrec.panchayat_id,
-- 											state_id			=	v_colrec.state_id,
											updated_date		=	v_updated_date;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_memberbankdetailsjson(_jsonquery udd_text, _state_id udd_int, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 29-06-2022
		SP Code      : B04MBDCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_bank_details_id	integer,
											cbo_id				bigint,
											member_code			bigint,
											account_no			varchar(20),
											bank_id				bigint,
											account_type		smallint,
											mem_branch_code		varchar(12),
											ifsc_code			varchar(20),
											is_default_account	integer,
											closing_date		date,
											status				smallint,
											is_active			boolean,
											state_id			integer,
											created_date   		text,
											updated_date		text
										)
			loop
			 	 v_updated_date := now();
				 v_created_date := now();
			  			
		      insert into member_bank_details(
			  								member_bank_details_id,
											cbo_id,
											member_code,
											account_no,
											bank_id,
											account_type,
											mem_branch_code,
											ifsc_code,
											is_default_account,
											closing_date,
											status,
											is_active,
											state_id,
											created_date
			  							)
								values  (											
			  								v_colrec.member_bank_details_id,
											v_colrec.cbo_id,
											v_colrec.member_code,
											v_colrec.account_no,
											v_colrec.bank_id,
											v_colrec.account_type,
											v_colrec.mem_branch_code,
											v_colrec.ifsc_code,
											v_colrec.is_default_account,
											v_colrec.closing_date,
											v_colrec.status,
											v_colrec.is_active,
											_state_id,
											v_created_date
								       )
										
				on conflict (
								member_bank_details_id,
								state_id
							)
							do update set   member_bank_details_id	= v_colrec.member_bank_details_id,
											cbo_id					= v_colrec.cbo_id,
											member_code				= v_colrec.member_code,
											account_no				= v_colrec.account_no,
											bank_id					= v_colrec.bank_id,
											account_type			= v_colrec.account_type,
											mem_branch_code			= v_colrec.mem_branch_code,
											ifsc_code				= v_colrec.ifsc_code,
											is_default_account		= v_colrec.is_default_account,
											closing_date			= v_colrec.closing_date,
											status					= v_colrec.status,
											is_active				= v_colrec.is_active,
-- 											state_id				= v_colrec.state_id,
											updated_date			= v_updated_date;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_memberphonedetailsjson(_jsonquery udd_text, _state_id udd_int, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 29-06-2022
		SP Code      : B04MPDCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_phone_details_id	bigint,
											cbo_id				bigint,
											member_code			bigint,
											phone_no			bigint,
											is_default			smallint,
											status				smallint,
											is_active			boolean,
											state_id			integer,
											created_date   		text,
											updated_date		text
										)
			loop
				v_updated_date := now();
				v_created_date := now();
				
			  			
		      insert into member_phone_details(
			  								member_phone_details_id,
											cbo_id,
											member_code,
											phone_no,
											is_default,
											status,
											is_active,
											state_id,
											created_date
			  							)
								values  (											
			  								v_colrec.member_phone_details_id,
											v_colrec.cbo_id,
											v_colrec.member_code,
											v_colrec.phone_no,
											v_colrec.is_default,
											v_colrec.status,
											v_colrec.is_active,
											_state_id,
											v_created_date
								       )
										
				on conflict (
								member_phone_details_id,
								state_id
							)
							do update set   member_phone_details_id = v_colrec.member_phone_details_id,
											cbo_id					= v_colrec.cbo_id,
											member_code				= v_colrec.member_code,
											phone_no				= v_colrec.phone_no,
											is_default				= v_colrec.is_default,
											status					= v_colrec.status,
											is_active				= v_colrec.is_active,
-- 											state_id				= v_colrec.state_id,
											updated_date			= v_updated_date;
			END LOOP;
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_panchayatmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Mangai
		Created Date : 28-02-2022
		SP Code : B01PJMCUX  
		
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														panchayat_id integer,
														state_id integer,
														district_id integer,
														block_id integer,
														panchayat_code char(10),
														panchayat_name_en varchar(100),
														panchayat_name_local varchar(200),
														language_id varchar(2),
														rural_urban_area varchar(1),
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
								
				insert into panchayat_master (
														panchayat_id,
														state_id,
														district_id,
														block_id,
														panchayat_code,
														panchayat_name_en,
														panchayat_name_local,
														language_id,
														rural_urban_area,
														is_active,
														created_date,
														created_by
												)
							values              (
													v_colrec.panchayat_id,
													v_colrec.state_id,
													v_colrec.district_id,
													v_colrec.block_id,
													v_colrec.panchayat_code,
													v_colrec.panchayat_name_en,
													v_colrec.panchayat_name_local,
													v_colrec.language_id,
													v_colrec.rural_urban_area,
													'true',
													now(),
													99
							)
							
		on CONFLICT (panchayat_id )  do update set  
													panchayat_id = v_colrec.panchayat_id,
													state_id = v_colrec.state_id,
													district_id = v_colrec.district_id,
													block_id = v_colrec.block_id,
													panchayat_code = v_colrec.panchayat_code,
													panchayat_name_en = v_colrec.panchayat_name_en,
													panchayat_name_local = v_colrec.panchayat_name_local,
													language_id = v_colrec.language_id,
													rural_urban_area = v_colrec.rural_urban_area,
													is_active = 'true',
													updated_date = now(),
													updated_by = 99;
		END LOOP;
		
		open result_succ_msg for select 	
   			'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokos_villagemasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Mangai
		Created Date : 23-06-2022
		SP Code : B01VLMCUX  
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														village_id integer,
														state_id integer,
														district_id integer,
														block_id integer,
														panchayat_id bigint,
														village_code char(16),
														village_name_en varchar(100),
														village_name_local varchar(200),
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
								
				insert into village_master (
														village_id,
														state_id,
														district_id,
														block_id,
														panchayat_id,
														village_code,
														village_name_en,
														village_name_local,
														is_active,
														created_date,
														created_by
												)
							values              (
													v_colrec.village_id,
													v_colrec.state_id,
													v_colrec.district_id,
													v_colrec.block_id,
													v_colrec.panchayat_id,
													v_colrec.village_code,
													v_colrec.village_name_en,
													v_colrec.village_name_local,
													'true',
													now(),
													99
							)
							
		on CONFLICT (village_id )  do update set  
													village_id = v_colrec.village_id,
													state_id = v_colrec.state_id,
													district_id = v_colrec.district_id,
													block_id = v_colrec.block_id,
													panchayat_id = v_colrec.panchayat_id,
													village_code = v_colrec.village_code,
													village_name_en = v_colrec.village_name_en,
													village_name_local = v_colrec.village_name_local,
													is_active = 'true',
													updated_date = now(),
													updated_by = 99;
		END LOOP;
		open result_succ_msg for select 	
   			'Data Synced Successfully';
		
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokosdistrictmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Mohan S
		Created Date : 17-06-2022
		SP Code : B01DTMCUX  
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;
begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														district_id integer,
														state_id integer,
														district_code char(4),
														district_name_en varchar(100),
														district_name_local varchar(200),
														district_short_name_en varchar(20),
														district_short_name_local varchar(40),
														fundrelease_flag boolean,
														language_id varchar(2),
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer,
														district_name_hi varchar(255)
													)
				LOOP 
				v_updated_date := now();
				v_created_date := now();
				
				insert into district_master (
														district_id,
														state_id,
														district_code,
														district_name_en,
														district_name_local,
														district_short_name_en,
														district_short_name_local,
														fundrelease_flag,
														language_id,
														is_active,
														created_date,
														created_by,
														district_name_hi
												)
							values              (
													v_colrec.district_id,
													v_colrec.state_id,
													v_colrec.district_code,
													v_colrec.district_name_en,
													v_colrec.district_name_local,
													v_colrec.district_short_name_en,
													v_colrec.district_short_name_local,
													v_colrec.fundrelease_flag,
													v_colrec.language_id,
													true,
													v_created_date,
													99,
													v_colrec.district_name_hi
							)
							
		on CONFLICT (district_id )  do update set  
													district_id = v_colrec.district_id,
													state_id = v_colrec.state_id,
													district_code = v_colrec.district_code,
													district_name_en = v_colrec.district_name_en,
													district_name_local = v_colrec.district_name_local,
													district_short_name_en = v_colrec.district_short_name_en,
													district_short_name_local = v_colrec.district_short_name_local,
													fundrelease_flag = v_colrec.fundrelease_flag,
													language_id = v_colrec.language_id,
													updated_date = v_updated_date,
													updated_by = 99,
													district_name_hi = v_colrec.district_name_hi;
		END LOOP;
		
				open result_succ_msg for select 	
   				'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokosmemberprofilejson(_jsonquery udd_text, _state_id udd_int, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mohan s
		Created Date : 21-06-2022
		SP Code      : Lokos Member Profile
	*/
	v_colrec record;
	v_updated_date timestamp := now();
	v_created_date timestamp := now();
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_id			integer,
											member_code			bigint,
											cbo_id				bigint,
											group_m_code		integer,
											seq_no				integer,
											member_name			varchar(50),
											member_name_local	varchar(100),
											father_husband		varchar(1),
											relation_name		varchar(50),
											relation_name_local	varchar(100),
											gender				smallint,
											social_category		smallint,
											dob					text,
											is_active			boolean,
											mem_activation_status	smallint,
											age					integer,
											age_as_on			text,
											dob_available		integer,
											state_id			integer,
											created_date   		text,
											updated_date		text
										)
			loop
			  			
		      insert into member_profile(
			  								member_id,
											member_code,
											cbo_id,
											group_m_code,
											seq_no,
											member_name,
											member_name_local,
											father_husband,
											relation_name,
											relation_name_local,
											gender,
											social_category,
											dob,
											is_active,
											mem_activation_status,
											age,
											age_as_on,
											dob_available,
											state_id,
											created_date
-- 											updated_date
			  							)
								values  (											
			  								v_colrec.member_id,
											v_colrec.member_code,
											v_colrec.cbo_id,
											v_colrec.group_m_code,
											v_colrec.seq_no,
											v_colrec.member_name,
											v_colrec.member_name_local,
											v_colrec.father_husband,
											v_colrec.relation_name,
											v_colrec.relation_name_local,
											v_colrec.gender,
											v_colrec.social_category,
											now(),--v_colrec.dob,
											v_colrec.is_active,
											v_colrec.mem_activation_status,
											v_colrec.age,
											now(),--v_colrec.age_as_on,
											v_colrec.dob_available,
											_state_id,
											v_created_date
-- 											v_updated_date
								       )
										
				on conflict (
								member_id,
								state_id
							)
							do update set   member_id				= v_colrec.member_id,
											member_code				= v_colrec.member_code,
											cbo_id					= v_colrec.cbo_id,
											group_m_code			= v_colrec.group_m_code,
											seq_no					= v_colrec.seq_no,
											member_name				= v_colrec.member_name,
											member_name_local		= v_colrec.member_name_local,
											father_husband			= v_colrec.father_husband,
											relation_name			= v_colrec.relation_name,
											relation_name_local		= v_colrec.relation_name_local,
											gender					= v_colrec.gender,
											social_category			= v_colrec.social_category,
											dob						= now(),--v_colrec.dob,
											is_active				= v_colrec.is_active,
											mem_activation_status	= v_colrec.mem_activation_status,
											age						= v_colrec.age,
											age_as_on				= now(),--v_colrec.age_as_on,
											dob_available			= v_colrec.dob_available,
-- 											state_id				= _state_id,
											updated_date			= v_updated_date;
			END LOOP;
			
			open result_succ_msg for select 	
   								'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokosshgprofilejson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mohan S
		Created Date : 21-06-2022
		SP Code      : shg Profile
	*/
	v_colrec record;
	v_updated_date timestamp := now();
	v_created_date timestamp := now(); 
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											shg_id 				integer,
											state_id 			integer,
											district_id 		integer,
											block_id 			integer,
											panchayat_id 		integer,
											village_id 			integer,
											shg_code 		    varchar(22),
											shg_name 			varchar(80),
											shg_type_code 		smallint,
											language_id 		varchar(2),
											shg_name_local 		varchar(120),
											parent_cbo_code 	bigint,
											parent_cbo_type 	smallint,
											is_active 			boolean,
											activation_status 	smallint,
											uploaded_by 		varchar(100),
											status 				smallint,
											promoter_code 		varchar(5),
											cbo_type			smallint,
											created_date		text,
											updated_date		text
										)
		  loop
			  		  
		      insert into shg_profile  (
			  								shg_id,
											state_id,
											district_id,
											block_id,
											panchayat_id,
											village_id,
											shg_code,
											shg_name,
											shg_type_code,
											language_id,
											shg_name_local,
											parent_cbo_code,
											parent_cbo_type,
											is_active,
											activation_status,
											uploaded_by,
											status,
											promoter_code,
											cbo_type,
				  							created_date,
				  							updated_date
				  
			  							)
								values  (											
			  								v_colrec.shg_id,
											v_colrec.state_id,
											v_colrec.district_id,
											v_colrec.block_id,
											v_colrec.panchayat_id,
											v_colrec.village_id,
											v_colrec.shg_code,
											v_colrec.shg_name,
											v_colrec.shg_type_code,
											v_colrec.language_id,
											v_colrec.shg_name_local,
											v_colrec.parent_cbo_code,
											v_colrec.parent_cbo_type,
											v_colrec.is_active,
											v_colrec.activation_status,
											v_colrec.uploaded_by,
											v_colrec.status,
											v_colrec.promoter_code,
											0,
											v_created_date,
											v_updated_date
										)
										
				on conflict (
								shg_id
							)
							do update set   shg_id 			= v_colrec.shg_id,
											state_id		= v_colrec.state_id,
											district_id		= v_colrec.district_id,
											block_id		= v_colrec.block_id,
											panchayat_id	= v_colrec.panchayat_id,
											village_id		= v_colrec.village_id,
											shg_code		= v_colrec.shg_code,
											shg_name		= v_colrec.shg_name,
											shg_type_code	= v_colrec.shg_type_code,
											language_id		= v_colrec.language_id,
											shg_name_local	= v_colrec.shg_name_local,
											parent_cbo_code	= v_colrec.parent_cbo_code,
											parent_cbo_type	= v_colrec.parent_cbo_type,
											is_active		= v_colrec.is_active,
											activation_status= v_colrec.activation_status,
											uploaded_by		= v_colrec.uploaded_by,
											status			= v_colrec.status,
											promoter_code	= v_colrec.promoter_code,
											cbo_type		= 0,
											updated_date	= v_updated_date;

						END LOOP;
						
						open result_succ_msg for select 	
   								'Data Synced Successfully';
END		
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokosstatemasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Mohan s
		Created Date : 17-06-2022
		SP Code : B01STMCUX
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														state_id integer,
														state_code char(2),
														state_name_en varchar(50),
														state_name_hi varchar(100),
														state_name_local varchar(100),
														state_short_local_name varchar(10),
														state_short_name_en varchar(10),
														category smallint,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				v_updated_date := now();
				v_created_date := now();
				
				insert into state_master (
														state_id,
														state_code,
														state_name_en,
														state_name_hi,
														state_name_local,
														state_short_local_name,
														state_short_name_en,
														category,
														is_active,
														created_date,
														created_by,
														updated_date,
														updated_by
												)
							values              (
													v_colrec.state_id,
													v_colrec.state_code,
													v_colrec.state_name_en,
													v_colrec.state_name_hi,
													v_colrec.state_name_local,
													v_colrec.state_short_local_name,
													v_colrec.state_short_name_en,
													v_colrec.category,
													true,
													v_created_date,
													99,
													v_updated_date,
													v_colrec.updated_by
							)
							
		on CONFLICT ( state_id )  do update set  
													state_id = v_colrec.state_id,
													state_code = v_colrec.state_code,
													state_name_en = v_colrec.state_name_en,
													state_name_hi = v_colrec.state_name_hi,
													state_name_local = v_colrec.state_name_local,
													state_short_local_name = v_colrec.state_short_local_name,
													state_short_name_en = v_colrec.state_short_name_en,
													category = v_colrec.category,
													updated_date = v_updated_date,
													updated_by = 99;
		END LOOP;
		open result_succ_msg for select 	
   			'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_lokossync(_state_id udd_int, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mohan
		Created Date : 31-03-2022
		SP Code      : B01LSYUXX
	*/
	 v_prev_last_sync_date udd_datetime := null;
begin 
	
	-- get last sync date 
	select 		last_sync_date into v_prev_last_sync_date
	from 		core_mst_tlokossync
	where		state_id = _state_id
	and 		status_code = 'A';
	
	-- Update on last sync and prev sync date
	if exists (	select '*' from core_mst_tlokossync
			  	where 	state_id = _state_id
			 	and 	status_code = 'A') then
		update 	core_mst_tlokossync
		set	  	last_sync_date = now(),
				prev_last_sync_date = v_prev_last_sync_date,
				updated_date = now(),
				updated_by = 'System'
		where	state_id 	= _state_id
		and 	status_code = 'A';
		
			_succ_msg := 'Updated Successfully';
		else
			_succ_msg := 'Updated Failed';
	end if;
	
	
End;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_master(INOUT _master_gid udd_int, _parent_code udd_code, _master_code udd_code, _depend_parent_code udd_code, _depend_code udd_code, _rec_slno udd_int, _sys_flag udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, _row_timestamp udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line udd_text = chr(13)||chr(10);
	v_timestamp udd_text := '';
begin
	-- validation
	-- master code cannot be blank
	if _master_code = '' then
		v_err_code := v_err_code || 'VB01QCMCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCMCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- parent code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where	parent_code = 'SYS'
				   and 		master_code = _parent_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01QCMCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCMCUD_002', _lang_code) || v_new_line;
	end if;
	
	if _depend_code <> '' then
		select 	depend_parent_code into _depend_parent_code 
		from 	core_mst_tmaster 
		where 	parent_code = 'SYS'
		and 	master_code = _parent_code
		and 	status_code = 'A';
		
		_depend_parent_code = coalesce(_depend_parent_code,'');
	end if;
	
	-- depend parent code validation
	if _depend_parent_code <> '' then
		if not exists (select 	* 
					   from		core_mst_tmaster 
					   where 	parent_code = 'SYS'
					   and 		master_code = _depend_parent_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB01QCMCUD_003' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCMCUD_003', _lang_code) || v_new_line;
		end if;
	end if;

	-- depend code validation
	if _depend_code <> '' then
		if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = _depend_parent_code 
					   and 		master_code = _depend_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB01QCMCUD_004' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCMCUD_004', _lang_code) || v_new_line;
		end if;
	end if;

	-- sys flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _sys_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01QCMCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCMCUD_005', _lang_code) || v_new_line;	
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code);	
	end if;
	
	if _mode_flag = 'I' then
		_lang_code = 'en_US';
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	-- timestamp check for concurrency
	select 	to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') into v_timestamp 
	from 	core_mst_tmaster
	where	master_gid = _master_gid;
	
	v_timestamp	:= coalesce(v_timestamp, '');
	
	IF (v_timestamp != _row_timestamp) 
	then
		-- Record modified since last fetch so Kindly refetch and continue
		v_err_code := v_err_code || 'VB00CMNCMN_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_002', _lang_code) || v_new_line;	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tmaster
				  where 	master_gid = _master_gid 
				  and 		parent_code = _parent_code
				  and 		master_code = _master_code 
				  and 		status_code = 'A'
				 ) then
			Update 	core_mst_tmaster
			set		status_code = 'I',
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	master_gid = _master_gid 
			and 	parent_code = _parent_code
			and 	master_code = _master_code 
			and 	status_code = 'A';
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tmaster
					  where		master_gid = _master_gid 
					  and 		parent_code = _parent_code
					  and 		master_code = _master_code 
					  and 		status_code = 'A'
					 ) then
			insert into core_mst_tmaster 
			(
				parent_code,
				master_code,
				depend_parent_code,
				depend_code,
				rec_slno,
				sys_flag,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				_parent_code,
				_master_code,
				_depend_parent_code,
				_depend_code,
				_rec_slno,
				_sys_flag,
				_status_code,
				_user_code,
				now(),
				now()
			) returning master_gid into _master_gid;
			
			v_succ_code := 'SB00CMNCMN_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tmaster
				   where	master_gid = _master_gid 
				   and 		parent_code = _parent_code
				   and 		master_code = _master_code 
				   and 		status_code = 'A'
				   ) then
			update	core_mst_tmaster 
			set 	depend_parent_code = _depend_parent_code,
					depend_code = _depend_code,
					status_code = _status_code,
					rec_slno = _rec_slno,
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	master_gid = _master_gid 
			and 	parent_code = _parent_code
			and 	master_code = _master_code 
			and 	status_code = 'A';
			
			v_succ_code := 'SB00CMNCMN_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_tmaster
			    where 	parent_code = _parent_code 
				group	by master_code
				having	count('*') > 1) 
	then
		-- master code cannot be duplicated
		v_err_code := v_err_code || 'EB01QCMCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB01QCMCUD_001', _lang_code),_master_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mastertranslate(INOUT _mastertranslate_gid udd_int, _parent_code udd_code, _master_code udd_code, _master_lang_code udd_code, _master_desc udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- master desc cannot be blank
	if _master_desc = '' then
		v_err_code := v_err_code || 'VB01QCTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCTCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- parent code validation
	if not exists (select * 
				   from 	core_mst_tmaster 
				   where	parent_code = 'SYS'
				   and 		master_code = _parent_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01QCTCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCTCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- master code validation
	if not exists (select * 
				   from 	core_mst_tmaster 
				   where	parent_code = _parent_code 
				   and 		master_code = _master_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01QCTCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCTCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- master language code validation
	if not exists (select * 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _master_lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01QCTCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01QCTCUD_004', _lang_code)|| v_new_line;	
	end if;
	
	-- language code validation
	if not exists (select * 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select mastertranslate_gid 
				  from 	core_mst_tmastertranslate
				  where mastertranslate_gid = _mastertranslate_gid 
				  and 	parent_code = _parent_code
				  and 	master_code = _master_code 
				  and 	lang_code = _master_lang_code 
				 ) then
			delete from	core_mst_tmastertranslate
			where 		mastertranslate_gid = _mastertranslate_gid 
			and 		parent_code = _parent_code
			and 		master_code = _master_code
			and 		lang_code = _master_lang_code;
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then 
		if not exists(select * 
					  from	core_mst_tmastertranslate
					  where	mastertranslate_gid = _mastertranslate_gid 
					  and 	parent_code = _parent_code
					  and 	master_code = _master_code 
					  and 	lang_code = _master_lang_code 
					 ) then
			insert into core_mst_tmastertranslate 
			(
				parent_code,
				master_code,
				lang_code,
				master_desc,
				created_date,
				created_by
			)
			values
			(
				_parent_code,
				_master_code,
				_master_lang_code,
				_master_desc,
				now(),
				_user_code
			) returning mastertranslate_gid into _mastertranslate_gid;
			
			v_succ_code := 'SB00CMNCMN_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select * 
				   from 	core_mst_tmastertranslate
				   where	mastertranslate_gid = _mastertranslate_gid 
				   and 		parent_code = _parent_code
				   and 		master_code = _master_code 
				   ) then
			update	core_mst_tmastertranslate 
			set 	lang_code = _master_lang_code,
					master_desc = _master_desc,
					updated_date = now(),
					updated_by  = _user_code
			where 	mastertranslate_gid = _mastertranslate_gid 
			and 	parent_code = _parent_code
			and 	master_code = _master_code ;
			
			v_succ_code := 'SB00CMNCMN_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_tmastertranslate 
			    where 	parent_code = _parent_code
			   	and 	master_code = _master_code 
				group	by lang_code
				having	count(*) > 1) 
	then
		-- master desc cannot be duplicated
		v_err_code := v_err_code || 'EB01QCTCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB01QCTCUD_001', _lang_code),_lang_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_memberaddressjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 28-02-2022
		SP Code      : B04MADCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_address_id	integer,
											cbo_id				bigint,
											member_code			bigint,
											address_type		smallint,
											address_line1		varchar(255),
											address_line2		varchar(255),
											village				integer,
											state				integer,
											district			integer,
											postal_code			integer,
											status              smallint,
											is_active			boolean,
											block_id			integer,
											panchayat_id       	integer,
											state_id      		integer,
											created_date   		text,
											updated_date		text
										)
			loop
			  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
			  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  			
		      insert into member_address(
			  								member_address_id,
											cbo_id,
											member_code,
											address_type,
											address_line1,
											address_line2,
											village,
											state,
											district,
											postal_code,
											status,
											is_active,
											block_id,
											panchayat_id,
											state_id,
											created_date,
											updated_date
			  							)
								values  (											
			  								v_colrec.member_address_id,
											v_colrec.cbo_id,
											v_colrec.member_code,
											v_colrec.address_type,
											v_colrec.address_line1,
											v_colrec.address_line2,
											v_colrec.village,
											v_colrec.state,
											v_colrec.district,
											v_colrec.postal_code,
											v_colrec.status,
											v_colrec.is_active,
											v_colrec.block_id,
											v_colrec.panchayat_id,
											v_colrec.state_id,
											v_created_date,
											v_updated_date
								       )
										
				on conflict (
								member_address_id,
								state_id
							)
							do update set   member_address_id	=	v_colrec.member_address_id,
											cbo_id				=	v_colrec.cbo_id,
											member_code			=	v_colrec.member_code,
											address_type		=	v_colrec.address_type,
											address_line1		=	v_colrec.address_line1,
											address_line2		=	v_colrec.address_line2,
											village				=	v_colrec.village,
											state				=	v_colrec.state,
											district			=	v_colrec.district,
											postal_code			=	v_colrec.postal_code,
											status				=	v_colrec.status,
											is_active			=	v_colrec.is_active,
											block_id			=	v_colrec.block_id,
											panchayat_id		=	v_colrec.panchayat_id,
											state_id			=	v_colrec.state_id,
											updated_date		=	v_updated_date;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_memberbankdetailsjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 28-02-2022
		SP Code      : B04MBDCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_bank_details_id	integer,
											cbo_id				bigint,
											member_code			bigint,
											account_no			varchar(20),
											bank_id				bigint,
											account_type		smallint,
											mem_branch_code		varchar(12),
											ifsc_code			varchar(20),
											is_default_account	integer,
											closing_date		date,
											status				smallint,
											is_active			boolean,
											state_id			integer,
											created_date   		text,
											updated_date		text
										)
			loop
			  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
			  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  			
		      insert into member_bank_details(
			  								member_bank_details_id,
											cbo_id,
											member_code,
											account_no,
											bank_id,
											account_type,
											mem_branch_code,
											ifsc_code,
											is_default_account,
											closing_date,
											status,
											is_active,
											state_id,
											created_date,
											updated_date
			  							)
								values  (											
			  								v_colrec.member_bank_details_id,
											v_colrec.cbo_id,
											v_colrec.member_code,
											v_colrec.account_no,
											v_colrec.bank_id,
											v_colrec.account_type,
											v_colrec.mem_branch_code,
											v_colrec.ifsc_code,
											v_colrec.is_default_account,
											v_colrec.closing_date,
											v_colrec.status,
											v_colrec.is_active,
											v_colrec.state_id,
											v_created_date,
											v_updated_date
								       )
										
				on conflict (
								member_bank_details_id,
								state_id
							)
							do update set   member_bank_details_id	= v_colrec.member_bank_details_id,
											cbo_id					= v_colrec.cbo_id,
											member_code				= v_colrec.member_code,
											account_no				= v_colrec.account_no,
											bank_id					= v_colrec.bank_id,
											account_type			= v_colrec.account_type,
											mem_branch_code			= v_colrec.mem_branch_code,
											ifsc_code				= v_colrec.ifsc_code,
											is_default_account		= v_colrec.is_default_account,
											closing_date			= v_colrec.closing_date,
											status					= v_colrec.status,
											is_active				= v_colrec.is_active,
											state_id				= v_colrec.state_id,
											updated_date			= v_updated_date;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_memberphonedetailsjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 28-02-2022
		SP Code      : B04MPDCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_phone_details_id	bigint,
											cbo_id				bigint,
											member_code			bigint,
											phone_no			bigint,
											is_default			smallint,
											status				smallint,
											is_active			boolean,
											state_id			integer,
											created_date   		text,
											updated_date		text
										)
			loop
			  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;	
			  select fn_text_todatetime(v_colrec.created_date) into v_created_date;	
			  			
		      insert into member_phone_details(
			  								member_phone_details_id,
											cbo_id,
											member_code,
											phone_no,
											is_default,
											status,
											is_active,
											state_id,
											created_date,
											updated_date
			  							)
								values  (											
			  								v_colrec.member_phone_details_id,
											v_colrec.cbo_id,
											v_colrec.member_code,
											v_colrec.phone_no,
											v_colrec.is_default,
											v_colrec.status,
											v_colrec.is_active,
											v_colrec.state_id,
											v_created_date,
											v_updated_date
								       )
										
				on conflict (
								member_phone_details_id,
								state_id
							)
							do update set   member_phone_details_id = v_colrec.member_phone_details_id,
											cbo_id					= v_colrec.cbo_id,
											member_code				= v_colrec.member_code,
											phone_no				= v_colrec.phone_no,
											is_default				= v_colrec.is_default,
											status					= v_colrec.status,
											is_active				= v_colrec.is_active,
											state_id				= v_colrec.state_id,
											updated_date			= v_updated_date;
			END LOOP;
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_memberprofilejson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 28-02-2022
		SP Code      : B04MPRCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											member_id			integer,
											member_code			bigint,
											cbo_id				bigint,
											group_m_code		integer,
											seq_no				integer,
											member_name			varchar(50),
											member_name_local	varchar(100),
											father_husband		varchar(1),
											relation_name		varchar(50),
											relation_name_local	varchar(100),
											gender				smallint,
											social_category		smallint,
											dob					date,
											is_active			boolean,
											mem_activation_status	smallint,
											age					integer,
											age_as_on			date,
											dob_available		integer,
											state_id			integer,
											created_date   		text,
											updated_date		text
										)
			loop
			  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
			  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  			
		      insert into member_profile(
			  								member_id,
											member_code,
											cbo_id,
											group_m_code,
											seq_no,
											member_name,
											member_name_local,
											father_husband,
											relation_name,
											relation_name_local,
											gender,
											social_category,
											dob,
											is_active,
											mem_activation_status,
											age,
											age_as_on,
											dob_available,
											state_id,
											created_date,
											updated_date
			  							)
								values  (											
			  								v_colrec.member_id,
											v_colrec.member_code,
											v_colrec.cbo_id,
											v_colrec.group_m_code,
											v_colrec.seq_no,
											v_colrec.member_name,
											v_colrec.member_name_local,
											v_colrec.father_husband,
											v_colrec.relation_name,
											v_colrec.relation_name_local,
											v_colrec.gender,
											v_colrec.social_category,
											v_colrec.dob,
											v_colrec.is_active,
											v_colrec.mem_activation_status,
											v_colrec.age,
											v_colrec.age_as_on,
											v_colrec.dob_available,
											v_colrec.state_id,
											v_created_date,
											v_updated_date
								       )
										
				on conflict (
								member_id,
								state_id
							)
							do update set   member_id				= v_colrec.member_id,
											member_code				= v_colrec.member_code,
											cbo_id					= v_colrec.cbo_id,
											group_m_code			= v_colrec.group_m_code,
											seq_no					= v_colrec.seq_no,
											member_name				= v_colrec.member_name,
											member_name_local		= v_colrec.member_name_local,
											father_husband			= v_colrec.father_husband,
											relation_name			= v_colrec.relation_name,
											relation_name_local		= v_colrec.relation_name_local,
											gender					= v_colrec.gender,
											social_category			= v_colrec.social_category,
											dob						= v_colrec.dob,
											is_active				= v_colrec.is_active,
											mem_activation_status	= v_colrec.mem_activation_status,
											age						= v_colrec.age,
											age_as_on				= v_colrec.age_as_on,
											dob_available			= v_colrec.dob_available,
											state_id				= v_colrec.state_id,
											updated_date			= v_updated_date;
			END LOOP;
			
			open result_succ_msg for select 	
   			'Data Synced Successfully';
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_menu(INOUT _menu_gid udd_int, _menu_code udd_code, _parent_code udd_code, _menu_slno udd_amount, _url_action_method udd_desc, _status_code udd_code, _menu_type_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 04-07-2022
		SP Code      : B01MENCUD
	*/

	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- Menu Code validation
	if _menu_code = '' then
		v_err_code := v_err_code || 'VB01MENCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01MENCUD_001', _lang_code) || v_new_line;
	end if;
	
-- Parent Code validation
	if _parent_code = '' then
		v_err_code := v_err_code || 'VB01MENCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01MENCUD_002', _lang_code) || v_new_line;
	end if;
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code   = 'QCD_STATUS' 
				   and   master_code   = _status_code 
				   and   status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from core_mst_tmenu
				  where menu_gid    = _menu_gid
				  and   status_code <> 'I')
			then
			update core_mst_tmenu 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where menu_gid 	    = _menu_gid
				and   status_code	<> 'I';
			v_succ_code := 'SB01MENCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif _mode_flag = 'I' then
		if not exists (select * from core_mst_tmenu
				   		where menu_code   = _menu_code
					  	and   parent_code = _parent_code)
		 then
			insert into core_mst_tmenu(
										menu_code ,
										parent_code ,
										menu_slno ,
										url_action_method ,
										status_code ,
										menu_type_code,
										created_date,
										created_by
									   )
								values(
										_menu_code ,
										_parent_code ,
										_menu_slno ,
										_url_action_method ,
										_status_code ,
										_menu_type_code,
										now(),
										_user_code
									   ) returning menu_gid into _menu_gid;
			
			v_succ_code := 'SB01MENCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tmenu
				   where	menu_gid    = _menu_gid
				   and 		status_code = 'A'
				   ) then
			update	core_mst_tmenu 
			set 	menu_slno 		  = _menu_slno,
					url_action_method = _url_action_method,
					status_code 	  = _status_code,
					menu_type_code	  = _menu_type_code,
					updated_date      = now(),
					updated_by	      = _user_code
			where 	menu_gid          = _menu_gid 
			and 	status_code       = 'A';
			
			v_succ_code := 'SB01MENCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_menutranslate(INOUT _menutranslate_gid udd_int, _menu_code udd_code, _menu_desc udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 04-07-2022
		SP Code      : B01METCUD
	*/

	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- Menu Code validation
	if not exists ( select 	* 
				    from 	core_mst_tmenu 
				    where 	menu_code   = _menu_code	
				    and     status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01METCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01METCUD_001', _lang_code)  || v_new_line;	
	end if;
	
--	Menu description validation
	if _menu_desc = '' then
		v_err_code := v_err_code || 'VB01METCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01METCUD_002', _lang_code)  || v_new_line;	
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from core_mst_tmenutranslate
				  where menutranslate_gid = _menutranslate_gid)
			then
				delete from core_mst_tmenutranslate 
				where menutranslate_gid = _menutranslate_gid;
			v_succ_code := 'SB01MEtCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif _mode_flag = 'I' then
		if not exists (select * from core_mst_tmenutranslate
				   		where menu_code   = _menu_code)
		 then
			insert into core_mst_tmenutranslate(
												menu_code ,
												lang_code,
												menu_desc,
												created_date,
												created_by
											   )
										values(
												_menu_code ,
												_lang_code,
												_menu_desc,
												now(),
												_user_code
											   ) returning menutranslate_gid into _menutranslate_gid;
			
			v_succ_code := 'SB01METCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tmenutranslate
				   where	menutranslate_gid = _menutranslate_gid
				   ) then
			update	core_mst_tmenutranslate 
			set 	menu_desc    = _menu_desc,
					updated_date = now(),
					updated_by	 = _user_code
			where 	menu_code    = _menu_code
			and     lang_code    = _lang_code;
			
			v_succ_code := 'SB01METCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_message(INOUT _msg_gid udd_int, _msg_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01MSGCDX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	
	-- message code validation
	if _msg_code = '' then
		v_err_code := v_err_code || 'VB01MSGCDX_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01MSGCDX_001', _lang_code) || v_new_line;
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tmessage
				  where 	msg_gid 	= _msg_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	core_mst_tmessage
			set		status_code 	= 'I',
					updated_by 		= _user_code,
					updated_date 	= now()					
			where 	msg_gid 		= _msg_gid 
			and 	status_code 	= 'A';
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tmessage
					  where		msg_code = _msg_code
					  and 		status_code = 'A'
					 ) then
			insert into core_mst_tmessage 
			(
				msg_code,
				status_code,
				created_by,
				created_date			
			)
			values
			(
				_msg_code,
				_status_code,
				_user_code,
				now()
				
			) returning msg_gid into _msg_gid;			
			v_succ_code := 'SB00CMNCMN_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;		
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
				
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_messagetranslate(INOUT _msgtranslate_gid udd_int, _msg_code udd_code, _langcode udd_code, _msg_desc udd_desc, _lang_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01MSTCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	
	-- message code validation
	if not exists (select 	* 
				   from 	core_mst_tmessage  
				   where 	msg_code = _msg_code				  
				  ) then
		v_err_code := v_err_code || 'VB01MSTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01MSTCUD_001', _lang_code)|| v_new_line;
	end if;
	
	-- message desc validation
	if _msg_desc = '' then
		v_err_code := v_err_code || 'VB01MSTCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01MSTCUD_002', _lang_code) || v_new_line;
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tmessagetranslate
				  where 	msgtranslate_gid 	= _msgtranslate_gid 				 
				 ) then
				 
			Delete from 	core_mst_tmessagetranslate
			where		    msgtranslate_gid = _msgtranslate_gid;
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tmessagetranslate
					  where		msg_code = _msg_code					 
					 ) then
			insert into core_mst_tmessagetranslate 
			(
				msg_code,
				lang_code,
				msg_desc			
			)
			values
			(
				_msg_code,
				_langcode,
				_msg_desc
				
			) returning msgtranslate_gid into _msgtranslate_gid;			
			v_succ_code := 'SB00CMNCMN_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;	
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tmessagetranslate
				   where	msgtranslate_gid 	= _msgtranslate_gid 
				   ) then
			update	core_mst_tmessagetranslate 
			set	    msg_desc				= _msg_desc		
			where 	msgtranslate_gid		= _msgtranslate_gid;
				
			v_succ_code := 'SB00CMNCMN_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;		
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_tmessagetranslate
			    where 	msg_code 	= _msg_code 
				group	by lang_code
				having	count('*') > 1) 
	then
		-- msg code  cannot be duplicated
		v_err_code := v_err_code || 'VB01MSTCUD_003';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('VB01MSTCUD_003', _lang_code),_msg_code);
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
			
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mobilesyncjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 28-02-2022
		SP Code      : B01MSYCUX
	*/
	v_colrec record;
	v_updated_date udd_datetime;
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											mobilesync_gid		udd_int,
											pg_id				udd_code,
											role_code			udd_code,
											user_code			udd_code,
											mobile_no			udd_mobile,
											sync_type_code		udd_code,
											last_sync_date		udd_datetime,
											prev_last_sync_date	udd_datetime,
											status_code			udd_code,
											created_date   		udd_datetime,
											created_by			udd_user,
											updated_date		udd_text,
											updated_by			udd_user
										)
			loop
			  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
			
		      insert into core_mst_tmobilesync(
			  								mobilesync_gid,
											pg_id,
											role_code,
											user_code,
											mobile_no,
											sync_type_code,
											last_sync_date,
											prev_last_sync_date,
											status_code,
											created_date,
											created_by,
											updated_date,
											updated_by
			  							)
								values  (											
			  								v_colrec.mobilesync_gid,
											v_colrec.pg_id,
											v_colrec.role_code,
											v_colrec.user_code,
											v_colrec.mobile_no,
											v_colrec.sync_type_code,
											v_colrec.last_sync_date,
											v_colrec.prev_last_sync_date,
											v_colrec.status_code,
											v_colrec.created_date,
											v_colrec.created_by,
											v_updated_date,
											v_colrec.updated_by
								       )
										
				on conflict (
								pg_id,
								role_code,
								user_code,
								mobile_no,
								sync_type_code
							)
							do update set   mobilesync_gid			= v_colrec.mobilesync_gid,
											pg_id					= v_colrec.pg_id,
											role_code				= v_colrec.role_code,
											user_code				= v_colrec.user_code,
											mobile_no				= v_colrec.mobile_no,
											sync_type_code			= v_colrec.sync_type_code,
											last_sync_date			= v_colrec.last_sync_date,
											prev_last_sync_date		= v_colrec.prev_last_sync_date,
											status_code				= v_colrec.status_code,
											updated_date			= v_updated_date,	
											updated_by				= v_colrec.updated_by;
			
			END LOOP;
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mtwaggreofprodjson(_aggofprocure udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 26-02-2022
		SP Code : B06AOPCUX
	*/
	v_procure udd_jsonb;
	v_procure_prod udd_jsonb;
	v_procure_prodqlty udd_jsonb;
	
begin
	-- stored procedure body 
	--PROCURE
	v_procure := (select t.value from (select * from json_each(_aggofprocure::udd_json)) as t
				where t.key = 'pg_trn_tprocure');
								  
	call public.pr_iud_procurejson(v_procure);
								  
	-- PROCURE PRODUCT
	v_procure_prod := (select t.value from (select * from json_each(_aggofprocure::udd_json)) as t
				where t.key = 'pg_trn_tprocureproduct');
									   
	call public.pr_iud_procureproductjson(v_procure_prod);
	
					
	-- PROCURE PRODUCT QUALITY
	v_procure_prodqlty := (select t.value from (select * from json_each(_aggofprocure::udd_json)) as t
				where t.key = 'pg_trn_tprocureproductqlty');							 
	
	call public.pr_iud_procureproductqltyjson(v_procure_prodqlty);
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mtwaggresync(_aggresync udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 25-02-2022

		Updated By 	: Vijayavel J
		Updated Date : 15-03-2022
		
		SP Code : B06SYNG01
	*/
	v_procure udd_jsonb;
	v_procure_prod udd_jsonb;
	v_procure_prodqlty udd_jsonb;
	v_sale udd_jsonb;
	v_sale_prod udd_jsonb;
	v_procure_cost udd_jsonb;
	v_session udd_jsonb;
	v_mobilesync udd_jsonb;
	v_pgbuyer udd_jsonb;
	v_pgdocnum udd_jsonb;
	
	v_pg_id udd_code;
	v_colrec record;
	v_colrec1 record;
	
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_MEM_PROCURE';
	v_pgmember_name udd_desc := '';
	v_pg_name udd_desc := '';
	v_procurement_date udd_date := null;
	v_product_name udd_text := '';
	v_grade_value udd_text := '';
	v_product_qty udd_text := '';
	v_uom udd_text := '';
	v_advance_amount udd_amount := 0;
	v_mobile_no udd_mobile := 0;
	
begin
	-- stored procedure body 
	--PROCURE
	v_procure := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_trn_tprocure');
								  
	call public.pr_iud_procurejson(v_procure);
								  
	-- PROCURE PRODUCT
	v_procure_prod := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_trn_tprocureproduct');
									   
	call public.pr_iud_procureproductjson(v_procure_prod);
	
					
	-- PROCURE PRODUCT QUALITY
	v_procure_prodqlty := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_trn_tprocureproductqlty');							 
	
	call public.pr_iud_procureproductqltyjson(v_procure_prodqlty);
	
	--SALE
	v_sale := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_trn_tsale');
								  
	call public.pr_iud_salejson(v_sale);
								  
	-- SALE PRODUCT
	v_sale_prod := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_trn_tsaleproduct');
									   
	call public.pr_iud_saleproductjson(v_sale_prod);
	
	-- PROCURE COST
	v_procure_cost := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_trn_tprocurecost');
								  
	call public.pr_iud_procurecostjson(v_procure_cost);
	
	-- SESSION
	v_session := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_trn_tsession');
								  
	call public.pr_iud_sessionjson(v_session);

	-- pgbuyer
	v_pgbuyer := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'pg_mst_tpgbuyer');
								  
	call public.pr_iud_pgbuyerjson(v_pgbuyer);

	-- pgdocnum
	v_pgdocnum := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'core_mst_tpgdocnum');

	call public.pr_iud_pgdocnumjson(v_pgdocnum);

	-- MOBILE SYNC
	v_mobilesync := (select t.value from (select * from json_each(_aggresync::udd_json)) as t
				where t.key = 'core_mst_tmobilesync');
								  
	call public.pr_iud_mobilesyncjson(v_mobilesync);

	select distinct pg_id into v_pg_id 
				from jsonb_to_recordset(v_mobilesync::udd_jsonb) as items 
	 									(
											mobilesync_gid		udd_int,
											pg_id				udd_code,
											role_code			udd_code,
											user_code			udd_code,
											mobile_no			udd_mobile,
											sync_type_code		udd_code,
											last_sync_date		udd_datetime,
											prev_last_sync_date	udd_datetime,
											status_code			udd_code,
											created_date   		udd_datetime,
											created_by			udd_user,
											updated_date		udd_text,
											updated_by			udd_user
										);
										
	v_pg_id := coalesce(v_pg_id,'');
	
	-- run payment process
	-- call pr_run_pgpaymentprocess(v_pg_id);
	
	--Send sms for procurement
	FOR v_colrec IN  select *
					 from 	jsonb_to_recordset(v_procure::udd_jsonb) as items 
													(
														proc_gid udd_int,
														pg_id udd_code,
														session_id udd_code,
														pgmember_id udd_code,
														proc_date udd_date,
														advance_amount udd_amount,
														sync_status_code udd_code,
														status_code udd_code,
														created_date udd_text,
														created_by udd_user,
														updated_date udd_text,
														updated_by udd_user
														)
														
							
	LOOP 
		v_advance_amount := v_colrec.advance_amount ;
		select fn_get_pgmembername(v_colrec.pg_id, v_colrec.pgmember_id) into v_pgmember_name;
		select fn_get_pgname(v_colrec.pg_id) into v_pg_name;
		select fn_get_pgmembermobileno(v_colrec.pg_id, v_colrec.pgmember_id) into v_mobile_no;
		v_procurement_date := v_colrec.proc_date;
		
		select 	array_agg(fn_get_productdesc(prod_code, 'en_US')),
				array_agg(fn_get_masterdesc('QCD_GRADE',grade_code,'en_US')),
				array_agg(proc_qty),
				array_agg(fn_get_masterdesc('QCD_UOM',uom_code,'en_US')) 
		into 	v_product_name,v_grade_value,v_product_qty,v_uom
		from 	pg_trn_tprocureproduct 
		where 	pg_id 		= v_colrec.pg_id
		and   	session_id 	= v_colrec.session_id
		and	  	pgmember_id = v_colrec.pgmember_id
		and	 	proc_date 	= v_colrec.proc_date;
		
		-- Send SMS for procurement
		SELECT 
				sms_template,dlt_template_id 
		into 	v_sms_template,v_dlt_template_id
		FROM 	core_mst_tsmstemplate
		where 	smstemplate_code = v_smstemplate_code
		and		lang_code = 'en_US'
		and 	status_code = 'A';

		v_sms_template := coalesce(v_sms_template,'');
		v_dlt_template_id := coalesce(v_dlt_template_id,'');
		
		if (v_dlt_template_id <> '') then
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Member_Name#}',coalesce(v_pgmember_name::udd_text,''));
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#PG_Name#}',coalesce(v_pg_name::udd_text,''));
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Procurement_Date#}',coalesce(v_procurement_date::udd_text,''));
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Product_Name#}',coalesce(v_product_name::udd_text,''));
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Grade_Value#}',coalesce(v_grade_value::udd_text,''));
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Quantity#}',coalesce(v_product_qty::udd_text,''));
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#UOM#}',coalesce(v_uom::udd_text,''));
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Advance_Amount#}',v_advance_amount::udd_text);

			-- Store procedure Call
			if v_advance_amount > 0 then
				call pr_iud_smstran(v_colrec.pg_id,
									v_smstemplate_code,
									v_dlt_template_id,
									v_mobile_no,
									v_sms_template,
									v_colrec.created_by,
									'udyogmitra');
			end if;
		end if;
	END LOOP;
			 
    open result_succ_msg for select 	
   							'Data Synced Successfully' ;

	
   
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mtwmobilesyncjson(_mobilesync udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 28-02-2022
		SP Code : B06MOSCUX
	*/
	v_mobilesync udd_jsonb;
	
begin
	-- stored procedure body 
	-- MOBILE SYNC
	v_mobilesync := (select t.value from (select * from json_each(_mobilesync::udd_json)) as t
				where t.key = 'core_mst_tmobilesync');
								  
	call public.pr_iud_mobilesyncjson(v_mobilesync);
								  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mtwprocurecostjson(_procurecost udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 28-02-2022
		SP Code : B06PRCCUX
	*/
	v_procure_cost udd_jsonb;
	
begin
	-- stored procedure body 
	-- PROCURE COST
	v_procure_cost := (select t.value from (select * from json_each(_procurecost::udd_json)) as t
				where t.key = 'pg_trn_tprocurecost');
								  
	call public.pr_iud_procurecostjson(v_procure_cost);
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mtwsalejson(_sale udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 28-02-2022
		SP Code : B06SALCUX
	*/
	v_sale udd_jsonb;
	v_sale_prod udd_jsonb;
	
begin
	-- stored procedure body 
	--SALE
	v_sale := (select t.value from (select * from json_each(_sale::udd_json)) as t
				where t.key = 'pg_trn_tsale');
								  
	call public.pr_iud_salejson(v_sale);
								  
	-- SALE PRODUCT
	v_sale_prod := (select t.value from (select * from json_each(_sale::udd_json)) as t
				where t.key = 'pg_trn_tsaleproduct');
									   
	call public.pr_iud_saleproductjson(v_sale_prod);
	
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_mtwsessionjson(_session udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 28-02-2022
		SP Code : B06SESCUX
	*/
	v_session udd_jsonb;
	
begin
	-- stored procedure body 
	-- SESSION
	v_session := (select t.value from (select * from json_each(_session::udd_json)) as t
				where t.key = 'pg_trn_tsession');
								  
	call public.pr_iud_sessionjson(v_session);
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_panchayatmasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Thianeswaran
		Created Date : 28-02-2022
		SP Code : B01PJMCUX  
		Updated By : Mangai
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														panchayat_id integer,
														state_id integer,
														district_id integer,
														block_id integer,
														panchayat_code char(10),
														panchayat_name_en varchar(100),
														panchayat_name_local varchar(200),
														language_id varchar(2),
														rural_urban_area varchar(1),
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
								
				insert into panchayat_master (
														panchayat_id,
														state_id,
														district_id,
														block_id,
														panchayat_code,
														panchayat_name_en,
														panchayat_name_local,
														language_id,
														rural_urban_area,
														is_active,
														created_date,
														created_by,
														updated_date,
														updated_by
												)
							values              (
													v_colrec.panchayat_id,
													v_colrec.state_id,
													v_colrec.district_id,
													v_colrec.block_id,
													v_colrec.panchayat_code,
													v_colrec.panchayat_name_en,
													v_colrec.panchayat_name_local,
													v_colrec.language_id,
													v_colrec.rural_urban_area,
													v_colrec.is_active,
													v_created_date,
													v_colrec.created_by,
													v_updated_date,
													v_colrec.updated_by
							)
							
		on CONFLICT (panchayat_id )  do update set  
													panchayat_id = v_colrec.panchayat_id,
													state_id = v_colrec.state_id,
													district_id = v_colrec.district_id,
													block_id = v_colrec.block_id,
													panchayat_code = v_colrec.panchayat_code,
													panchayat_name_en = v_colrec.panchayat_name_en,
													panchayat_name_local = v_colrec.panchayat_name_local,
													language_id = v_colrec.language_id,
													rural_urban_area = v_colrec.rural_urban_area,
													is_active = v_colrec.is_active,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;
		END LOOP;
		
		open result_succ_msg for select 	
   			'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgactivity(INOUT _pgactivitity_gid udd_int, _pg_id udd_code, _seq_no udd_int, _activity_code udd_code, _prod_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 17-12-2021
		SP Code : B04ATYCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;

	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB05FDTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- seq no cannot be blank
	if _seq_no <= 0 then
		v_err_code := v_err_code || 'VB04ATYCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATYCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- product code cannot be blank
	if _prod_code = '' then
		v_err_code := v_err_code || 'VB04ATYCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATYCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- Activity validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ACTIVITY'
				   and 		master_code = _activity_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ATYCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATYCUD_003', _lang_code) || v_new_line;	
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tactivity
				  where 	pg_id = _pg_id
				  and 		pgactivitity_gid = _pgactivitity_gid
				 ) then
				 
			delete from	pg_mst_tactivity
			where 	pg_id = _pg_id
			and 	pgactivitity_gid = _pgactivitity_gid;
			
			v_succ_code := 'SB04ATYCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tactivity
					  where		pg_id = _pg_id 
					  and 		prod_code = _prod_code
					  and	    activity_code = _activity_code	
					 ) then
			insert into pg_mst_tactivity 
			(
				pg_id,
				seq_no,
				activity_code,
				prod_code,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_seq_no,
				_activity_code,
				_prod_code,
				_user_code,
				now()
			) returning pgactivitity_gid into _pgactivitity_gid;
			
			v_succ_code := 'SB04ATYCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tactivity
				   where 	pg_id = _pg_id
				   and 		pgactivitity_gid = _pgactivitity_gid
				   ) then
			update	pg_mst_tactivity 
			set 	seq_no = _seq_no,
					activity_code = _activity_code,
					prod_code = _prod_code,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgactivitity_gid = _pgactivitity_gid;
			 
			v_succ_code := 'SB04ATYCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tactivity
			    where 	pg_id = _pg_id
			   	and     prod_code = _prod_code
			    and     activity_code  = _activity_code
				group	by activity_code
				having	count('*') > 1) 
	then
		-- activity code cannot be duplicated
		v_err_code := v_err_code || 'EB04ATYCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04ATYCUD_001', _lang_code),_activity_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgactivity(INOUT _pgactivitity_gid udd_int, _pg_id udd_code, _seq_no udd_int, _activity_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 17-12-2021
		SP Code : B04ATYCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB05FDTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- seq no cannot be blank
	if _seq_no <= 0 then
		v_err_code := v_err_code || 'VB04ATYCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATYCUD_002', _lang_code) || v_new_line;
	end if;
	
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ACTIVITY'
				   and 		master_code = _activity_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ATYCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATYCUD_003', _lang_code) || v_new_line;	
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tactivity
				  where 	pg_id = _pg_id
				  and 		pgactivitity_gid = _pgactivitity_gid
				 ) then
				 
			delete from	pg_mst_tactivity
			where 	pg_id = _pg_id
			and 	pgactivitity_gid = _pgactivitity_gid;
			
			v_succ_code := 'SB04ATYCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tactivity
					  where		pg_id = _pg_id 
					  and	    activity_code = _activity_code
					 ) then
			insert into pg_mst_tactivity 
			(
				pg_id,
				seq_no,
				activity_code,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_seq_no,
				_activity_code,
				_user_code,
				now()
			) returning pgactivitity_gid into _pgactivitity_gid;
			
			v_succ_code := 'SB04ATYCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tactivity
				   where 	pg_id = _pg_id
				   and 		pgactivitity_gid = _pgactivitity_gid
				   ) then
			update	pg_mst_tactivity 
			set 	seq_no = _seq_no,
					activity_code = _activity_code,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgactivitity_gid = _pgactivitity_gid;
			 
			v_succ_code := 'SB04ATYCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tactivity
			    where 	pg_id = _pg_id
			    and     activity_code  = _activity_code
				group	by activity_code
				having	count('*') > 1) 
	then
		-- activity code cannot be duplicated
		v_err_code := v_err_code || 'EB04ATYCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04ATYCUD_001', _lang_code),_activity_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgactivityjson(_pgactivitity_gid udd_int, _pg_id udd_code, _pgactivity udd_text, _prod_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 29-07-2022
		SP Code : B04ACTCUD
	*/
	
	v_colrec record;
	v_mode_flag udd_flag := '';
	
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	 v_mode_flag := _mode_flag;
	 
	 if v_mode_flag <> 'D' then
		 if exists (select '*' from pg_mst_tactivity 
					where 	pg_id         = _pg_id
					and 	prod_code     = _prod_code
					) then
			if v_mode_flag = 'U' then
				   delete from pg_mst_tactivity where pg_id = _pg_id
				   and prod_code = _prod_code;
			end if;	
			_mode_flag = 'I';
			
		  end if;
	  end if;
	 
	 FOR v_colrec IN select * from jsonb_to_recordset(_pgactivity::udd_jsonb) as items 
														 (activity_code udd_code) 

			LOOP 
				if v_mode_flag <> 'D' then 
					if v_mode_flag = 'I' then 
						if exists (select '*' from pg_mst_tactivity 
									where 		pg_id = _pg_id
									and 		prod_code = _prod_code
									and 		activity_code = v_colrec.activity_code) then
						
							-- activity code cannot be duplicated
							v_err_code := v_err_code || 'EB04ATYCUD_001';
							v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04ATYCUD_001', _lang_code),v_colrec.activity_code);	

							raise exception '%',v_err_code || '-' || v_err_msg;
						end if;
					end if;
					call pr_iud_pgactivity(
											   _pgactivitity_gid,
											   _pg_id,
											   1,
											   v_colrec.activity_code,
											   _prod_code,
											   _lang_code,
											   _user_code,
											   _mode_flag,
											   _succ_msg);
				else
					delete from pg_mst_tactivity 
					where 		pg_id = _pg_id
				   	and 		prod_code = _prod_code
					and 		activity_code = v_colrec.activity_code;
				end if;
			END LOOP;
				
			if v_mode_flag = 'I' then
				 v_succ_code := 'SB04ATYCUD_001';
				_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
			end if;
			
			if v_mode_flag = 'U' then
				 v_succ_code := 'SB04ATYCUD_002';
				_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
			end if;
			
			if v_mode_flag = 'D' then
				 v_succ_code := 'SB04ATYCUD_003';
				_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
			end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgactivityjson(_pgactivity udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 29-07-2022
		SP Code : B04ACTCUD
	*/
	
	v_colrec record;
--  v_delete_flag udd_flag := 'N';
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_pgactivity::udd_jsonb) as items 
													(
														pgactivitity_gid udd_int,
														pg_id udd_code,
														seq_no udd_int,
														activity_code udd_code,
														prod_code udd_code,
														lang_code udd_code,
														user_code udd_code,
														mode_flag udd_flag,
														succ_msg udd_text
														) 
												
			LOOP 
			
			call pr_iud_pgactivity(
									   v_colrec.pgactivitity_gid,
									   v_colrec.pg_id,
									   v_colrec.seq_no,
									   v_colrec.activity_code,
									   v_colrec.prod_code,
									   v_colrec.lang_code,
									   v_colrec.user_code,
									   v_colrec.mode_flag,
									   v_colrec.succ_msg);
			
			END LOOP;
			
	select 'Activity Created Successfully' into _succ_msg;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgaddress(INOUT _pgaddress_gid udd_int, _pg_id udd_code, _addr_type_code udd_code, _addr_line udd_text, _pin_code udd_pincode, _village_id udd_int, _panchayat_id udd_int, _block_id udd_int, _district_id udd_int, _state_id udd_int, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan s
		Created Date : 21-12-2021
		SP Code : B04ADDCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_pg_name   udd_desc := '';

begin
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB05FDTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- address type code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ADDR_TYPE'
				   and 		master_code = _addr_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ADDCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_002', _lang_code);	
	end if;
	
	-- address line cannot be blank
	if _addr_line = '' then
		v_err_code := v_err_code || 'VB04ADDCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- pincode cannot be blank
	if _pin_code = '' then
		v_err_code := v_err_code || 'VB04ADDCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- village id cannot be blank
	if _village_id <= 0 then
		v_err_code := v_err_code || 'VB04ADDCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- panchayat id cannot be blank
	if _panchayat_id <= 0 then
		v_err_code := v_err_code || 'VB04ADDCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_006', _lang_code) || v_new_line;
	end if;
	
	-- block id cannot be blank
	if _block_id <= 0 then
		v_err_code := v_err_code || 'VB04ADDCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_007', _lang_code) || v_new_line;
	end if;
	
	-- district id cannot be blank
	if _district_id <= 0 then
		v_err_code := v_err_code || 'VB04ADDCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_008', _lang_code) || v_new_line;
	end if;
	
	-- state id cannot be blank
	if _state_id <= 0 then
		v_err_code := v_err_code || 'VB04ADDCUD_009' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ADDCUD_009', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	-- Get Pgname
	select pg_name into v_pg_name 
	from 	pg_mst_tproducergroup 
	where 	pg_id = _pg_id
	and     status_code <> 'I';
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_mst_taddress
				  where 	pgaddress_gid = _pgaddress_gid
				 ) then
				 
			Delete from 	pg_mst_taddress
			where		    pgaddress_gid = _pgaddress_gid;
			
			v_succ_code := 'SB04ADDCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
	
		 update 	pg_mst_tproducergroup 
		 set 		panchayat_id = _panchayat_id
		 where	    pg_id = _pg_id 
		 and 		status_code <> 'I';
		 
		 if exists (	select	count(*)
						from 	pg_mst_tproducergroup
						where 	pg_name = v_pg_name
						and 	panchayat_id = _panchayat_id
						and     status_code <> 'I'
						group	by pg_name,panchayat_id
						having	count('*') > 1)
			then
				v_err_code := v_err_code || 'VB00CMNCMN_009' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_009', _lang_code) || v_new_line || v_pg_name;	
			raise exception '%',v_err_code || '-' || v_err_msg;
		
		 else
		 if not exists(select 	* 
					  from		pg_mst_taddress
					  where		pgaddress_gid = _pgaddress_gid
					 ) then
			insert into pg_mst_taddress 
			(
				pg_id,
				addr_type_code,
				addr_line,
				pin_code,
				village_id,
				panchayat_id,
				block_id,
				district_id,
				state_id,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_addr_type_code,
				_addr_line,
				_pin_code,
				_village_id,
				_panchayat_id,
				_block_id,
				_district_id,
				_state_id,
				_user_code,
				now()
			) returning pgaddress_gid into _pgaddress_gid;
			
			v_succ_code := 'SB04ADDCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
		
	elsif (_mode_flag = 'U') then 
		update 	pg_mst_tproducergroup 
		 set 		panchayat_id = _panchayat_id
		 where	    pg_id = _pg_id 
		 and 		status_code <> 'I';
		 
	  if exists (	select	count(*)
						from 	pg_mst_tproducergroup
						where 	pg_name = v_pg_name
						and 	panchayat_id = _panchayat_id
						and     status_code <> 'I'
						group	by pg_name,panchayat_id
						having	count('*') > 1)
			then
				v_err_code := v_err_code || 'VB00CMNCMN_009' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_009', _lang_code) || v_new_line || v_pg_name;	
			raise exception '%',v_err_code || '-' || v_err_msg;
		
		else
		if  exists(select 	*
				   from 	pg_mst_taddress
				   where	pgaddress_gid = _pgaddress_gid
				   ) then
			update	pg_mst_taddress 
			set 	pg_id = _pg_id,
					addr_type_code = _addr_type_code,
					addr_line = _addr_line,
					pin_code = _pin_code,
					village_id = _village_id,
					panchayat_id = _panchayat_id,
					block_id = _block_id,
					district_id = _district_id,
					state_id = _state_id,
					updated_by = _user_code,
					updated_date = now()
			where 	pgaddress_gid = _pgaddress_gid;
			
			v_succ_code := 'SB04ADDCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	  end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_taddress
			    where 	pg_id = _pg_id
			    and     addr_type_code = 'QCD_ADDRTYPE_REG' 
				group	by pg_id,addr_type_code
				having	count('*') > 1) 
	then
		-- Address type code cannot be duplicated
		v_err_code := v_err_code || 'EB04ADDCUD_001';
		v_err_msg  := v_err_msg || FORMAT(fn_get_msg('EB04ADDCUD_001', _lang_code),_addr_type_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
		
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgattachment(INOUT _pgattachment_gid udd_int, _pg_id udd_code, _doc_type_code udd_code, _doc_subtype_code udd_code, _file_path udd_text, _file_name udd_desc, _attachment_remark udd_desc, _original_verified_flag udd_flag, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 18-12-2021
		SP Code : B04ATMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB05FDTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- doc type code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_DOC_TYPE'
				   and 		master_code = _doc_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ATMCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_002', _lang_code) || v_new_line;		
	end if;
	
	-- doc subtype code cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_DOC_SUBTYPE'
				   and 		master_code = _doc_subtype_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ATMCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_003', _lang_code) || v_new_line;	
	end if;
	
	-- file name cannot be blank
	if _file_name = ''   then
		v_err_code := v_err_code || 'VB04ATMCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- file path cannot be blank
	if _file_path = ''   then
		v_err_code := v_err_code || 'VB04ATMCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- original verified flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _original_verified_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ATMCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_006', _lang_code) || v_new_line;		
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tattachment
				  where 	pg_id = _pg_id
				  and 		pgattachment_gid = _pgattachment_gid
				 ) then
				 
			delete from	pg_mst_tattachment
			where 	pg_id = _pg_id
			and 	pgattachment_gid = _pgattachment_gid;
			
			v_succ_code := 'SB04ATMCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tattachment
					  where		pg_id = _pg_id 
					  and       doc_type_code = _doc_type_code
					  and       doc_subtype_code = _doc_subtype_code
					  and       file_name = _file_name
					 ) then
			insert into  pg_mst_tattachment
			(
				pg_id,
				doc_type_code,
				doc_subtype_code,
				file_name,
				file_path,
				attachment_remark,
				original_verified_flag,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_doc_type_code,
				_doc_subtype_code,
				_file_name,
				_file_path,
				_attachment_remark,
				_original_verified_flag,
				_user_code,
				now()
			) returning pgattachment_gid into _pgattachment_gid;
			
			v_succ_code := 'SB04ATMCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tattachment
				   where 	pg_id = _pg_id
				   and 		pgattachment_gid = _pgattachment_gid
				   ) then
			update	pg_mst_tattachment 
			set 	doc_type_code = _doc_type_code,
					doc_subtype_code = _doc_subtype_code,
					file_name = _file_name,
					file_path = _file_path,
					attachment_remark = _attachment_remark,
					original_verified_flag = _original_verified_flag,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgattachment_gid = _pgattachment_gid;
			 
			v_succ_code := 'SB04ATMCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
		if exists (	select	count(*)
				from 	pg_mst_tattachment
			    where 	pg_id = _pg_id
			    and     doc_type_code  = _doc_type_code
			    and     doc_subtype_code  = _doc_subtype_code
			    and     file_name  = _file_name
				group	by doc_type_code
				having	count('*') > 1) 
	then
		-- file name cannot be duplicated
		v_err_code := v_err_code || 'EB04FUSCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04FUSCUD_001', _lang_code),_file_name);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgattachment_old(INOUT _pgattachment_gid udd_int, _pg_id udd_code, _doc_type_code udd_code, _doc_subtype_code udd_code, _file_path udd_text, _file_name udd_desc, _attachment_remark udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 18-12-2021
		
		Updated By 	: Vijayavel J
		Updated Date : 03-02-2022

		SP Code : B04ATMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB05FDTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDTCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- doc type code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_DOC_TYPE'
				   and 		master_code = _doc_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ATMCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_002', _lang_code);	
	end if;
	
	-- doc subtype code cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_DOC_SUBTYPE'
				   and 		master_code = _doc_subtype_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04ATMCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_003', _lang_code);	
	end if;
	
	-- file name cannot be blank
	if _file_name = ''   then
		v_err_code := v_err_code || 'VB04ATMCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- file path cannot be blank
	if _file_path = ''   then
		v_err_code := v_err_code || 'VB04ATMCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04ATMCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tattachment
				  where 	pg_id = _pg_id
				  and 		pgattachment_gid = _pgattachment_gid
				 ) then
				 
			delete from	pg_mst_tattachment
			where 	pg_id = _pg_id
			and 	pgattachment_gid = _pgattachment_gid;
			
			v_succ_code := 'SB04ATMCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tattachment
					  where		pg_id = _pg_id 
					  and       doc_type_code = _doc_type_code
					  and       doc_subtype_code = _doc_subtype_code
					  and       file_name = _file_name
					 ) then
			insert into  pg_mst_tattachment
			(
				pg_id,
				doc_type_code,
				doc_subtype_code,
				file_name,
				file_path,
				attachment_remark,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_doc_type_code,
				_doc_subtype_code,
				_file_name,
				_file_path,
				_attachment_remark,
				_user_code,
				now()
			) returning pgattachment_gid into _pgattachment_gid;
			
			v_succ_code := 'SB04ATMCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tattachment
				   where 	pg_id = _pg_id
				   and 		pgattachment_gid = _pgattachment_gid
				   ) then
			update	pg_mst_tattachment 
			set 	doc_type_code = _doc_type_code,
					doc_subtype_code = _doc_subtype_code,
					file_name = _file_name,
					file_path = _file_path,
					attachment_remark = _attachment_remark,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgattachment_gid = _pgattachment_gid;
			 
			v_succ_code := 'SB04ATMCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
		if exists (	select	count(*)
				from 	pg_mst_tattachment
			    where 	pg_id = _pg_id
			    and     doc_type_code  = _doc_type_code
			    and     doc_subtype_code  = _doc_subtype_code
			    and     file_name  = _file_name
				group	by doc_type_code
				having	count('*') > 1) 
	then
		-- file name cannot be duplicated
		v_err_code := v_err_code || 'EB04FUSCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04FUSCUD_001', _lang_code),_file_name);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgbank(INOUT _pgbank_gid udd_int, _pg_id udd_code, _bankacc_type_code udd_code, _ifsc_code udd_code, _bank_code udd_code, _bank_name udd_desc, _branch_name udd_desc, _bankacc_no udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 21-12-2021
		SP Code : B04BNKCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_bankacc_no udd_int := 0;
	v_pgbankaccno_max_count udd_int := 0;
	v_boolvalidation udd_boolean := false;
	v_bool udd_boolean := false;
begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	

	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- bankacc type code cannot be blank
	if _bankacc_type_code= '' then
		v_err_code := v_err_code || 'VB04BNKCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- ifsc code cannot be blank
	if _ifsc_code =  '' then
		v_err_code := v_err_code || 'VB04BNKCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- bank code cannot be blank
	if _bank_code = '' then
		v_err_code := v_err_code || 'VB04BNKCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- bank name cannot be blank
	if _bank_name = '' then
		v_err_code := v_err_code || 'VB04BNKCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- branch name cannot be blank
	if _branch_name = '' then
		v_err_code := v_err_code || 'VB04BNKCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_006', _lang_code) || v_new_line;
	end if;
	
	-- bank accno cannot be blank
	if _bankacc_no = '' then
		v_err_code := v_err_code || 'VB04BNKCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_007', _lang_code) || v_new_line;
	end if;
	
	/*-- bank accno less than 20 validation
	select 	config_value  into v_pgbankaccno_max_count
	from 	core_mst_tconfig 
	where 	config_name = 'pgbankaccno_max_count'
	and 	status_code = 'A';

	select length(_bankacc_no) into v_bankacc_no;
	if v_bankacc_no > v_pgbankaccno_max_count then
		v_err_code := v_err_code || 'VB04BNKCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_008', _lang_code) || v_new_line;
	end if;*/
	
	v_bool := (select fn_get_bankacclength(_bank_code, _bankacc_no));
	if v_bool = 'f' then
		v_err_code := v_err_code || 'VB04BNKCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BNKCUD_008', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_mst_tbank
				  where 	pgbank_gid = _pgbank_gid 
				 ) then
				 
			delete from 	pg_mst_tbank
			where 	pgbank_gid = _pgbank_gid;
			
			v_succ_code := 'SB04BNKCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tbank
					  where		pgbank_gid = _pgbank_gid
					 ) then
			insert into pg_mst_tbank 
			(
				pg_id,
				bankacc_type_code,
				ifsc_code,
				bank_code,
				bank_name,
				branch_name,
				bankacc_no,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bankacc_type_code,
				_ifsc_code,
				_bank_code,
				_bank_name,
				_branch_name,
				_bankacc_no,
				_user_code,
				now()
			) returning pgbank_gid into _pgbank_gid;
			
			v_succ_code := 'SB04BNKCUD_001';
			_succ_msg := fn_get_msg('SB00CMNCMN_001', _lang_code);
			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_mst_tbank
				   where	pgbank_gid = _pgbank_gid 
				   ) then
			update	pg_mst_tbank 
			set 	pg_id = _pg_id,
					bankacc_type_code = _bankacc_type_code,
					ifsc_code = _ifsc_code,
					bank_code = _bank_code,
					bank_name = _bank_name,
					branch_name = _branch_name,
					bankacc_no = _bankacc_no,
					updated_by = _user_code,
					updated_date = now()
			where 	pgbank_gid = _pgbank_gid;
			
			v_succ_code := 'SB04BNKCUD_002';
			_succ_msg := fn_get_msg('SB04BNKCUD_002', _lang_code);
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
   
   if exists (	select	count(*)
				from 	pg_mst_tbank
			    where 	pg_id = _pg_id
			    and     bank_code = _bank_code
			    and 	bankacc_no = _bankacc_no
				group	by bankacc_no
				having	count('*') > 1) 
	then
		-- duplicated record
		v_err_code := v_err_code || 'EB04BNKCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04BNKCUD_001', _lang_code),_bankacc_no);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgbomanager(INOUT _pgbomanager_gid udd_int, _pg_id udd_code, _bomanager_id udd_code, _bomanager_name udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Maangai
		Created Date : 02-09-2022
		SP Code : B04BOMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	

	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- bomanager id cannot be blank
	if _bomanager_id = '' then
		v_err_code := v_err_code || 'VB04BOMCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BOMCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- bomanager name cannot be blank
	if _bomanager_name = '' then
		v_err_code := v_err_code || 'VB04BOMCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BOMCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D') then
		if exists(select 	* 
				  from 		pg_mst_tbomanager
				  where 	pg_id           = _pg_id
				  and 		pgbomanager_gid = _pgbomanager_gid
				 ) then
			
			 delete from pg_mst_tbomanager
			 where 	pg_id           = _pg_id
			 and 	pgbomanager_gid = _pgbomanager_gid;
			
			v_succ_code := 'SB04BOMCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I') then
		if not exists(select 	* 
					  from		pg_mst_tbomanager
					  where		pg_id        = _pg_id 
					  and	    bomanager_id = _bomanager_id
					 ) then
			insert into pg_mst_tbomanager 
			(
				pg_id,
				bomanager_id,
				bomanager_name,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_bomanager_id,
				_bomanager_name,
				_user_code,
				now()
			) returning pgbomanager_gid into _pgbomanager_gid;
			
			v_succ_code := 'SB04BOMCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_mst_tbomanager
				   where 	pg_id     = _pg_id
				   and 		pgbomanager_gid = _pgbomanager_gid
				   ) then
			update	pg_mst_tbomanager 
			set     bomanager_id   = _bomanager_id,
					bomanager_name = _bomanager_name,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgbomanager_gid = _pgbomanager_gid;
			 
			v_succ_code := 'SB04BOMCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tbomanager
			    where 	pg_id = _pg_id
			    and     bomanager_id = _bomanager_id
				group	by bomanager_id
				having	count('*') > 1) 
	then
		-- clf office id cannot be duplicated
		v_err_code := v_err_code || 'EB04BOMCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04BOMCUD_001', _lang_code),_bomanager_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgbuyer(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By 	: Vijayavel J
		Created Date: 15-03-2022
		SP Code 	: B01BUYCUX
	*/
	
	v_colrec record;
	v_updated_date udd_datetime;
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
													(
														pgbuyer_gid udd_int,
														pg_id udd_code,
														buyer_name udd_desc,
														mobile_no udd_mobile,
														status_code udd_code,
														created_date udd_datetime,
														created_by udd_user,
														updated_date udd_text,
														updated_by udd_user
														) 
												
			LOOP
			
			 select	 fn_text_todatetime(v_colrec.updated_date) 
			 into 	 v_updated_date;
			
			insert into core_mst_tpgbuyer (
														pgbuyer_gid,
														pg_id ,
														buyer_name,
														mobile_no,
														status_code ,
														created_date ,
														created_by ,
														updated_date ,
														updated_by 
													)
										values		(
														v_colrec.pgbuyer_gid ,
														v_colrec.pg_id ,
														v_colrec.buyer_name ,
														v_colrec.mobile_no ,
														v_colrec.status_code ,
														v_colrec.created_date ,
														v_colrec.created_by ,
														v_updated_date ,
														v_colrec.updated_by 
													)
						
						on CONFLICT ( pg_id,
									  mobile_no) 
									 do update set  buyer_name = v_colrec.buyer_name,
													status_code = v_colrec.status_code,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;

			END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgbuyerjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By 	: Vijayavel J
		Created Date: 15-03-2022
		SP Code 	: B01BUYCUX
	*/
	
	v_colrec record;
	v_updated_date udd_datetime;
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
													(
														pgbuyer_gid udd_int,
														pg_id udd_code,
														buyer_name udd_desc,
														mobile_no udd_mobile,
														status_code udd_code,
														created_date udd_datetime,
														created_by udd_user,
														updated_date udd_text,
														updated_by udd_user
														) 
												
			LOOP
			
			 select	 fn_text_todatetime(v_colrec.updated_date) 
			 into 	 v_updated_date;
			
			insert into pg_mst_tpgbuyer (
														pgbuyer_gid,
														pg_id ,
														buyer_name,
														mobile_no,
														status_code ,
														created_date ,
														created_by ,
														updated_date ,
														updated_by 
													)
										values		(
														v_colrec.pgbuyer_gid ,
														v_colrec.pg_id ,
														v_colrec.buyer_name ,
														v_colrec.mobile_no ,
														v_colrec.status_code ,
														v_colrec.created_date ,
														v_colrec.created_by ,
														v_updated_date ,
														v_colrec.updated_by 
													)
						
						on CONFLICT ( pg_id,
									  mobile_no) 
									 do update set  buyer_name = v_colrec.buyer_name,
													status_code = v_colrec.status_code,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;

			END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgclf(INOUT _pgclf_gid udd_int, _pg_id udd_code, _clf_id udd_code, _clf_name udd_desc, _clf_officer_id udd_code, _clf_officer_name udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 17-12-2021
		SP Code : B04CLFCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- clf id cannot be blank
	if _clf_id = '' then
		v_err_code := v_err_code || 'VB04CLFCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04CLFCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- clf name cannot be blank
	if _clf_name = '' then
		v_err_code := v_err_code || 'VB04CLFCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04CLFCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- clf officer id cannot be blank
	if _clf_officer_id = '' then
		v_err_code := v_err_code || 'VB04CLFCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04CLFCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- clf officer name cannot be blank
	if _clf_officer_name = '' then
		v_err_code := v_err_code || 'VB04CLFCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04CLFCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D') then
		if exists(select 	* 
				  from 		pg_mst_tclf
				  where 	pg_id = _pg_id
				  and 		pgclf_gid = _pgclf_gid
				 ) then
			
			 delete from pg_mst_tclf
			 where 	pg_id = _pg_id
			 and 	pgclf_gid = _pgclf_gid;
			
			v_succ_code := 'SB04CLFCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I') then
		if not exists(select 	* 
					  from		pg_mst_tclf
					  where		pg_id = _pg_id 
					  and	    clf_id = _clf_id
					 ) then
			insert into pg_mst_tclf 
			(
				pg_id,
				clf_id,
				clf_name,
				clf_officer_id,
				clf_officer_name,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_clf_id,
				_clf_name,
				_clf_officer_id,
				_clf_officer_name,
				_user_code,
				now()
			) returning pgclf_gid into _pgclf_gid;
			
			v_succ_code := 'SB04CLFCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_mst_tclf
				   where 	pg_id = _pg_id
				   and 		pgclf_gid = _pgclf_gid
				   ) then
			update	pg_mst_tclf 
			set 	clf_id = _clf_id,
					clf_name = _clf_name,
					clf_officer_id = _clf_officer_id,
					clf_officer_name = _clf_officer_name,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgclf_gid = _pgclf_gid;
			 
			v_succ_code := 'SB04CLFCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tclf
			    where 	pg_id = _pg_id
			    and     clf_officer_id = _clf_officer_id
				group	by clf_officer_id
				having	count('*') > 1) 
	then
		-- clf office id cannot be duplicated
		v_err_code := v_err_code || 'EB04CLFCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04CLFCUD_001', _lang_code),_clf_officer_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgcollectionpoint(INOUT _collpoint_gid udd_int, _pg_id udd_code, _collpoint_no udd_int, _collpoint_name udd_desc, _collpoint_ll_name udd_desc, _latitude_code udd_code, _longitude_code udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan
		Created Date : 01-05-2022
		SP Code : B04COPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	
	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id	
				   and      status_code <> 'I'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	-- collection point no should be greater than zero
	if (_collpoint_no <= 0 )
	then
			v_err_code := v_err_code || 'VB04COPCUD_003' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04COPCUD_003', _lang_code)  || v_new_line;
	end if;
	
	-- collection point name cannot be empty
	if (_collpoint_name = '' )
	then
			v_err_code := v_err_code || 'VB04COPCUD_004' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04COPCUD_004', _lang_code)  || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tcollectionpoint
				  where 	pg_id = _pg_id
				  and 		collpoint_gid = _collpoint_gid
				 ) then
				 
			delete from	pg_mst_tcollectionpoint
			where 	pg_id = _pg_id
			and 	collpoint_gid = _collpoint_gid;
			
			v_succ_code := 'SB04COPCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tcollectionpoint
					  where		pg_id = _pg_id 
					  and       collpoint_name = _collpoint_name
					 ) then
			insert into  pg_mst_tcollectionpoint
			(
				pg_id,
				collpoint_no,
				collpoint_name,
				collpoint_ll_name,
				latitude_code,
				longitude_code,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_collpoint_no,
				_collpoint_name,
				_collpoint_ll_name,
				_latitude_code,
				_longitude_code,
				_user_code,
				now()
			) returning collpoint_gid into _collpoint_gid;
			
			v_succ_code := 'SB04COPCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tcollectionpoint
				   where 	pg_id = _pg_id
				   and 		collpoint_gid = _collpoint_gid
				   ) then
			update	pg_mst_tcollectionpoint 
			set 	collpoint_no = _collpoint_no,
			     	collpoint_name = _collpoint_name,
			    	collpoint_ll_name = _collpoint_ll_name,
					latitude_code = _latitude_code,
					longitude_code = _longitude_code,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	collpoint_gid = _collpoint_gid;
			 
			v_succ_code := 'SB04COPCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
		if exists (	select	count(*)
				from 	pg_mst_tcollectionpoint
			    where 	pg_id = _pg_id
				and 	collpoint_no = _collpoint_no
			    and     collpoint_name = _collpoint_name
				group	by pg_id,collpoint_no,collpoint_name
				having	count('*') > 1) 
	then
		-- coll point name cannot be duplicated
		v_err_code := v_err_code || 'EB04COPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04COPCUD_001', _lang_code),_collpoint_name);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgcollectionpoint(INOUT _collpoint_gid udd_int, _pg_id udd_code, _collpoint_no udd_int, _collpoint_name udd_desc, _collpoint_ll_name udd_desc, _collpoint_lang_code udd_code, _latitude_code udd_code, _longitude_code udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan
		Created Date : 01-05-2022
		
		Updated By : Mohan 
		Updated Date : 13-01-2023
		
		SP Code : B04COPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;

	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id	
				   and      status_code <> 'I'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	-- collection point no should be greater than zero
	if (_collpoint_no <= 0 )
	then
			v_err_code := v_err_code || 'VB04COPCUD_003' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04COPCUD_003', _lang_code)  || v_new_line;
	end if;
	
	-- collection point desc validation
	if (_collpoint_name = '' )
	then
			v_err_code := v_err_code || 'VB04COPCUD_004' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04COPCUD_004', _lang_code)  || v_new_line;
	end if;
	
	-- collpoint language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _collpoint_lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tcollectionpoint
				  where 	pg_id = _pg_id
				  and 		collpoint_gid = _collpoint_gid
				 ) then
				 
			/*delete from	pg_mst_tcollectionpoint
			where 	pg_id = _pg_id
			and 	collpoint_gid = _collpoint_gid;*/
			
			update pg_mst_tcollectionpoint
			set 	status_code = 'I',
					updated_by = _user_code,
					updated_date = now()
			where 	pg_id = _pg_id
			and 	collpoint_gid = _collpoint_gid;
			
			v_succ_code := 'SB04COPCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
			  
		if not exists(select 	* 
					  from		pg_mst_tcollectionpoint
					  where		pg_id = _pg_id 
					  and       collpoint_name = _collpoint_name
					  and       collpoint_lang_code = _collpoint_lang_code
					 ) then
			insert into  pg_mst_tcollectionpoint
			(
				pg_id,
				collpoint_no,
				collpoint_name,
				collpoint_ll_name,
				collpoint_lang_code,
				latitude_code,
				longitude_code,
				status_code,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_collpoint_no,
				_collpoint_name,
				_collpoint_ll_name,
				_collpoint_lang_code,
				_latitude_code,
				_longitude_code,
				'A',
				_user_code,
				now()
			) returning collpoint_gid into _collpoint_gid;
			
			v_succ_code := 'SB04COPCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
	
		if  exists(select 	*
				   from 	pg_mst_tcollectionpoint
				   where 	pg_id = _pg_id
				   and 		collpoint_gid = _collpoint_gid
				   ) then
			update	pg_mst_tcollectionpoint 
			set 	
-- 					collpoint_no = _collpoint_no,
					collpoint_name = _collpoint_name,
					collpoint_ll_name = _collpoint_ll_name,
					collpoint_lang_code = _collpoint_lang_code,
					latitude_code = _latitude_code,
					longitude_code = _longitude_code,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	collpoint_gid = _collpoint_gid;
			 
			v_succ_code := 'SB04COPCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tcollectionpoint
			    where 	pg_id 		 = _pg_id
			    and 	collpoint_name = _collpoint_name
			    and 	collpoint_lang_code = _collpoint_lang_code
				group	by pg_id,collpoint_name,collpoint_lang_code
				having	count('*') > 1) 
	then
		-- coll point name cannot be duplicated
		v_err_code := v_err_code || 'EB04COPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04COPCUD_001', _lang_code),_collpoint_name);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgcollectionpointtranslate(INOUT _collpointtranslate_gid udd_int, _pg_id udd_code, _collpoint_no udd_int, _collpoint_lang_code udd_code, _collpoint_desc udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan
		Created Date : 27-07-2022
		SP Code : B04CPTCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id	
				   and      status_code <> 'I'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	-- collection point no should be greater than zero
	if (_collpoint_no <= 0 )
	then
			v_err_code := v_err_code || 'VB04COPCUD_003' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04COPCUD_003', _lang_code)  || v_new_line;
	end if;

	-- collection point desc validation
	if (_collpoint_desc = '' )
	then
			v_err_code := v_err_code || 'VB04COPCUD_004' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04COPCUD_004', _lang_code)  || v_new_line;
	end if;
	
	-- collpoint language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _collpoint_lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_mst_tcollectionpointtranslate
				  where 	collpointtranslate_gid = _collpointtranslate_gid
				 ) then
				 
			Delete from 	pg_mst_tcollectionpointtranslate
			where		    collpointtranslate_gid = _collpointtranslate_gid;
			
			v_succ_code := 'SB04COPCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tcollectionpointtranslate
					  where		pg_id 	  	 = _pg_id
					  and 		collpoint_no = _collpoint_no
					  and       lang_code 	 = _collpoint_lang_code
					 ) then
			insert into pg_mst_tcollectionpointtranslate 
			(
				pg_id,
				collpoint_no,
				lang_code,
				collpoint_desc
			)
			values
			(
				_pg_id,
				_collpoint_no,
				_collpoint_lang_code,
				_collpoint_desc
			) returning collpointtranslate_gid into _collpointtranslate_gid;
			
			v_succ_code := 'SB04COPCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_mst_tcollectionpointtranslate
				   where	collpointtranslate_gid = _collpointtranslate_gid
				   ) then
			update	pg_mst_tcollectionpointtranslate 
			set		collpoint_no			= _collpoint_no,
					lang_code 				= _collpoint_lang_code,
					collpoint_desc 			= _collpoint_desc
			where 	collpointtranslate_gid 	= _collpointtranslate_gid;
			
			v_succ_code := 'SB04COPCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
		if exists (	select	count(*)
				from 	pg_mst_tcollectionpointtranslate
			    where 	pg_id 		 = _pg_id
			    and 	collpoint_no = _collpoint_no
			    and 	lang_code 	 = _collpoint_lang_code
				group	by pg_id,collpoint_no,lang_code
				having	count('*') > 1) 
		then
		-- coll point desc cannot be duplicated
		v_err_code := v_err_code || 'EB04COPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04COPCUD_001', _lang_code),_collpoint_desc);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgdocnumjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By 	: Vijayavel J
		Created Date: 15-03-2022
		SP Code 	: B01PDNCUX
	*/
	
	v_colrec record;
	v_updated_date udd_datetime;
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
													(
														pgdocnum_gid udd_int,
														activity_code udd_code,
														pg_id udd_code,
														finyear_id udd_code,
														tran_date udd_date,
														next_seq_no udd_int,
														docnum_format udd_code,
														docnum_remark udd_desc,
														status_code udd_code,
														created_date udd_datetime,
														created_by udd_user,
														updated_date udd_text,
														updated_by udd_user
														) 
												
			LOOP
			
			 select	 fn_text_todatetime(v_colrec.updated_date) 
			 into 	 v_updated_date;
			
			insert into core_mst_tpgdocnum (
														pg_id ,
														activity_code,
														finyear_id ,
														tran_date ,
														next_seq_no ,
														docnum_format,
														docnum_remark,
														status_code ,
														created_date ,
														created_by ,
														updated_date ,
														updated_by 
													)
										values		(
														v_colrec.pg_id ,
														v_colrec.activity_code ,
														v_colrec.finyear_id ,
														v_colrec.tran_date ,
														v_colrec.next_seq_no ,
														v_colrec.docnum_format ,
														v_colrec.docnum_remark ,
														v_colrec.status_code ,
														v_colrec.created_date ,
														v_colrec.created_by ,
														v_updated_date ,
														v_colrec.updated_by 
													)
						
						on CONFLICT ( pg_id,
									  activity_code,
									  finyear_id,
									  tran_date) 
									 do update set  next_seq_no = v_colrec.next_seq_no,
													status_code = v_colrec.status_code,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;

			END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgfinancesumm(INOUT _pgfinsumm_gid udd_int, _pg_id udd_code, _till_date udd_date, _cash_in_hand udd_amount, _cash_in_bank udd_amount, _opening_stock_value udd_amount, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 18-12-2021
		SP Code : B04FISCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	/*v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;*/
	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- till date cannot be blank
	if _till_date is NULL   then
		v_err_code := v_err_code || 'VB04FISCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FISCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- cash in hand validation
	if _cash_in_hand < 0   then
		v_err_code := v_err_code || 'VB04FISCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FISCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- cash in bank validation
	if _cash_in_bank < 0   then
		v_err_code := v_err_code || 'VB04FISCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FISCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- opening stock value validation
	if _opening_stock_value < 0   then
		v_err_code := v_err_code || 'VB04FISCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FISCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tfinancesumm
				  where 	pg_id = _pg_id
				  and 		pgfinsumm_gid = _pgfinsumm_gid
				 ) then
				 
			delete from	pg_mst_tfinancesumm
			where 	pg_id = _pg_id
			and 	pgfinsumm_gid = _pgfinsumm_gid;
			
			v_succ_code := 'SB04FISCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tfinancesumm
					  where		pg_id = _pg_id 
					  and 		till_date = _till_date
					 ) then
			insert into  pg_mst_tfinancesumm
			(
				pg_id,
				till_date,
				cash_in_hand,
				cash_in_bank,
				opening_stock_value,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_till_date,
				_cash_in_hand,
				_cash_in_bank,
				_opening_stock_value,
				_user_code,
				now()
			) returning pgfinsumm_gid into _pgfinsumm_gid;
			
			v_succ_code := 'SB04FISCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tfinancesumm
				   where 	pg_id = _pg_id
				   and 		pgfinsumm_gid = _pgfinsumm_gid
				   ) then
			update	pg_mst_tfinancesumm 
			set 	till_date = _till_date,
					cash_in_hand = _cash_in_hand,
					cash_in_bank = _cash_in_bank,
					opening_stock_value = _opening_stock_value,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgfinsumm_gid = _pgfinsumm_gid;
			 
			v_succ_code := 'SB04FISCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tfinancesumm
			    where 	pg_id = _pg_id
			    and     till_date = _till_date
				group	by till_date
				having	count('*') > 1) 
	then
		-- till date cannot be duplicated
		v_err_code := v_err_code || 'EB04FISCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04FISCUD_001', _lang_code),_till_date);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgfund(INOUT _pgfund_gid udd_int, _pg_id udd_code, _pgfund_code udd_code, _pgfund_date udd_date, _pgfund_source_code udd_code, _pgfund_amount udd_amount, _pgfund_available_amount udd_amount, _pgfund_remark udd_text, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 23-02-2022
		
		Updated By   : Mohan
		Updated Date : 05-03-2022
		
		SP Code      : B05FUNCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_avail_amt udd_amount := 0;
	v_fund_amt udd_amount := 0;
begin
-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id     = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- PG Fund Code Validation
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_PGFUND' 
				   and 	  master_code = _pgfund_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_020' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_020', _lang_code) || v_new_line;		
	end if;

-- PG Fund Source Code Validation	
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_PGFUND_SOURCE' 
				   and 	  master_code = _pgfund_source_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB05FUNCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUNCUD_001', _lang_code) || v_new_line;		
	end if;
	
/*-- PG Fund Amount Validation
	if _pgfund_amount <= 0 
	then
		v_err_code := v_err_code || 'VB05FUNCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB05FUNCUD_002', _lang_code) || v_new_line;
	end if;	*/

/* -- PG Fund Available Amount Validation
	if _pgfund_available_amount  
	then
		v_err_code := v_err_code || 'VB05FUNCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB05FUNCUD_003', _lang_code) || v_new_line;
	end if;	*/
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code   = 'QCD_STATUS' 
				   and   master_code   = _status_code 
				   and   status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	-- UPDATE VALIDATION
	if(_mode_flag <> 'I') then 
		select 
				pgfund_amount,pgfund_available_amount 
		into 	v_fund_amt,v_avail_amt 
		from 	pg_trn_tpgfund
		where 	pgfund_gid  = _pgfund_gid
		and	    status_code <>	'I';
		
		if(_mode_flag = 'U') then
			if( _pgfund_amount - (v_fund_amt - v_avail_amt) ) < 0 then
				v_err_code := v_err_code || 'VB05FUNCUD_003' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUNCUD_003', _lang_code) || v_new_line;	
			end if;
		end if;
		
		if(_mode_flag = 'D') then
			if v_fund_amt <> v_avail_amt then
				v_err_code := v_err_code || 'VB05FUNCUD_004' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUNCUD_004', _lang_code) || v_new_line;	
			end if;
		end if;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tpgfund
				  where pgfund_gid    = _pgfund_gid
				  and   status_code <> 'I')
			then
			update pg_trn_tpgfund 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where pgfund_gid 	= _pgfund_gid
				and	pg_id		    = _pg_id
				and pgfund_amount   = pgfund_available_amount
				and status_code	    <> 'I';
			v_succ_code := 'SB05FUNCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
		elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tpgfund
				   where pgfund_gid 	= _pgfund_gid
				   and   pg_id		    = _pg_id)
		 then
			insert into pg_trn_tpgfund(
				pg_id,
				pgfund_code,
				pgfund_date,
				pgfund_source_code,
				pgfund_amount,
				pgfund_available_amount,
				pgfund_remark,
				status_code,
				created_date,
				created_by
				)
			values(
				_pg_id,
				_pgfund_code,
				now(),
				_pgfund_source_code,
				_pgfund_amount,
				_pgfund_amount,
				_pgfund_remark,
				_status_code,
				now(),
				_user_code
				) returning pgfund_gid into _pgfund_gid;
				v_succ_code := 'SB05FUNCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tpgfund
				   where pgfund_gid  = _pgfund_gid
				   and   status_code <> 'I' )
		then
		update pg_trn_tpgfund
		set		pg_id					 = _pg_id,
				pgfund_code				 = _pgfund_code,
				pgfund_source_code		 = _pgfund_source_code,
				pgfund_amount			 = _pgfund_amount,
-- 				pgfund_available_amount	 = _pgfund_amount,
				pgfund_remark			 = _pgfund_remark,
				status_code              = _status_code,
				updated_date			 = now(),
				updated_by				 = _user_code
		where   pgfund_gid               = _pgfund_gid
		and	    status_code			     <>	'I';
		 v_succ_code	:= 'SB05FUNCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tpgfund
			    where 	pg_id       = _pg_id 
			    and 	pgfund_code = _pgfund_code
			    group	by pg_id, pgfund_code
				having	count('*') > 1) 
	then
		-- pg id and pgfund_codde cannot be duplicated
		v_err_code := v_err_code || 'EB05FUNCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB05FUNCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgfundexpenses(INOUT _pgfundexp_gid udd_int, _pg_id udd_code, _pgfund_code udd_code, _expense_head_code udd_code, _expense_date udd_date, _expense_amount udd_amount, _recovery_flag udd_flag, _recovered_flag udd_flag, _beneficiary_name udd_desc, _expense_remark udd_text, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 23-02-2022
		SP Code      : B05FUECUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_expense_amount udd_amount := 0;
	v_available_amount udd_amount := 0;
	v_value udd_amount	 := 0;
	v_value1 udd_amount  := 0;
	v_value2 udd_amount  := 0;
	v_pgfund_amount udd_amount := 0;
	v_available_amount1 udd_amount := 0;
	v_value3 udd_amount  := 0;
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id       = _pg_id 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- PG Fund Code Validation
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_PGFUND' 
				   and 	  master_code = _pgfund_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_020' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_020', _lang_code) || v_new_line;		
	end if;

-- PG Fund Expense Head Code Validation
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_PGFUND_EXPHEAD' 
				   and 	  master_code = _expense_head_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB05FUECUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUECUD_001', _lang_code) || v_new_line;		
	end if;
	
-- Expense Amount Validation
	if _expense_amount <= 0 
	then
		v_err_code := v_err_code || 'VB05FUECUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB05FUECUD_002', _lang_code) || v_new_line;
	end if;	
	
-- Recovery Flag Code Validation
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_YES_NO' 
				   and 	  master_code = _recovery_flag 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB05FUECUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUECUD_003', _lang_code) || v_new_line;		
	end if;
	
-- Beneficiary Name Validation
	if _beneficiary_name = '' 
	then
		v_err_code := v_err_code || 'VB05FUECUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUECUD_005', _lang_code) || v_new_line;		
	end if;
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code   = 'QCD_STATUS' 
				   and   master_code   = _status_code 
				   and   status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
			
		
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	select 	coalesce(pgfund_available_amount,0) into v_available_amount
	from  	pg_trn_tpgfund
	where 	pg_id       = _pg_id
	and   	pgfund_code = _pgfund_code
	and   	status_code = 'A';
	
	if _mode_flag = 'D' then
		if exists(select * from  pg_trn_tpgfundexpenses
				  where pgfundexp_gid    = _pgfundexp_gid
				  and 	pg_id = _pg_id 
				  and   status_code      <> 'I')
		 then
			select coalesce(expense_amount,0) into v_expense_amount
			from pg_trn_tpgfundexpenses
			where pg_id = _pg_id 
			and pgfundexp_gid    = _pgfundexp_gid;
			
			
			update pg_trn_tpgfund
				set pgfund_available_amount = coalesce(pgfund_available_amount,0) + coalesce(v_expense_amount,0)
				where pg_id =_pg_id;
			
			update pg_trn_tpgfundexpenses 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where pgfundexp_gid = _pgfundexp_gid
				and	pg_id		    = _pg_id
				and status_code	    <> 'I';
					
			v_succ_code := 'SB05FUECUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif _mode_flag = 'I' then
		
		if v_available_amount < _expense_amount then
			v_err_code := v_err_code || 'VB05FUECUD_007';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUECUD_007', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
			
		end if;
		
		if not exists (select * from pg_trn_tpgfundexpenses
				   where pgfundexp_gid 	= _pgfundexp_gid
				   and   pg_id		    = _pg_id)
		 then 
		    
			insert into pg_trn_tpgfundexpenses(
				pg_id,
				pgfund_code,
				expense_head_code,
				expense_date,
				expense_amount,
				recovery_flag,
				recovered_flag,
				beneficiary_name,
				expense_remark,
				status_code,
				created_date,
				created_by)
			values(
				_pg_id,
				_pgfund_code,
				_expense_head_code,
				now(),
				_expense_amount,
				_recovery_flag,
				'N', -- default value
				_beneficiary_name,
				_expense_remark,
				_status_code,
				now(),
				_user_code) returning pgfundexp_gid into _pgfundexp_gid;
			
			update pg_trn_tpgfund
			set pgfund_available_amount = pgfund_available_amount - _expense_amount
			where pg_id = _pg_id;
			
				
			v_succ_code := 'SB05FUECUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tpgfundexpenses
				   where pgfundexp_gid  = _pgfundexp_gid
				   and   status_code    <> 'I' )
		then
			select expense_amount into v_expense_amount
			from pg_trn_tpgfundexpenses
			where pg_id          = _pg_id
			and   pgfundexp_gid  = _pgfundexp_gid;
			
			if (v_available_amount + v_expense_amount) < _expense_amount then
				v_err_code := v_err_code || 'VB05FUECUD_007';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB05FUECUD_007', _lang_code) || v_new_line;	
				RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
				
			end if;
			
			update pg_trn_tpgfundexpenses
			set		pg_id				= _pg_id,
					pgfund_code			= _pgfund_code,
					expense_head_code	= _expense_head_code,
					expense_amount		= _expense_amount,
					recovery_flag		= _recovery_flag,
					beneficiary_name	= _beneficiary_name,
					expense_remark		= _expense_remark,
					status_code			= _status_code,
					updated_date		= now(),
					updated_by			= _user_code
			where   pgfundexp_gid       = _pgfundexp_gid
			and	    status_code			<> 'I';
			
			v_value1 := v_value - _expense_amount;
			
			update pg_trn_tpgfund
			set pgfund_available_amount = pgfund_available_amount + v_expense_amount - _expense_amount
			where pg_id = _pg_id;
		
		v_succ_code	:= 'SB05FUECUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgfundledger(INOUT _pgfundledger_gid udd_int, _pg_id udd_code, _pgfund_code udd_code, _pgfund_trantype_code udd_code, _pgfund_ledger_code udd_code, _tran_date udd_date, _dr_amount udd_amount, _cr_amount udd_amount, _recovery_flag udd_flag, _recovered_flag udd_flag, _beneficiary_name udd_text, _pgfund_remark udd_text, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 07-03-2022
		SP Code      : B05FDLCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where 	pg_id  = _pg_id 
				   and 		status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- PG Fund Code Validation
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_PGFUND' 
				   and 	  master_code = _pgfund_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_020' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_020', _lang_code) || v_new_line;		
	end if;

	-- PG Fund trantype Code Validation	
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_PGFUND_TRANTYPE' 
				   and 	  master_code = _pgfund_trantype_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB05FDLCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_001', _lang_code) || v_new_line;		
	end if;
	
	-- PG Fund Ledger Code Validation	
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_ACC_HEAD' 
				   and 	  master_code = _pgfund_ledger_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB05FDLCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_002', _lang_code) || v_new_line;		
	end if;
	
	-- Tran Date Validation 
	if _tran_date isnull
	then
		v_err_code := v_err_code || 'VB05FDLCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_003', _lang_code) || v_new_line;		
	end if;
	
	if _tran_date > now()::udd_date
	then
		v_err_code := v_err_code || 'VB05FDLCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_004', _lang_code) || v_new_line;		
	end if;
	
	-- Debit Amount Validation
	if _pgfund_trantype_code = 'QCD_PGFUND_EXPENSES'
	then 
		if _dr_amount <= 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_005' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_005', _lang_code) || v_new_line;		
		end if;
		if _cr_amount <> 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_010' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_010', _lang_code) || v_new_line;		
		end if;
	end if;
	
	-- Credit Amount Validation
	if _pgfund_trantype_code = 'QCD_PGFUND_SOURCE'
	then 
		if _cr_amount <= 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_006' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_006', _lang_code) || v_new_line;		
		end if;
		if _dr_amount <> 0
		then
			v_err_code := v_err_code || 'VB05FDLCUD_011' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_011', _lang_code) || v_new_line;		
		end if;
	end if;
	
	-- Recovery Flag Validation
	if not exists (select * from core_mst_tmaster 
				   where 	parent_code   = 'QCD_YES_NO' 
				   and   	master_code   = _recovery_flag 
				   and   	status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB05FDLCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_007', _lang_code) || v_new_line;		
	end if;
	
	-- Recovered Flag Validation
	if not exists (select * from core_mst_tmaster 
				   where 	parent_code   = 'QCD_YES_NO' 
				   and   	master_code   = _recovered_flag 
				   and   	status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB05FDLCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_008', _lang_code) || v_new_line;		
	end if;
	
	-- Beneficiary Name Validation
	if _pgfund_trantype_code = 'QCD_PGFUND_EXPENSES'
	then
		if _beneficiary_name = ''
		then
			v_err_code := v_err_code || 'VB05FDLCUD_009' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDLCUD_009', _lang_code) || v_new_line;		
		end if;
	end if;
	
	-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where 	parent_code   = 'QCD_STATUS' 
				   and   	master_code   = _status_code 
				   and   	status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where 	lang_code   = _lang_code
				   and   	status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tpgfundledger
				  where pgfundledger_gid    = _pgfundledger_gid
				  and   status_code <> 'I')
			then
			update 	pg_trn_tpgfundledger 
			set		status_code 	 = 'I',
					updated_by		 = _user_code,
					updated_date	 = now()
			where 	pgfundledger_gid = _pgfundledger_gid
			and		pg_id		     = _pg_id
			and 	status_code	    <> 'I';
			
			v_succ_code := 'SB05FDLCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tpgfundledger
				   	   where 	pgfundledger_gid = _pgfundledger_gid
				   	   and   	pg_id		     = _pg_id)
		 then
			insert into pg_trn_tpgfundledger(
												pg_id,
												pgfund_code,
												pgfund_trantype_code,
												pgfund_ledger_code,
												tran_date,
												dr_amount,
												cr_amount,
												recovery_flag,
												recovered_flag,
												beneficiary_name,
												pgfund_remark,
												status_code,
												created_date,
												created_by
															)
										values(
												_pg_id,
												_pgfund_code,
												_pgfund_trantype_code,
												_pgfund_ledger_code,
												_tran_date,
												_dr_amount,
												_cr_amount,
												_recovery_flag,
												_recovered_flag,
												_beneficiary_name,
												_pgfund_remark,
												_status_code,
												now(),
												_user_code
												) returning pgfundledger_gid into _pgfundledger_gid;
												v_succ_code := 'SB05FDLCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tpgfundledger
				   where 	pgfundledger_gid  = _pgfundledger_gid
				   and   	status_code <> 'I' )
		then
		update  pg_trn_tpgfundledger
		set		pg_id					 = _pg_id,
				pgfund_code				 = _pgfund_code,
				pgfund_trantype_code	 = _pgfund_trantype_code,
				pgfund_ledger_code		 = _pgfund_ledger_code,
 				tran_date	 			 = _tran_date,
				dr_amount				 = _dr_amount,
				cr_amount				 = _cr_amount,
				recovery_flag 			 = _recovery_flag,
				recovered_flag 			 = _recovered_flag,
				beneficiary_name 		 = _beneficiary_name,
				pgfund_remark			 = _pgfund_remark,
				status_code              = _status_code,
				updated_date			 = now(),
				updated_by				 = _user_code
		where   pgfundledger_gid         = _pgfundledger_gid
		and	    status_code			     <>	'I';
			    v_succ_code	:= 'SB05FDLCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgfundsupport(INOUT _pgfundsupp_gid udd_int, _pg_id udd_code, _fund_source_code udd_code, _fund_type_code udd_code, _fund_supp_date udd_date, _fund_supp_amount udd_amount, _purpose_code udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
			Created By : Mohan
			Created Date : 31-12-2021
			SP Code : B04FUSCUD
			
			Updated By : Mohan S
			Updated Date : 11-01-2022
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- fund source code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_FUND_SOURCE'
				   and 		master_code = _fund_source_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04FUSCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FUSCUD_002', _lang_code);	
	end if;
	 
	
	-- fund type code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_FUND_TYPE'
				   and 		master_code = _fund_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04FUSCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FUSCUD_003', _lang_code);	
	end if;
	 
	-- fund supp date cannot be blank
	if _fund_supp_date is Null   then
		v_err_code := v_err_code || 'VB04FUSCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FUSCUD_004', _lang_code) || v_new_line;
	end if;
	
    -- fund supp future date could not allow
	if _fund_supp_date > now()   then
		v_err_code := v_err_code || 'VB00CMNCMN_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_007', _lang_code) || v_new_line;
	end if;
	
	-- fund support amount cannot be blank
	if _fund_supp_amount = 0.00   then
		v_err_code := v_err_code || 'VB04FUSCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FUSCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- purpose code cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PURPOSE'
				   and 		master_code = _purpose_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04FUSCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04FUSCUD_006', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tfundsupport
				  where 	pg_id = _pg_id
				  and 		pgfundsupp_gid = _pgfundsupp_gid
				 ) then
				 
			delete from	pg_mst_tfundsupport
			where 	pg_id = _pg_id
			and 	pgfundsupp_gid = _pgfundsupp_gid;
			
			v_succ_code := 'SB04FUSCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tfundsupport
					    where	pg_id = _pg_id 
					   	and     fund_source_code  = _fund_source_code
						and 	fund_type_code = _fund_type_code
						and		fund_supp_date = _fund_supp_date
					    and 	purpose_code = _purpose_code	
					 ) then
			insert into  pg_mst_tfundsupport
			(
				pg_id,
				fund_source_code,
				fund_type_code,
				fund_supp_date,
				fund_supp_amount,
				purpose_code,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_fund_source_code,
				_fund_type_code,
				_fund_supp_date,
				_fund_supp_amount,
				_purpose_code,
				_user_code,
				now()
			) returning pgfundsupp_gid into _pgfundsupp_gid;
			
			v_succ_code := 'SB04FUSCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tfundsupport
				   where 	pg_id = _pg_id
				   and 		pgfundsupp_gid = _pgfundsupp_gid
				   ) then
			update	pg_mst_tfundsupport 
			set 	fund_source_code = _fund_source_code,
					fund_type_code = _fund_type_code,
					fund_supp_date = _fund_supp_date,
					fund_supp_amount = _fund_supp_amount,
					purpose_code = _purpose_code,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgfundsupp_gid = _pgfundsupp_gid;
			 
			v_succ_code := 'SB04FUSCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
		if exists (	select	count(*)
				from 	pg_mst_tfundsupport
			    where 	pg_id = _pg_id
			    and     fund_source_code  = _fund_source_code
				and 	fund_type_code = _fund_type_code
				and		fund_supp_date = _fund_supp_date
				and     purpose_code = _purpose_code
				group	by purpose_code
				having	count('*') > 1) 
	then
		-- duplicated validation
		v_err_code := v_err_code || 'EB04FUSCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04FUSCUD_001', _lang_code),_purpose_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgmemberledger(INOUT _pgmemberledger_gid udd_int, _pg_id udd_code, _pgmember_id udd_code, _acchead_code udd_code, _tran_date udd_datetime, _dr_amount udd_amount, _cr_amount udd_amount, _tran_narration udd_text, _tran_ref_no udd_text, _tran_remark udd_text, _status_code udd_code, _paymode_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 31-12-2021
		
		Updated By : Vijayavel J
		Updated Date : 12-03-2022
		
		SP Code : B07MLGCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
	
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_MEM_PAYMENT';
	v_pgname udd_desc := '';
	v_pgmembername udd_desc := '';
	v_mobile_no udd_mobile := '';
begin
	-- validation
	if _tran_date is null then
		_tran_date := now();
	end if;
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id
				   and		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	-- pg member id Validation
	if not exists (select 	* 
				   from 	pg_mst_tpgmember 
				   where 	pg_id 		= _pg_id
				   and 		pgmember_id = _pgmember_id 				  
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_005', _lang_code)  || v_new_line;	
	end if;

	-- acchead_code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_ACC_HEAD'
				   and 		master_code = _acchead_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB07MLGCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_001', _lang_code) || v_new_line;	
	end if;
	
	/*-- tran_date cannot be empty
	if (_tran_date is null) 
	 then
		v_err_code := v_err_code || 'VB07MLGCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_006', _lang_code)  || v_new_line;	
	end if;*/
	
	-- tran_date cannot future
	if _tran_date > now()
	 then
		v_err_code := v_err_code || 'VB00CMNCMN_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_007', _lang_code)  || v_new_line;	
	end if;
	
	-- dr_amount and _cr_amount cannot be zero 
	if _dr_amount <= 0 and  _cr_amount <= 0 
	 then
		v_err_code := v_err_code || 'VB07MLGCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_004', _lang_code)   || v_new_line;	
	end if;
	
	-- dr_amount cannot be less than zero
	if _dr_amount < 0 
	 then
		v_err_code := v_err_code || 'VB07MLGCUD_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_008', _lang_code)  || v_new_line;	
	end if;
	
	-- cr_amount cannot be less than zero
	if _cr_amount < 0 
	 then
		v_err_code := v_err_code || 'VB07MLGCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_005', _lang_code)  || v_new_line;
	end if;
	
	-- tran_narration cannot be blank
	if _tran_narration = '' then
		v_err_code := v_err_code || 'VB07MLGCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_002', _lang_code) || v_new_line;
	end if;
	
	/*	Vijayavel/12-03-2022 15.04
	-- tran_ref_no cannot be blank
	if _tran_ref_no = '' then
		v_err_code := v_err_code || 'VB07MLGCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_003', _lang_code) || v_new_line;
	end if;
	*/
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code)  || v_new_line;
	end if;
	
	-- Paymode code validation
	if (_paymode_code <> '') then
		if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = 'QCD_PAY_MODE'
					   and 		master_code = _paymode_code 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB07MLGCUD_007' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCUD_007', _lang_code)  || v_new_line;
		end if;
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code)  || v_new_line;	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tpgmemberledger
				  where 	pgmemberledger_gid = _pgmemberledger_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	pg_trn_tpgmemberledger
			set		status_code 	= 'I',
					updated_by 		= _user_code,
					updated_date 	= now()					
			where 	pg_id 			= _pg_id 
			and 	status_code 	= 'A';
			
			v_succ_code := 'SB07MLGCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
-- 		if not exists(select 	* 
-- 					  from		pg_trn_tpgmemberledger
-- 					  where		pgmemberledger_gid = _pgmemberledger_gid
-- 					  and 		status_code = 'A'
-- 					 ) then
			insert into pg_trn_tpgmemberledger 
			(
				pg_id,
				pgmember_id,
				acchead_code,
				tran_date,
				dr_amount,
				cr_amount,
				tran_narration,
				tran_ref_no,
				tran_remark,
				status_code,
				paymode_code,
				created_by,
				created_date				
			)
			values
			(
				_pg_id,
				_pgmember_id,
				_acchead_code,
				_tran_date,
				_dr_amount,
				_cr_amount,
				_tran_narration,
				_tran_ref_no,
				_tran_remark,
				_status_code,
				_paymode_code,
				_user_code,
				now()
				
			) returning pgmemberledger_gid into _pgmemberledger_gid;
			
			-- send sms payment to member
			SELECT 
				sms_template,dlt_template_id into v_sms_template,v_dlt_template_id
			FROM 	core_mst_tsmstemplate
			where 	smstemplate_code = v_smstemplate_code
			and 	lang_code = _lang_code
			and 	status_code = 'A';
			
			v_sms_template := coalesce(v_sms_template,'');
			v_dlt_template_id := coalesce(v_dlt_template_id,'');
			
			select fn_get_pgname(_pg_id) into v_pgname;
			select fn_get_pgmembername(_pg_id, _pgmember_id) into v_pgmembername;
			
			if (v_dlt_template_id <> '') then
				v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Member_Name#}',v_pgmembername);
				v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Paid_Amount#}',_cr_amount::udd_text);
				v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Payment_Date#}',_tran_date::udd_text);
				v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#PG_Name#}',v_pgname);
				v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#link#}','http://169.38.77.191:test');
				
				-- Store procedure Call
				v_mobile_no := fn_get_pgmembermobileno(_pg_id, _pgmember_id);
				
				call pr_iud_smstran(_pg_id,
									v_smstemplate_code,
									v_dlt_template_id,
									v_mobile_no,
									v_sms_template,
									_user_code,
									'udyog');
			end if;
			
			v_succ_code := 'SB07MLGCUD_001';
			
			
-- 		else
-- 			-- Record already exists
-- 			v_err_code := v_err_code || 'EB00CMNCMN_002';
-- 			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
-- 			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
-- 		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tpgmemberledger
				   where	pgmemberledger_gid 	= _pgmemberledger_gid 
				   and 		status_code = 'A'
				   ) then
			update	pg_trn_tpgmemberledger 
			set	    acchead_code 		= _acchead_code,
					tran_date 			= _tran_date,
					dr_amount 			= _dr_amount,
					cr_amount 			= _cr_amount,
					tran_narration 		= _tran_narration,
					tran_ref_no 		= _tran_ref_no,
					tran_remark 		= _tran_remark,
					status_code 		= _status_code,
					paymode_code 		= _paymode_code,
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	pgmemberledger_gid	= _pgmemberledger_gid
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB07MLGCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
			
	/*if exists (	select	count(*)
				from 	pg_trn_tpgmemberledger
			    where 	pg_id = _pg_id 
			   	and     pgmember_id = _pgmember_id
			    and 	status_code = 'A'
				group	by pg_id,pgmember_id
				having	count('*') > 1) 
	then
		-- pg id cannot be duplicated
		v_err_code := v_err_code || 'EB04PRGCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04PRGCUD_001', _lang_code),_pg_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;*/
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgmemberpayment(INOUT _pgmemberpymt_gid udd_int, _pg_id udd_code, _pgmember_id udd_code, _paid_date udd_date, _period_from udd_date, _period_to udd_date, _paymode_code udd_code, _paid_amount udd_amount, _pymt_ref_no udd_code, _pymt_remark udd_text, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 31-12-2021
		SP Code : B07MPYCDX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id				  
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)|| v_new_line;
	end if;
	
	-- pg member id Validation
	if not exists (select 	* 
				   from 	pg_mst_tpgmember 
				   where 	pg_id 		= _pg_id
				   and 		pgmember_id = _pgmember_id 				  
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_005', _lang_code)|| v_new_line;	
	end if;
	
	-- paid_date cannot be blank
	if _paid_date is Null then
		v_err_code := v_err_code || 'VB07MLGCDX_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCDX_001', _lang_code) || v_new_line;
	end if;
	
	-- paid_date cannot future
	if _paid_date > CAST(now() AS DATE) 
	 then
		v_err_code := v_err_code || 'VB07MLGCDX_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCDX_007', _lang_code) || v_new_line;	
	end if;
	
	-- period_from cannot be blank
	if _period_from is Null then
		v_err_code := v_err_code || 'VB07MLGCDX_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCDX_002', _lang_code) || v_new_line;
	end if;
	
	-- period_to cannot be blank
	if _period_to is Null then
		v_err_code := v_err_code || 'VB07MLGCDX_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCDX_003', _lang_code) || v_new_line;
	end if;
	
	-- period_from and period_to validation
	if _period_to < _period_from then
		v_err_code := v_err_code || 'VB07MLGCDX_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCDX_004', _lang_code) || v_new_line;	
	end if;
	
	-- paymode code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PAY_MODE'
				   and 		master_code = _paymode_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB07MLGCDX_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCDX_005', _lang_code) || v_new_line;
	end if;
	
	-- Paid amount validation
	if _paid_amount < 0 
	 then
		v_err_code := v_err_code || 'VB00CMNCMN_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_006', _lang_code) || v_new_line;	
	end if;
	
	-- pymt_ref_no cannot be blank
	if _pymt_ref_no = '' then
		v_err_code := v_err_code || 'VB07MLGCDX_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB07MLGCDX_006', _lang_code) || v_new_line;
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_trn_tpgmemberpayment
				  where 	pgmemberpymt_gid = _pgmemberpymt_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	pg_trn_tpgmemberpayment
			set		status_code 	= 'I',
					updated_by 		= _user_code,
					updated_date 	= now()					
			where 	pgmemberpymt_gid = _pgmemberpymt_gid 
			and 	status_code 	= 'A';
			
			v_succ_code := 'SB07MLGCDX_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_trn_tpgmemberpayment
					  where		pg_id 		= _pg_id
					  and		pgmember_id = _pgmember_id
					  and 		status_code = 'A'
					 ) then
			insert into pg_trn_tpgmemberpayment 
			(
				pg_id,
				pgmember_id,
				paid_date,
				period_from,
				period_to,
				paymode_code,
				paid_amount,
				pymt_ref_no,
				pymt_remark,
				status_code,
				created_by,
				created_date				
			)
			values
			(
				_pg_id,
				_pgmember_id,
				_paid_date,
				_period_from,
				_period_to,
				_paymode_code,
				_paid_amount,
				_pymt_ref_no,
				_pymt_remark,
				_status_code,
				_user_code,
				now()
				
			) returning pgmemberpymt_gid into _pgmemberpymt_gid;			
			v_succ_code := 'SB07MLGCDX_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;				
	end if;
			
	if exists (	select	count(*)
				from 	pg_trn_tpgmemberpayment
			    where 	pg_id = _pg_id 
			    and     pgmember_id = _pgmember_id
				group	by pg_id,pgmember_id
				having	count('*') > 1) 
	then
		-- pg id and  pg member id cannot be duplicated
		v_err_code := v_err_code || 'EB04PRGCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04PRGCUD_001', _lang_code),_pg_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgofficebearers(INOUT _pgoffbearer_gid udd_int, _pg_id udd_code, _offbearer_name udd_desc, _designation_code udd_code, _signatory_code udd_code, _mobile_no udd_mobile, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 17-12-2021
		SP Code : B04OFBCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	

	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code <> 'I'
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code) || v_new_line;	
	end if;
	
	-- office bearer name cannot be blank
	if _offbearer_name = '' then
		v_err_code := v_err_code || 'VB04OFBCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04OFBCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- designation code cannot be blank
	if _designation_code = '' then
		v_err_code := v_err_code || 'VB04OFBCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04OFBCUD_003', _lang_code) || v_new_line;
	end if;
	
-- 	-- signatory code cannot be blank
-- 	if _signatory_code = '' then
-- 		v_err_code := v_err_code || 'VB04OFBCUD_004' || ',';
-- 		v_err_msg  := v_err_msg ||  fn_get_msg('VB04OFBCUD_004', _lang_code) || v_new_line;
-- 	end if;
	
	-- mobile no cannot be blank
	if _mobile_no = '' then
		v_err_code := v_err_code || 'VB04OFBCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04OFBCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' )  then
		if exists(select 	* 
				  from 		pg_mst_tofficebearers
				  where 	pg_id = _pg_id
				  and 		pgoffbearer_gid = _pgoffbearer_gid
				 ) then
				 
			delete from	pg_mst_tofficebearers
			where 	pg_id = _pg_id
			and 	pgoffbearer_gid = _pgoffbearer_gid;
			
			v_succ_code := 'SB04OFBCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tofficebearers
					  where		pg_id = _pg_id 
					  and	    offbearer_name = _offbearer_name
					 ) then
			insert into pg_mst_tofficebearers 
			(
				pg_id,
				offbearer_name,
				designation_code,
				signatory_code,
				mobile_no,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_offbearer_name,
				_designation_code,
				_signatory_code,
				_mobile_no,
				_user_code,
				now()
			) returning pgoffbearer_gid into _pgoffbearer_gid;
			
			v_succ_code := 'SB04OFBCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tofficebearers
				   where 	pg_id = _pg_id
				   and 		pgoffbearer_gid = _pgoffbearer_gid
				   ) then
			update	pg_mst_tofficebearers 
			set 	offbearer_name = _offbearer_name,
					designation_code = _designation_code,
					signatory_code = _signatory_code,
					mobile_no = _mobile_no,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgoffbearer_gid = _pgoffbearer_gid;
			 
			v_succ_code := 'SB04OFBCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tofficebearers
			    where 	pg_id = _pg_id
			    and     offbearer_name  = _offbearer_name
				and     designation_code = _designation_code
				group	by offbearer_name,designation_code
				having	count('*') > 1) 
	then
		-- offbearer name cannot be duplicated
		v_err_code := v_err_code || 'EB04OFBCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04OFBCUD_001', _lang_code),_offbearer_name);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgpanchayatmapping(INOUT _pgpanchayatmapping_gid udd_int, _pg_id udd_code, _panchayat_id udd_int, _state_id udd_int, _district_id udd_int, _block_id udd_int, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 05-01-2022
		SP Code : B04PYMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);

begin
	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id
				   and      status_code <> 'I'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	-- State id validation
	if not exists (select  	  * 
				   from  	  state_master 
				   where      state_id = _state_id)then
				   
		v_err_code := v_err_code || 'VB04PYMCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PYMCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- District id validation
	if not exists (select  	  * 
				   from  	  district_master 
				   where      district_id = _district_id)then
				   
		v_err_code := v_err_code || 'VB04PYMCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PYMCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- panchayat id validation
	if not exists (select  	  * 
				   from  	  panchayat_master 
				   where      panchayat_id = _panchayat_id)then
				   
		v_err_code := v_err_code || 'VB04PYMCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PYMCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- block id validation
	if not exists (select  	  * 
				   from  	  block_master 
				   where      block_id = _block_id)then
				   
		v_err_code := v_err_code || 'VB04PYMCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PYMCUD_004', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
	    -- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
		if exists(select 	* 
				  from 		pg_mst_tpanchayatmapping
				  -- where 	pgpanchayatmapping_gid = _pgpanchayatmapping_gid
				  where 	pg_id = _pg_id
				  and 		panchayat_id = _panchayat_id
				 ) then
			Delete from pg_mst_tpanchayatmapping
		    -- where 		pgpanchayatmapping_gid = _pgpanchayatmapping_gid;
			where 	pg_id = _pg_id
			and 	panchayat_id = _panchayat_id;
			v_succ_code := 'SB00CMNCMN_003';
		-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-002
		if not exists(select 	* 
					  from		pg_mst_tpanchayatmapping
					  where		panchayat_id = _panchayat_id
					  and 		pg_id = _pg_id
					 ) then
		 -- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-002
			insert into pg_mst_tpanchayatmapping 
			(
				pg_id,
				panchayat_id,
				state_id,
				district_id,
				block_id,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_panchayat_id,
				_state_id,
				_district_id,
				_block_id,
				_user_code,
				now()
			) returning pgpanchayatmapping_gid into _pgpanchayatmapping_gid;
			
			v_succ_code := 'SB00CMNCMN_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-003
		if  exists(select 	*
				   from 	pg_mst_tpanchayatmapping
				   where	panchayat_id = _panchayat_id
				   and      pg_id 		= _pg_id
				   ) then
		-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-003
			update	pg_mst_tpanchayatmapping 
			set 	pg_id = _pg_id,
					panchayat_id = _panchayat_id,
					state_id = _state_id,
					district_id = _district_id,
					block_id = _block_id,
					updated_by = _user_code,
					updated_date = now()
			-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-004
			where 	panchayat_id = _panchayat_id
			and 	pg_id = _pg_id;
			-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-004
			
			v_succ_code := 'SB00CMNCMN_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tpanchayatmapping
			    where 	pg_id = _pg_id
			    and 	panchayat_id = _panchayat_id
				group	by pg_id,panchayat_id
				having	count('*') > 1) 
	then
		-- panchayat cannot be duplicated
		v_err_code := v_err_code || 'EB04PYMCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04PYMCUD_001', _lang_code),_panchayat_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgproducergroup(INOUT _pg_gid udd_int, INOUT _pg_id udd_code, _pg_name udd_desc, _pg_ll_name udd_desc, _pg_type_code udd_code, _formation_date udd_date, _promoter_code udd_code, _state_id udd_int, _district_id udd_int, _block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _cbo_id udd_code, _cbo_name udd_desc, _clf_id udd_code, _clf_name udd_desc, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, _row_timestamp udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan
		Created Date : 17-12-2021
		SP Code : B04PRGCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_seqno udd_int := 0;
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	/*if _pg_id <> '0' then
		v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));

		if (v_boolvalidation = false) then 
			v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
		end if;
	end if;*/
	

	-- validation
	-- pg name cannot be blank
	if _pg_name = '' then
		v_err_code := v_err_code || 'VB04PRGCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRGCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- pg type code Validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PG_TYPE'
				   and 		master_code = _pg_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04PRGCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRGCUD_003', _lang_code);	
	end if;
	
	-- formation date cannot be blank
	if _formation_date is Null then
		v_err_code := v_err_code || 'VB04PRGCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRGCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- promoter code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PROMOTER'
				   and 		master_code = _promoter_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04PRGCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRGCUD_005', _lang_code);	
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code);	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	-- timestamp check for concurrency
	select 	to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') into v_timestamp 
	from 	pg_mst_tproducergroup
	where	pg_gid = _pg_gid;
	
	v_timestamp	:= coalesce(v_timestamp, '');
	
	IF (v_timestamp != _row_timestamp) 
	then
		-- Record modified since last fetch so Kindly refetch and continue
		v_err_code := v_err_code || 'VB00CMNCMN_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_002', _lang_code) || v_new_line;	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		pg_mst_tproducergroup
				  where 	pg_gid = _pg_gid 
				  and 		status_code <> 'I'
				 ) then
			Update 	pg_mst_tproducergroup
			set		status_code = 'I',
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	pg_gid = _pg_gid 
			and 	status_code <> 'I';
			
			v_succ_code := 'SB04PRGCUD_003';

		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tproducergroup
					  where		pg_gid = _pg_gid 
					  and 		status_code = 'A'
					 ) then
					 
		--Pg id generation
		 select fn_get_docseqno('PGID') into v_seqno ;
-- 		 select CONCAT(upper(substring 
-- 							 (regexp_replace(_pg_name collate pg_catalog.""default"", '[^a-zA-Z]', '', 'g')
-- 							  ,1,2)),
			select case 
						when length(v_seqno::udd_text)>5 then v_seqno::udd_text 
				   else 
					   to_char(v_seqno,'fm0000000') end into _pg_id ;
	        
			insert into pg_mst_tproducergroup 
			(
				pg_id,
				pg_name,
				pg_ll_name,
				pg_type_code,
				formation_date,
				promoter_code,
				state_id,
				district_id,
				block_id,
				panchayat_id,
				village_id,
				cbo_id,
				cbo_name,
				clf_id,
				clf_name,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				_pg_id,
				_pg_name,
				_pg_ll_name,
				_pg_type_code,
				_formation_date,
				_promoter_code,
				_state_id,
				_district_id,
				_block_id,
				_panchayat_id,
				_village_id,
				_cbo_id,
				_cbo_name,
				_clf_id,
				_clf_name,
				'D',
				_user_code,
				now(),
				now()
			) returning pg_gid into _pg_gid;
			-- sequence no table insert 
			insert into pg_mst_tpgmembersequence
			(
				pg_id,
			 	next_seq_no,
				sync_status_code,
				status_code,
				created_date,
			 	created_by
			)
			values
			(
				_pg_id,
			 	1,
				'N',
				'A',
				now(),
				_user_code
			);
			
			v_succ_code := 'SB04PRGCUD_001';
			
			/*Update 	pg_mst_tproducergroup
			set		pg_id = _pg_gid
			where 	pg_gid = _pg_gid
			and 	status_code = 'A';*/
			
			--pgid values setting area
			select	 pg_id into _pg_id 
			from 	 pg_mst_tproducergroup
			where 	 pg_gid = _pg_gid
			and 	 status_code <> 'I';
			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if exists (	select	count(*)
						from 	pg_mst_tproducergroup
						where 	pg_name = _pg_name
						and 	panchayat_id = _panchayat_id
						and     status_code <> 'I'
						group	by pg_name,panchayat_id
						having	count('*') > 1)
			then
				v_err_code := v_err_code || 'VB00CMNCMN_009' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_009', _lang_code) || v_new_line || _pg_name;	
			raise exception '%',v_err_code || '-' || v_err_msg;
		 end if;
		 
		if  exists(select 	*
				   from 	pg_mst_tproducergroup
				   where	pg_gid = _pg_gid 
				   and 		status_code <> 'I'
				   ) then
				update	pg_mst_tproducergroup 
				set 	pg_name = _pg_name,
						pg_ll_name = _pg_ll_name,
						pg_type_code = _pg_type_code,
						formation_date = _formation_date,
						promoter_code = _promoter_code,
						state_id = _state_id,
						district_id = _district_id,
						block_id = _block_id,
						panchayat_id = _panchayat_id,
						village_id = _village_id,
						cbo_id = _cbo_id,
						cbo_name = _cbo_name,
						clf_id = _clf_id,
						clf_name = _clf_name,
					 -- status_code = _status_code,
						updated_by = _user_code,
						updated_date = now(),
						row_timestamp = now()
				where 	pg_gid = _pg_gid
				and 	status_code <> 'I';

				v_succ_code := 'SB04PRGCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	  end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tproducergroup
			    where 	pg_name = _pg_name 
			    and 	panchayat_id = _panchayat_id	
				group	by pg_name,panchayat_id
				having	count('*') > 1) 
	then
		-- pg id cannot be duplicated
		v_err_code := v_err_code || 'EB04PRGCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04PRGCUD_001', _lang_code),_pg_name);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgproductmapping(INOUT _pgprodmapp_gid udd_int, _pg_id udd_code, _prod_code udd_code, _frequent_flag udd_flag, _stock_reset_flag udd_flag, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 17-12-2021
		
		Updated By : Mangai
		Updated Date : 24-01-2023
		
		SP Code : B04PRMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_max_prod_value udd_int := 0;
	v_boolvalidation udd_boolean := false;

	v_prod_type_code udd_code := ''; 
begin
	--Block level validation
	/*v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;*/
	
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
	if _mode_flag <> 'D' then
		-- Get prod_type_code
		select 	prod_type_code into v_prod_type_code
		from 	core_mst_tproduct
		where 	prod_code = _prod_code
		and 	status_code = 'A';
		
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001
	
	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id	
				   and 		status_code <> 'I'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	-- product code cannot be blank
	if _prod_code = '' then
		v_err_code := v_err_code || 'VB04PRMCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRMCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- Non perishable product validation
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-002
	if v_prod_type_code = 'N' and   _stock_reset_flag = 'N'  then 
			v_err_code := v_err_code || 'VB04PRMCUD_006' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRMCUD_006', _lang_code)  || v_new_line;
	end if;
	
	if v_prod_type_code = 'N' and _stock_reset_flag = 'Y' then
			_stock_reset_flag := 'N';
	elseif v_prod_type_code = 'P' then
			select case 
					 when _stock_reset_flag = 'Y' then
							'N'
					 when _stock_reset_flag = 'N' then
							'Y'
					 end into _stock_reset_flag;
										
	end if;
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-002
	
	-- frequent flag cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _frequent_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04PRMCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRMCUD_003', _lang_code) || v_new_line;	
	end if;

	-- getting product count
	select 	config_value into v_max_prod_value 
	from 	core_mst_tconfig
	where 	config_name = 'max_prod_count'
	and   	status_code = 'A';
	
	if _mode_flag = 'I' then
		if exists (select 	count(*) 
				   from 	pg_mst_tproductmapping 
				   where 	pg_id = _pg_id
				   group by pg_id
				   having   count(*) >= v_max_prod_value)
		then
			v_err_code := v_err_code || 'VB04PRMCUD_004' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRMCUD_004', _lang_code) || v_new_line;	
		end if;
	end if;
	
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-003
	-- stock reset flag cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _stock_reset_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04PRMCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04PRMCUD_005', _lang_code) || v_new_line;	
	end if;
	-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-003
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	end if;
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if (_mode_flag  = 'D' ) then
		if exists(select 	* 
				  from 		pg_mst_tproductmapping
				  where 	pg_id = _pg_id
				  and 		pgprodmapp_gid = _pgprodmapp_gid
				 ) then
				 
			delete from	pg_mst_tproductmapping
			where 	pg_id = _pg_id
			and 	pgprodmapp_gid = _pgprodmapp_gid;
			
			v_succ_code := 'SB04PRMCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		pg_mst_tproductmapping
					  where		pg_id = _pg_id
					  and	    prod_code = _prod_code
					 ) then
			insert into pg_mst_tproductmapping 
			(
				pg_id,
				prod_code,
				frequent_flag,
				-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-004
				stock_reset_flag,
				-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-004
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_prod_code,
				_frequent_flag,
				-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-005
				_stock_reset_flag,
				-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-005
				_user_code,
				now()
			) returning pgprodmapp_gid into _pgprodmapp_gid;
			
			v_succ_code := 'SB04PRMCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tproductmapping
				   where 	pg_id = _pg_id
				   and 		pgprodmapp_gid = _pgprodmapp_gid
				   ) then
			update	pg_mst_tproductmapping 
			set 	prod_code = _prod_code,
					frequent_flag = _frequent_flag,
					-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-006
					-- stock_reset_flag = _stock_reset_flag,
					-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-006
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgprodmapp_gid = _pgprodmapp_gid;
			 
			v_succ_code := 'SB04PRMCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tproductmapping
			    where 	pg_id = _pg_id
			    and     prod_code = _prod_code
				group	by prod_code
				having	count('*') > 1) 
	then
		-- prod code cannot be duplicated
		v_err_code := v_err_code || 'EB04PRMCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04PRMCUD_001', _lang_code),_prod_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgudyogmitra(INOUT _pgudyogmitra_gid udd_int, _pg_id udd_code, _udyogmitra_id udd_code, _udyogmitra_name udd_desc, _mobile_no udd_mobile, _token_no udd_code, _tran_status_code udd_code, _pgmember_type_code udd_code, _fatherhusband_name udd_desc, _password udd_desc, _village_id udd_int, _shgmember_relation_code udd_code, _shgmember_id udd_code, _shgmember_name udd_desc, _shgmember_mobile_no udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 17-12-2021
		SP Code : B04UDMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_pgmem_count udd_int := 0;
	v_pgmember_min_count udd_int := 0;
	v_mobile_no udd_mobile := 0;
	v_count_pgid udd_int := 0;
	v_statuscode udd_code := '';
	
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_UM_CREDENT';
	v_smstemplate_code1 udd_code := 'SMST_UM_APPLINK';
	v_role_code udd_code := 'udyogmitra';
	v_boolvalidation udd_boolean := false;

begin
	--Block level validation
	v_boolvalidation := (select fn_get_blockvalidation(_pg_id,_user_code));
	
	if (v_boolvalidation = false) then 
		v_err_code := v_err_code || 'VB00CMNCMN_022' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_022', _lang_code) || v_new_line;
	end if;
	
	_udyogmitra_id := _mobile_no;
	
	-- validation
	-- set default password
	_password := coalesce(_password,'');
	if _password  = ''  then 
		_password := '12345678';
	end if;
	
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id				  
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	-- udyogmitra id cannot be blank
	if _pgmember_type_code = 'SHG' then
		if _udyogmitra_id = '' then
			v_err_code := v_err_code || 'VB04UDMCUD_002' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_002', _lang_code) || v_new_line;
		end if;
	end if;
	
	-- udyogmitra name cannot be blank
	if _udyogmitra_name = '' then
		v_err_code := v_err_code || 'VB04UDMCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- mobile no cannot be blank
	if _pgmember_type_code = 'SHG' then
		if _mobile_no = '' or _mobile_no = '0' then
			v_err_code := v_err_code || 'VB04UDMCUD_004' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_004', _lang_code) || v_new_line;
		end if;
	end if;
	
	-- tran status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_TRAN_STATUS'
				   and 		master_code = _tran_status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04UDMCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_005', _lang_code) || v_new_line;
	end if;
	
	-- pgmember type code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PGMEMBER_TYPE'
				   and 		master_code = _pgmember_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04UDMCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_007', _lang_code) || v_new_line;	
	end if;
	
	-- Nonshg Mandatore fields
	if _pgmember_type_code = 'NONSHG' then
		if _shgmember_relation_code = '' then
			v_err_code := v_err_code || 'VB04UDMCUD_008' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_008', _lang_code) || v_new_line;
		end if;
		
		if _shgmember_id = '' then
			v_err_code := v_err_code || 'VB04UDMCUD_009' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_009', _lang_code) || v_new_line;
		end if;
		
		if _shgmember_name = '' then
			v_err_code := v_err_code || 'VB04UDMCUD_010' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_010', _lang_code) || v_new_line;
		end if;
		/*
		if _shgmember_mobile_no = '' then
			v_err_code := v_err_code || 'VB04UDMCUD_011' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_011', _lang_code) || v_new_line;
		end if;*/
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	--pgmember count
	select count(*) into v_pgmem_count 
	from pg_mst_tpgmember where pg_id = _pg_id
	and status_code = 'A';
	
	--pgmember mincount values
	select 	config_value into v_pgmember_min_count
	from 	core_mst_tconfig 
	where 	config_name = 'pgmember_min_count'
	and 	status_code = 'A';
	
	if (_mode_flag  = 'D' ) then
		if exists(select 	* 
				  from 		pg_mst_tudyogmitra
				  where 	pg_id = _pg_id
				  and 		pgudyogmitra_gid = _pgudyogmitra_gid
				  and 		tran_status_code <> 'I'
				 ) then
			Update 	pg_mst_tudyogmitra
			set		tran_status_code = 'I',
					updated_by = _user_code,
					updated_date = now()
			where 	pg_id = _pg_id
			and 	pgudyogmitra_gid = _pgudyogmitra_gid
			and 	tran_status_code <> 'I';
			
			v_succ_code := 'SB04UDMCUD_003';
			
			select count(pg_id) into v_count_pgid
			from   pg_mst_tudyogmitra 
			where  pg_id = _pg_id
			and    tran_status_code in ('A','P');
			
			select status_code into v_statuscode
			from   pg_mst_tproducergroup
			where  pg_id       = _pg_id ;
-- 			and    status_code = 'A';
			
			if v_statuscode = 'M'  and v_count_pgid < 1 then
						update pg_mst_tproducergroup
						set    status_code = 'D'
						where  pg_id       = _pg_id;
-- 						and    status_code <> 'I';
			end if;
			/*						
			if v_statuscode = 'A' then
					update pg_mst_tproducergroup
					set    status_code = 'A'
					where  pg_id = _pg_id;
			end if;		
			*/
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elsif ( _mode_flag = 'I' ) then
	-- more than one record active validation 
	if exists (	select	count(*)
					from 	pg_mst_tudyogmitra
					where 	pg_id     = _pg_id
-- 			   		and     mobile_no = _mobile_no
					and     tran_status_code in ('A','P')
			   		group	by pg_id
					having	count('*') >= 1)
		then
			v_err_code := v_err_code || 'VB04UDMCUD_006' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04UDMCUD_006', _lang_code) || v_new_line;	
		raise exception '%',v_err_code || '-' || v_err_msg;
		
	else
	if not exists(select 	* 
					  from		pg_mst_tudyogmitra
					  where		pg_id = _pg_id 
					  and	    pgudyogmitra_gid = _pgudyogmitra_gid
					  and 		tran_status_code <> 'I'
					 ) then
			insert into pg_mst_tudyogmitra 
			(
				pg_id,
				udyogmitra_id,
				udyogmitra_name,
				mobile_no,
				token_no,
				tran_status_code,
				pgmember_type_code,
				fatherhusband_name,
				village_id,
				shgmember_relation_code,
				shgmember_id,
				shgmember_name,
				shgmember_mobile_no,
				created_by,
				created_date
			)
			values
			(
				_pg_id,
				_udyogmitra_id,
				_udyogmitra_name,
				_mobile_no,
				_token_no,
				_tran_status_code,
				_pgmember_type_code,
				_fatherhusband_name,
				_village_id,
				_shgmember_relation_code,
				_shgmember_id,
				_shgmember_name,
				_shgmember_mobile_no,
				_user_code,
				now()
			) returning pgudyogmitra_gid into _pgudyogmitra_gid;
			
			if _mobile_no <> '0' then
				-- send sms credentials
				CALL pr_sms_udyogmitra(
										_pg_id, 
										_user_code, 
										v_role_code, 
										_udyogmitra_id,
										_password,
										_mobile_no, 
										_lang_code,
										_succ_msg
									   );
			end if;
		
 			if exists (select count(*) from pg_mst_tudyogmitra
 					   where mobile_no = _mobile_no
					   and tran_status_code in ('A','P')
 					   group by mobile_no
					   having count(*) > 1) 
 			then
 					CALL pr_sms_udyogmitramapping(
													_pg_id, 
													_user_code, 
													v_role_code, 
													_udyogmitra_name,
													_mobile_no, 
													_lang_code,
													_succ_msg
												   );
			end if;
	
			v_succ_code := 'SB04UDMCUD_001';
			
			/*
			if _pgmember_type_code = 'NONSHG' then
			   _udyogmitra_id := 'N' || _pgudyogmitra_gid; 
				
				update  pg_mst_tudyogmitra 
				set 	udyogmitra_id = _udyogmitra_id
				where 	pgudyogmitra_gid = _pgudyogmitra_gid;
				
			end if;
			*/
			
			if(v_pgmem_count < v_pgmember_min_count)then
				if (_mobile_no <> '0') then
					--pg member less than 10  update Status code ""A"" in pg table
						update pg_mst_tproducergroup 
						set status_code = 'M',
							updated_date = now(),
							updated_by = _user_code,
							row_timestamp = now()
						where pg_id = _pg_id
						and status_code not in ('A','I');
				end if;
			end if;
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
		
	elsif (_mode_flag = 'U' ) then 
		if  exists(select 	*
				   from 	pg_mst_tudyogmitra
				   where 	pg_id = _pg_id
				   and 		pgudyogmitra_gid = _pgudyogmitra_gid
				   and 		tran_status_code <> 'I'
				   ) then
			-- Get existing mobile number
			 select mobile_no into v_mobile_no 
			 from 	pg_mst_tudyogmitra 
			 where 	pg_id = _pg_id
		     and 	pgudyogmitra_gid = _pgudyogmitra_gid
	      	 and 	tran_status_code <> 'I';
			 
			update	pg_mst_tudyogmitra 
			set 	udyogmitra_id = _udyogmitra_id,
					udyogmitra_name = _udyogmitra_name,
					mobile_no = _mobile_no,
					token_no = _token_no,
					tran_status_code = _tran_status_code,
					pgmember_type_code = _pgmember_type_code,
					fatherhusband_name = _fatherhusband_name,
					village_id = _village_id,
					shgmember_relation_code = _shgmember_relation_code,
					shgmember_id = _shgmember_id,
					shgmember_name = _shgmember_name,
					shgmember_mobile_no = _shgmember_mobile_no,
					updated_by = _user_code,
					updated_date = now()
			 where 	pg_id = _pg_id
		     and 	pgudyogmitra_gid = _pgudyogmitra_gid
	      	 and 	tran_status_code <> 'I';
			 
			if v_mobile_no <> _mobile_no and length(_mobile_no) = 10 then
				-- send sms credentials
				CALL pr_sms_udyogmitra(
										_pg_id, 
										_user_code, 
										v_role_code, 
										_udyogmitra_id,
										_password,
										_mobile_no, 
										_lang_code,
										_succ_msg
									   );
			end if;
			 
			v_succ_code := 'SB04UDMCUD_002';
			
			if(v_pgmem_count < v_pgmember_min_count)then
			  if (_mobile_no <> '0') then
				--pg member less than 10 update Status code ""A"" in pg table
					update pg_mst_tproducergroup 
					set status_code = 'M',
						updated_date = now(),
						updated_by = _user_code,
						row_timestamp = now()
					where pg_id = _pg_id
					and status_code not in ('A','I');
				end if;
			end if;
		
			
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	pg_mst_tudyogmitra
			    where 	pg_id = _pg_id
			    and     udyogmitra_id = _udyogmitra_id
			   	and 	tran_status_code = 'A'
				group	by udyogmitra_id
				having	count('*') > 1) 
	then
		-- udyogmitra id cannot be duplicated
		v_err_code := v_err_code || 'EB04UDMCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB04UDMCUD_001', _lang_code),_udyogmitra_id);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_pgvillagemapping(INOUT _pgvillage_gid udd_int, _pg_id udd_code, _state_id udd_int, _district_id udd_int, _block_id udd_int, _panchayat_id udd_int, _village_id udd_text, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 21-01-2023
		SP Code : B04VGMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line udd_text = chr(13)||chr(10);
	
	v_colrec record;
	v_village_id udd_int := 0;
	v_delete_flag udd_flag := 'Y';
	v_pgpanchayatmapping_gid udd_int := 0;
begin
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
	-- validation
	-- pg Id validation
	if not exists (select 	* 
				   from 	pg_mst_tproducergroup 
				   where 	pg_id = _pg_id
				   and      status_code <> 'I'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_004', _lang_code)  || v_new_line;	
	end if;
	
	if _mode_flag = 'D' then
		delete from pg_mst_tpanchayatmapping
	    where  pg_id = _pg_id
	    and    panchayat_id = _panchayat_id;
							   
		delete from pg_mst_tvillagemapping 
		where pg_id = _pg_id
		and   panchayat_id = _panchayat_id;
		
		v_succ_code := 'SB00CMNCMN_003';
	end if;
	
	if _mode_flag = 'I' then 
			if exists ( select * from pg_mst_tpanchayatmapping
						where pg_id = _pg_id 
						and panchayat_id = _panchayat_id ) then
			-- Duplicate validation
			v_err_code := v_err_code || 'VB04PYMCUD_006' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB04PYMCUD_006', _lang_code) || v_new_line;	
			end if;
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
	if _mode_flag in ('I','U') then
		if _village_id <> '' then
		-- Drop Temp Table
		DROP TABLE if exists temp_village_id;
		-- Create Temp Table
		CREATE temporary TABLE temp_village_id AS
		select regexp_split_to_table(_village_id collate pg_catalog.""default"", E',') as village_id;
		-- For Loop Against Village id
		FOR v_colrec IN select * from temp_village_id
				LOOP
				-- village id validation
				if not exists (select  	  * 
							   from  	  village_master  
							   where      village_id = v_colrec.village_id::udd_int
							   and 		  is_active = true)then

					v_err_code := v_err_code || 'VB00CMNCMN_026' || ',';
					v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_026', _lang_code) || v_new_line;
					RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
				end if;		
			
				select state_id,district_id,block_id,panchayat_id
				into   _state_id,_district_id,_block_id,_panchayat_id
				from   village_master 
				where  village_id = v_colrec.village_id::udd_int;
				
				-- panchayat mapping insert
				if not exists (select * from pg_mst_tpanchayatmapping
							   where  pg_id = _pg_id
							   and 	  panchayat_id = _panchayat_id) then
					call public.pr_iud_pgpanchayatmapping(v_pgpanchayatmapping_gid, _pg_id, _panchayat_id,
														  _state_id, _district_id, _block_id, _lang_code,
														  _user_code, 'I', _succ_msg);
				end if;
				
				if v_delete_flag = 'Y' then
					delete from pg_mst_tvillagemapping 
					where pg_id = _pg_id
					and   panchayat_id = _panchayat_id;

					v_delete_flag = 'N';

				end if;

				insert into pg_mst_tvillagemapping (
															pg_id ,
															state_id,
															district_id,
															block_id ,
															panchayat_id,
															village_id,
															created_date ,
															created_by 
														)
											values		(
															_pg_id ,
															_state_id ,
															_district_id ,
															_block_id ,
															_panchayat_id ,
															v_colrec.village_id::udd_int ,
															now(),
															_user_code
														);
			end loop;
			
			if _mode_flag = 'I' then
				v_succ_code := 'SB00CMNCMN_001';
			else
				v_succ_code := 'SB00CMNCMN_002';
			end if;

		else 
				v_err_code := v_err_code || 'VB00CMNCMN_025' || ',';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_025', _lang_code) || v_new_line;
				RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if v_succ_code <> '' then
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001
end

$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procure(INOUT _proc_gid udd_int, _pg_id udd_code, _session_id udd_code, _pgmember_id udd_code, _proc_date udd_date, _advance_amount udd_amount, _sync_status_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 07-02-2022
		SP Code      : B06PRCCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id       = _pg_id 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- Session ID Validation
	if not exists (select * from pg_trn_tsession
				   where session_id       = _session_id
				   and   status_code      = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_012' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_012', _lang_code) || v_new_line;
	end if;	
	
-- PG Member ID Validation
	if not exists (select * from pg_mst_tpgmember
				   where pgmember_id      = _pgmember_id
				   and   status_code      = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_005' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_005', _lang_code) || v_new_line;
	end if;	
	
-- Procurement Date Validation
	if _proc_date isnull
	then
		v_err_code := v_err_code || 'VB06PRCCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06PRCCUD_001', _lang_code) || v_new_line;
	end if;	
	
-- Sync Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_SYNC_STATUS' 
				   and   master_code = _sync_status_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_013', _lang_code) || v_new_line;		
	end if;
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_STATUS' 
				   and   master_code = _status_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;

-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;

	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tprocure
				  where proc_gid = _proc_gid
				  and   status_code <> 'I')
			then
			update pg_trn_tprocure 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where proc_gid 	    = _proc_gid
				and	  pg_id		    = _pg_id
				and   status_code	<> 'I';
			v_succ_code := 'SB06PRCCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;

	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tprocure
				       where  proc_gid	= _proc_gid
				       and    pg_id 	= _pg_id)
		 then
			insert into pg_trn_tprocure(
				pg_id,
				session_id,
				pgmember_id,
				proc_date,
				advance_amount,
				sync_status_code,
				status_code,
				created_date,
				created_by)
			values(
				_pg_id,
				_session_id,
				_pgmember_id,
				_proc_date,
				_advance_amount,
				_sync_status_code,
				_status_code,
				now(),
				_user_code) returning proc_gid into _proc_gid;
				v_succ_code := 'SB06PRCCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if; 

	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tprocure
				   where proc_gid     = _proc_gid
				   and   status_code  <> 'I' )
		then
		update pg_trn_tprocure
		set		pg_id				   = _pg_id,
				session_id			   = _session_id,
				pgmember_id			   = _pgmember_id,
				proc_date			   = _proc_date,
				advance_amount 		   = _advance_amount,
				sync_status_code	   = _sync_status_code,
				status_code			   = _status_code,
				updated_date		   = now(),
				updated_by			   = _user_code
		where 	proc_gid               = _proc_gid
		and 	status_code            <> 'I';
		v_succ_code	:= 'SB06PRCCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
		 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tprocure
			    where 	pg_id         = _pg_id 
			    and 	session_id    = _session_id
			    and 	pgmember_id   = _pgmember_id
			    group	by pg_id, session_id, pgmember_id
				having	count('*') > 1) 
	then
		-- pg id session_id and pgmember_id cannot be duplicated
		v_err_code := v_err_code || 'EB06PRCCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06PRCCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procurecost(INOUT _proccost_gid udd_int, _pg_id udd_code, _proc_date udd_date, _tran_datetime udd_datetime, _package_cost udd_amount, _loading_unloading_cost udd_amount, _transport_cost udd_amount, _other_cost udd_amount, _proccost_remark udd_text, _sync_status_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By : Mangai
		Created Date : 04-02-2022
		
		Updated By : Vijayavel J
		Updated Date : 12-04-2022
		
		SP Code : B06PCOCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	
	v_package_cost 				udd_amount := 0;
	v_loading_unloading_cost 	udd_amount := 0;
	v_transport_cost 			udd_amount := 0;
	v_other_cost 				udd_amount := 0;	
	v_tran_datetime udd_text := '';
begin
v_tran_datetime := to_char(_tran_datetime,'YYYY-MM-DD HH24:MI:SS');

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
                   where pg_id     = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	

-- Procure Date Validation
	if _proc_date isnull
	then
		v_err_code := v_err_code || 'VB06PCOCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06PCOCUD_001', _lang_code) || v_new_line;
	end if;
	
-- Transaction DateTime Validation
	if _tran_datetime isnull
	then
		v_err_code := v_err_code || 'VB06PCOCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06PCOCUD_002', _lang_code) || v_new_line;
	end if;
	
---- Sync Status Code Validation
	/*
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_SYNC_STATUS' 
				   and   master_code = _sync_status_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_013', _lang_code) || v_new_line;		
	end if;
	*/
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_STATUS' 
				   and   master_code = _status_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if _mode_flag = 'U' then
		if exists (select * from pg_trn_tprocurecost
				   where pg_id	       = _pg_id
				   and   to_char(tran_datetime,'YYYY-MM-DD HH24:MI:SS') = v_tran_datetime
				   and   status_code   <> 'I' ) then
				   
			select 
					package_cost,
					loading_unloading_cost,
					transport_cost,
					other_cost
			into
					v_package_cost,
					v_loading_unloading_cost,
					v_transport_cost,
					v_other_cost
			from 	pg_trn_tprocurecost
			where 	pg_id	     	= _pg_id
			and   	to_char(tran_datetime,'YYYY-MM-DD HH24:MI:SS') 	= v_tran_datetime
			and   	status_code   	<> 'I';
			if (v_package_cost+v_loading_unloading_cost+v_transport_cost+v_other_cost) <> 
			   (_package_cost+_loading_unloading_cost+_transport_cost+_other_cost) then
			   _package_cost 			:= _package_cost - v_package_cost;
			   _loading_unloading_cost 	:= _loading_unloading_cost - v_loading_unloading_cost;
			   _transport_cost			:= _transport_cost - v_transport_cost;
			   _other_cost 				:= _other_cost - v_other_cost;
			   
			   _tran_datetime := now()::udd_datetime;
			   _mode_flag := 'I';
			end if;
		end if;
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;

	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tprocurecost
				  where pg_id	      = _pg_id
				  and   to_char(tran_datetime,'YYYY-MM-DD HH24:MI:SS') = v_tran_datetime
				  and   status_code   <> 'I')
			then
			update pg_trn_tprocurecost 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where proccost_gid 	= _proccost_gid
					and	pg_id		= _pg_id
					and status_code	<> 'I';
			v_succ_code := 'SB06PCOCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'I' then
		/*if not exists (select * from pg_trn_tprocurecost
				       where  pg_id	        = _pg_id
				       and    to_char(tran_datetime,'YYYY-MM-DD HH24:MI:SS') = v_tran_datetime)
		 then*/
			insert into pg_trn_tprocurecost(
				proccost_gid,
				pg_id,
				proc_date,
				tran_datetime,
				package_cost,
				loading_unloading_cost,
				transport_cost,
				other_cost,
				proccost_remark,
				sync_status_code,
				status_code,
				created_date,
				created_by)
			values(
				_proccost_gid,
				_pg_id,
				_proc_date,
				_tran_datetime,
				_package_cost,
				_loading_unloading_cost,
				_transport_cost,
				_other_cost,
				_proccost_remark,
				_sync_status_code,
				_status_code,
				now(),
				_user_code) returning proccost_gid into _proccost_gid;
				v_succ_code := 'SB06PCOCUD_001';
			  
		/*else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;*/
		--end if; 
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tprocurecost
				   where pg_id	       = _pg_id
				   and   to_char(tran_datetime,'YYYY-MM-DD HH24:MI:SS') = v_tran_datetime
				   and   status_code   <> 'I' )
		then
		update pg_trn_tprocurecost
		set		
-- 				pg_id				   =	_pg_id,
-- 	            proc_date			   =	_proc_date,
-- 				tran_datetime		   =	_tran_datetime,
-- 				package_cost		   =	_package_cost,
-- 				loading_unloading_cost =	_loading_unloading_cost,
-- 				transport_cost		   =	_transport_cost,
-- 				other_cost			   =	_other_cost,
				proccost_remark		   =	_proccost_remark,
-- 				sync_status_code	   =	_sync_status_code,
-- 				status_code			   =	_status_code,
				updated_date		   =	now(),
				updated_by			   = 	_user_code
		where   pg_id	               =    _pg_id
	    and     to_char(tran_datetime,'YYYY-MM-DD HH24:MI:SS')          =    v_tran_datetime
		and	    status_code			   <>	'I';
		 v_succ_code	:= 'SB06PCOCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
		 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tprocurecost
			    where 	pg_id         = _pg_id 
			    and 	tran_datetime = _tran_datetime
			--	and 	status_code   != 'I' 
			    group	by pg_id, tran_datetime
				having	count('*') > 1) 
	then
		-- pg id and tran_datetime cannot be duplicated
		v_err_code := v_err_code || 'EB06PCOCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06PCOCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procurecostjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 26-02-2022
		SP Code : B01PRCCUX
	*/
	
	v_colrec record;
	v_updated_date udd_datetime;

begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
													(
														proccost_gid udd_int,
														pg_id udd_code,
														proc_date udd_date,
														tran_datetime udd_datetime,
														package_cost udd_numeric,
														loading_unloading_cost udd_numeric,
														transport_cost udd_numeric,
														other_cost udd_numeric,
														proccost_remark udd_text,
														sync_status_code udd_code,
														status_code udd_code,
														created_date udd_date,
														created_by udd_code,
														updated_date udd_text,
														updated_by udd_code
														) 
												
			LOOP 
			
				select	 fn_text_todatetime(v_colrec.updated_date) 
			    into 	 v_updated_date;
				
			insert into pg_trn_tprocurecost (
														proccost_gid ,
														pg_id ,
														proc_date ,
														tran_datetime ,
														package_cost ,
														loading_unloading_cost ,
														transport_cost ,
														other_cost ,
														proccost_remark ,
														sync_status_code ,
														status_code ,
														created_date ,
														created_by,
														updated_date,
														updated_by
													)
										values		(
														v_colrec.proccost_gid ,
														v_colrec.pg_id ,
														v_colrec.proc_date ,
														v_colrec.tran_datetime ,
														v_colrec.package_cost ,
														v_colrec.loading_unloading_cost ,
														v_colrec.transport_cost ,
														v_colrec.other_cost ,
														v_colrec.proccost_remark ,
														v_colrec.sync_status_code ,
														v_colrec.status_code, 
														v_colrec.created_date, 
														v_colrec.created_by, 
														v_updated_date, 
														v_colrec.updated_by 
													)
						on CONFLICT ( pg_id,
									  tran_datetime)  
									 do update set  proccost_gid = v_colrec.proccost_gid,
													pg_id = v_colrec.pg_id,
													proc_date = v_colrec.proc_date,
													tran_datetime = v_colrec.tran_datetime,
													package_cost = v_colrec.package_cost,
													loading_unloading_cost = v_colrec.loading_unloading_cost,
													transport_cost = v_colrec.transport_cost,
													other_cost = v_colrec.other_cost,
													proccost_remark = v_colrec.proccost_remark,
													sync_status_code = v_colrec.sync_status_code,
													status_code = v_colrec.status_code,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;

			END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procurecostproduct(INOUT _proccostprod_gid udd_int, _pg_id udd_code, _tran_datetime udd_datetime, _prod_type_code udd_code, _prod_code udd_code, _grade_code udd_code, _uom_code udd_code, _prod_qty udd_qty, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By : Mangai
		Created Date : 04-02-2022
		SP Code : B06PCPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id       = _pg_id 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	

-- Transaction DateTime Validation
	if _tran_datetime isnull
	then
		v_err_code := v_err_code || 'VB06PCPCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06PCPCUD_001', _lang_code) || v_new_line;
	end if;
	
-- Product Type Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_PROD_TYPE' 
				   and   master_code = _prod_type_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;		
	end if;

-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code   = _prod_code 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and   master_code = _grade_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;
	
-- UOM Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_UOM' 
				   and   master_code = _uom_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB06PCPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06PCPCUD_002', _lang_code) || v_new_line;		
	end if;
	
-- Product Quantity Validation
	if _prod_qty <= 0
	then
		v_err_code := v_err_code || 'VB06PCPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06PCPCUD_003', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;


	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tprocurecostproduct		
				  where proccostprod_gid = _proccostprod_gid)
			then
				delete from pg_trn_tprocurecostproduct
				where proccostprod_gid = _proccostprod_gid;
			v_succ_code := 'SB06PCPCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tprocurecostproduct
				   where proccostprod_gid = _proccostprod_gid
				   and   pg_id 	          = _pg_id)
		 then
			insert into pg_trn_tprocurecostproduct(
				pg_id,
				tran_datetime,
				prod_type_code,
				prod_code,
				grade_code,
				uom_code,
				prod_qty,
				created_date,
				created_by)
			values(
				_pg_id,
				_tran_datetime,
				_prod_type_code,
				_prod_code,
				_grade_code,
				_uom_code,
				_prod_qty,
				now(),
				_user_code) returning proccostprod_gid into _proccostprod_gid;
				v_succ_code := 'SB06PCPCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if; 
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tprocurecostproduct
				  	 where proccostprod_gid   = _proccostprod_gid)
		then
		update pg_trn_tprocurecostproduct
		set		pg_id				=	_pg_id,
				tran_datetime		=	_tran_datetime,
				prod_type_code		=	_prod_type_code,
				prod_code			=	_prod_code,
				grade_code			=	_grade_code,
				uom_code			=	_uom_code,
				prod_qty			=	_prod_qty,
				updated_date		=	now(),
				updated_by			=	_user_code
		where  proccostprod_gid	    =	_proccostprod_gid;
		v_succ_code	:= 'SB06PCPCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tprocurecostproduct
			    where 	pg_id           = _pg_id 
			    and 	tran_datetime   = _tran_datetime
				and		prod_code		= _prod_code
			    and		grade_code		= _grade_code
			   	group	by pg_id, tran_datetime, prod_code, grade_code
				having	count('*') > 1) 
	then
		-- pg id, tran_datetime, prod_code and grade_code cannot be duplicated
		v_err_code := v_err_code || 'EB06PCPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06PCPCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procurejson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 24-02-2022
		SP Code : B01PROCUX
	*/
	
	v_colrec record;
	v_updated_date udd_datetime;
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
													(
														proc_gid udd_int,
														pg_id udd_code,
														session_id udd_code,
														pgmember_id udd_code,
														proc_date udd_date,
														advance_amount udd_amount,
														sync_status_code udd_code,
														status_code udd_code,
														created_date udd_datetime,
														created_by udd_code,
														updated_date udd_text,
														updated_by udd_code
														) 
												
			LOOP
			
			 select	 fn_text_todatetime(v_colrec.updated_date) 
			 into 	 v_updated_date;
			
			insert into pg_trn_tprocure (
														proc_gid ,
														pg_id ,
														session_id ,
														pgmember_id ,
														proc_date ,
														advance_amount ,
														sync_status_code ,
														status_code ,
														created_date ,
														created_by ,
														updated_date ,
														updated_by 
													)
										values		(
														v_colrec.proc_gid ,
														v_colrec.pg_id ,
														v_colrec.session_id ,
														v_colrec.pgmember_id ,
														v_colrec.proc_date ,
														v_colrec.advance_amount ,
														v_colrec.sync_status_code ,
														v_colrec.status_code ,
														v_colrec.created_date ,
														v_colrec.created_by ,
														v_updated_date ,
														v_colrec.updated_by 
													)
						
						on CONFLICT ( pg_id,
									  session_id,
									  pgmember_id ,
									  proc_date) 
									 do update set  proc_gid = v_colrec.proc_gid,
													pg_id = v_colrec.pg_id,
													session_id = v_colrec.session_id,
													pgmember_id = v_colrec.pgmember_id,
													proc_date = v_colrec.proc_date,
													advance_amount = v_colrec.advance_amount,
													sync_status_code = v_colrec.sync_status_code,
													status_code = v_colrec.status_code,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;

			END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procureproduct(INOUT _procprod_gid udd_int, _pg_id udd_code, _session_id udd_code, _pgmember_id udd_code, _rec_slno udd_int, _proc_date udd_date, _prod_type_code udd_code, _prod_code udd_code, _grade_code udd_code, _proc_rate udd_rate, _proc_qty udd_qty, _uom_code udd_code, _proc_remark udd_text, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 07-02-2022
		SP Code      : B06PRPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_proc_qty udd_qty := 0;
	v_rec_slno udd_int := 0;
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id       = _pg_id 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- Session ID Validation
	if not exists (select * from pg_trn_tsession
				   where session_id       = _session_id
				   and   status_code      = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_012' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_012', _lang_code) || v_new_line;
	end if;	
	
-- PG Member ID Validation
	if not exists (select * from pg_mst_tpgmember
				   where pgmember_id      = _pgmember_id
				   and   status_code      = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_005' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_005', _lang_code) || v_new_line;
	end if;	
	
-- Record SlNo Validation
	if _rec_slno < 0 
	then
		v_err_code := v_err_code || 'VB06PRPCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06PRPCUD_001', _lang_code) || v_new_line;
	end if;	
	
-- Procurement Date Validation
	if _proc_date isnull
	then
		v_err_code := v_err_code || 'VB06PRPCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06PRPCUD_002', _lang_code) || v_new_line;
	end if;	
	
-- Product Type Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_PROD_TYPE' 
				   and   master_code = _prod_type_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;		
	end if;

-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code = _prod_code 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and   master_code = _grade_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;

-- Product Quantity Validation
	if _proc_qty <= 0
	then
		v_err_code := v_err_code || 'VB06PRPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06PRPCUD_003', _lang_code) || v_new_line;		
	end if;
	
-- UOM Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_UOM' 
				   and   master_code = _grade_code 
				   and   status_code = 'A') and   _grade_code = 'KG'
	then
		v_err_code := v_err_code || 'VB06PRPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06PRPCUD_004', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if _mode_flag = 'U' then 
	
		-- Getting proc qty old value
		   select 	proc_qty into v_proc_qty
		   from 	pg_trn_tprocureproduct
		   where	pg_id = _pg_id
		   and 		session_id = _session_id
		   and 		pgmember_id = _pgmember_id
		   and 		rec_slno = _rec_slno
		   and 		proc_date = _proc_date
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code;
		   
		   select 	max(rec_slno) into v_rec_slno
		   from 	pg_trn_tprocureproduct
		   where	pg_id = _pg_id
		   and 		session_id = _session_id
		   and 		pgmember_id = _pgmember_id
		   and 		proc_date = _proc_date
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code;
		   
		   _proc_qty = _proc_qty - v_proc_qty;
		   
		   if _proc_qty <> 0 then
		  	 _procprod_gid := v_rec_slno;
			 _rec_slno := v_rec_slno + 1;
		   	 _mode_flag := 'I';
		   end if;
		   
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;

	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tprocureproduct
				  where procprod_gid = _procprod_gid)
			then
				delete from pg_trn_tprocureproduct
				where procprod_gid = _procprod_gid;
			v_succ_code := 'SB06PRPCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;

	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tprocureproduct
				       where  	pg_id = _pg_id
					   and 		session_id = _session_id
					   and 		pgmember_id = _pgmember_id
					   and 		rec_slno = _rec_slno
					   and 		proc_date = _proc_date
					   and 		prod_code = _prod_code
					   and 		grade_code = _grade_code)
		 then
			insert into pg_trn_tprocureproduct(
				procprod_gid,
				pg_id,
				session_id,
				pgmember_id,
				rec_slno,
				proc_date,
				prod_type_code,
				prod_code,
				grade_code,
				proc_rate,
				proc_qty,
				uom_code,
				proc_remark,
				created_date,
				created_by)
			values(
				_procprod_gid,
				_pg_id,
				_session_id,
				_pgmember_id,
				_rec_slno,
				_proc_date,
				_prod_type_code,
				_prod_code,
				_grade_code,
				_proc_rate,
				_proc_qty,
				_uom_code,
				_proc_remark,
				now(),
				_user_code) returning procprod_gid into _procprod_gid;
				v_succ_code := 'SB06PRPCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if; 

	elseif _mode_flag = 'U' then
	
		if exists (select * from pg_trn_tprocureproduct
				       where  	pg_id = _pg_id
					   and 		session_id = _session_id
					   and 		pgmember_id = _pgmember_id
					   and 		rec_slno = _rec_slno
					   and 		proc_date = _proc_date
					   and 		prod_code = _prod_code
					   and 		grade_code = _grade_code)
		then
		update pg_trn_tprocureproduct
		set		
				proc_remark			= _proc_remark,
				updated_date		= now(),
				updated_by			= _user_code
	   where  	pg_id = _pg_id
	   and 		session_id = _session_id
	   and 		pgmember_id = _pgmember_id
	   and 		rec_slno = _rec_slno
	   and 		proc_date = _proc_date
	   and 		prod_code = _prod_code
	   and 		grade_code = _grade_code;
	   
			v_succ_code	:= 'SB06PRPCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
		 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tprocureproduct
			    where 	pg_id         = _pg_id 
			    and 	session_id    = _session_id
			    and 	pgmember_id   = _pgmember_id
			    and 	prod_code 	  = _prod_code
			   	and 	grade_code 	  = _grade_code
			    and 	proc_date 	  = _proc_date
			    and 	rec_slno	  = _rec_slno
			    group	by pg_id, session_id, pgmember_id, rec_slno
				having	count('*') > 1) 
	then
		-- pg id session_id, pgmember_id and rec_slno cannot be duplicated
		v_err_code := v_err_code || 'EB06PRCCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06PRPCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procureproductjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Thianeswaran
		Created Date : 25-02-2022
		SP Code : B01PPRCUD
		Updated By : Mangai
*/
v_colrec record;
v_updated_date timestamp;
v_proc_rate udd_rate := 0;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														procprod_gid integer,
														pg_id udd_code,
														session_id udd_code,
														pgmember_id udd_code,
														rec_slno udd_int,
														proc_date udd_date,
														prod_type_code udd_code,
														prod_code udd_code,
														grade_code udd_code,
														proc_rate udd_text,
														proc_qty udd_qty,
														uom_code udd_code,
														created_date udd_datetime,
														created_by udd_user,
														updated_date udd_text,
														updated_by udd_user
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_torate(v_colrec.proc_rate) into v_proc_rate;
								
				insert into pg_trn_tprocureproduct (
														procprod_gid,
														pg_id,
														session_id,
														pgmember_id,
														rec_slno,
														proc_date,
														prod_type_code,
														prod_code,
														grade_code,
														proc_rate,
														proc_qty,
														uom_code,
														created_date,
														created_by,
														updated_date,
														updated_by
												)
							values              (
													v_colrec.procprod_gid,
													v_colrec.pg_id,
													v_colrec.session_id,
													v_colrec.pgmember_id,
													v_colrec.rec_slno,
													v_colrec.proc_date,
													v_colrec.prod_type_code,
													v_colrec.prod_code,
													v_colrec.grade_code,
													v_proc_rate,
													v_colrec.proc_qty,
													v_colrec.uom_code,
													v_colrec.created_date,
													v_colrec.created_by,
													v_updated_date,
													v_colrec.updated_by

							)
							
		on CONFLICT ( pg_id,
					 session_id,
					 pgmember_id,
					 rec_slno,
					 prod_code,
					 grade_code )  do update set  
													procprod_gid = v_colrec.procprod_gid,
													pg_id = v_colrec.pg_id,
													session_id = v_colrec.session_id,
													pgmember_id = v_colrec.pgmember_id,
													rec_slno = v_colrec.rec_slno,
													proc_date = v_colrec.proc_date,
													prod_type_code = v_colrec.prod_type_code,
													prod_code = v_colrec.prod_code,
													grade_code = v_colrec.grade_code,
													proc_rate = v_proc_rate,
													proc_qty = v_colrec.proc_qty,
													uom_code = v_colrec.uom_code,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;
		END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procureproductqlty(INOUT _procprodqlty_gid udd_int, _pg_id udd_code, _session_id udd_code, _pgmember_id udd_code, _rec_slno udd_int, _prod_type_code udd_code, _prod_code udd_code, _grade_code udd_code, _qltyparam_code udd_code, _qltyuom_code udd_code, _actual_value udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 07-02-2022
		SP Code      : B06PPQCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id       = _pg_id 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- Session ID Validation
	if not exists (select * from pg_trn_tsession
				   where session_id       = _session_id
				   and   status_code      = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_012' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_012', _lang_code) || v_new_line;
	end if;	
	
-- PG Member ID Validation
	if not exists (select * from pg_mst_tpgmember
				   where pgmember_id      = _pgmember_id
				   and   status_code      = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_005' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_005', _lang_code) || v_new_line;
	end if;	
	
-- Record SlNo Validation
	if _rec_slno < 0 
	then
		v_err_code := v_err_code || 'VB06PPQCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06PPQCUD_001', _lang_code) || v_new_line;
	end if;	
	
-- Product Type Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_PROD_TYPE' 
				   and   master_code = _prod_type_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;		
	end if;

-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code = _prod_code 
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and   master_code = _grade_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;

-- Quality Parameter Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_QC_PARAMETER' 
				   and   master_code = _qltyparam_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB06PPQCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06PPQCUD_002', _lang_code) || v_new_line;		
	end if;
	
-- Quality Unit of Measurement Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_QC_UOM' 
				   and   master_code = _qltyuom_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB06PPQCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06PPQCUD_003', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;

	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tprocureproductqlty
				  where procprodqlty_gid = _procprodqlty_gid)
			then
				delete from pg_trn_tprocureproductqlty
				where procprodqlty_gid = _procprodqlty_gid;
			v_succ_code := 'SB06PPQCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;

	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tprocureproductqlty
				       where  procprodqlty_gid	= _procprodqlty_gid
				       and    pg_id 	= _pg_id)
		 then
			insert into pg_trn_tprocureproductqlty(
				pg_id,
				session_id,
				pgmember_id,
				rec_slno,
				prod_type_code,
				prod_code,
				grade_code,
				qltyparam_code,
				qltyuom_code,
				actual_value,
				created_date,
				created_by)
			values(
				_pg_id,
				_session_id,
				_pgmember_id,
				_rec_slno,
				_prod_type_code,
				_prod_code,
				_grade_code,
				_qltyparam_code,
				_qltyuom_code,
				_actual_value,
				now(),
				_user_code) returning procprodqlty_gid into _procprodqlty_gid;
				v_succ_code := 'SB06PPQCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if; 

	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tprocureproductqlty
				   where procprodqlty_gid = _procprodqlty_gid)
		then
		update pg_trn_tprocureproductqlty
		set		pg_id				= _pg_id,
				session_id			= _session_id,
				pgmember_id			= _pgmember_id,
				rec_slno			= _rec_slno,
				prod_type_code		= _prod_type_code,
				prod_code			= _prod_code,
				grade_code			= _grade_code,
				qltyparam_code		= _qltyparam_code,
				qltyuom_code		= _qltyuom_code,
				actual_value		= _actual_value,
				updated_date		= now(),
				updated_by			= _user_code
		where   procprodqlty_gid        = _procprodqlty_gid;
		v_succ_code	:= 'SB06PPQCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
		 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tprocureproductqlty
			    where 	pg_id         = _pg_id 
			    and 	session_id    = _session_id
			    and 	pgmember_id   = _pgmember_id
			    and 	rec_slno	  = _rec_slno
			    group	by pg_id, session_id, pgmember_id, rec_slno
				having	count('*') > 1) 
	then
		-- pg id session_id, pgmember_id and rec_slno cannot be duplicated
		v_err_code := v_err_code || 'EB06PRCCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06PPQCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_procureproductqltyjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Thianeswaran
		Created Date : 25-02-2022
		SP Code : B01PPQCUX
		Updated By : Mangai
*/
v_colrec record;
v_updated_date timestamp;
begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														procprodqlty_gid integer,
														pg_id udd_code,
														session_id udd_code,
														pgmember_id udd_code,
														rec_slno udd_int,
														prod_type_code udd_code,
														prod_code udd_code,
														grade_code udd_code,
														qltyparam_code udd_code,
														qltyuom_code udd_code,
														actual_value udd_desc,
														created_date udd_datetime,
														created_by udd_user,
														updated_date udd_text,
														updated_by udd_user
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				
				insert into pg_trn_tprocureproductqlty (
														procprodqlty_gid,
														pg_id,
														session_id,
														pgmember_id,
														rec_slno,
														prod_type_code,
														prod_code,
														grade_code,
														qltyparam_code,
														qltyuom_code,
														actual_value,
														created_date,
														created_by,
														updated_date,
														updated_by
												)
							values              (
													v_colrec.procprodqlty_gid,
													v_colrec.pg_id,
													v_colrec.session_id,
													v_colrec.pgmember_id,
													v_colrec.rec_slno,
													v_colrec.prod_type_code,
													v_colrec.prod_code,
													v_colrec.grade_code,
													v_colrec.qltyparam_code,
													v_colrec.qltyuom_code,
													v_colrec.actual_value,
													v_colrec.created_date,
													v_colrec.created_by,
													v_updated_date,
													v_colrec.updated_by
							)
							
		on CONFLICT ( pg_id,
					 session_id,
					 pgmember_id,
					 rec_slno,
					 prod_code,
					 grade_code,
					 qltyparam_code )  do update set  
													procprodqlty_gid = v_colrec.procprodqlty_gid,
													pg_id = v_colrec.pg_id,
													session_id = v_colrec.session_id,
													pgmember_id = v_colrec.pgmember_id,
													rec_slno = v_colrec.rec_slno,
													prod_type_code = v_colrec.prod_type_code,
													prod_code = v_colrec.prod_code,
													grade_code = v_colrec.grade_code,
													qltyparam_code  = v_colrec.qltyparam_code,
													qltyuom_code  = v_colrec.qltyuom_code,
													actual_value  = v_colrec.actual_value,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by
					;
		END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_prodprice(INOUT _prodprice_gid udd_int, _prod_code udd_code, _prod_state_id udd_int, _prod_grade_code udd_code, _prod_msp_price udd_amount, _procurement_price udd_amount, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 29-12-2021
		SP Code : B01PTPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- prod code cannot be blank
	if _prod_code = '' then
		v_err_code := v_err_code || 'VB01PTPCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTPCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- state id cannot be blank
	if not exists (select 	* 
				   from 	state_master 
				   where 	state_id = _prod_state_id
				   and 		is_active = true
				  ) then
		v_err_code := v_err_code || 'VB01PTPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTPCUD_002', _lang_code)|| v_new_line;	
	end if;
	
	-- grade code cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_GRADE'
				   and 		master_code = _prod_grade_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PTPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTPCUD_003', _lang_code)|| v_new_line;	
	end if;
	
	-- prod msp price cannot be blank
	if _prod_msp_price = 0 then
		v_err_code := v_err_code || 'VB01PTPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTPCUD_004', _lang_code) || v_new_line;
	end if;
	
	-- prod curprice cannot be blank
	if _procurement_price = 0 then
		v_err_code := v_err_code || 'VB01PTPCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTPCUD_005', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tproductprice
				  where 	prodprice_gid = _prodprice_gid
				 ) then
				 
			Delete from 	core_mst_tproductprice
			where		    prodprice_gid = _prodprice_gid;
			
			v_succ_code := 'SB01PTPCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tproductprice
					  where		prodprice_gid = _prodprice_gid
					 ) then
			insert into core_mst_tproductprice 
			(
				prod_code,
				state_id,
				grade_code,
				msp_price,
				procurement_price,
				last_modified_date,
				created_by,
				created_date
			)
			values
			(
				_prod_code,
				_prod_state_id,
				_prod_grade_code,
				_prod_msp_price,
				_procurement_price,
				now(),
				_user_code,
				now()
			) returning prodprice_gid into _prodprice_gid;
			
			v_succ_code := 'SB01PTPCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tproductprice
				   where	prodprice_gid = _prodprice_gid
				   ) then
			update	core_mst_tproductprice 
			set		state_id 			= _prod_state_id,
					grade_code 			= _prod_grade_code,
					msp_price 			= _prod_msp_price ,
					procurement_price 	= _procurement_price,
					updated_by 			= _user_code,
					updated_date 		= now()
			where 	prodprice_gid 		= _prodprice_gid;
			
			v_succ_code := 'SB01PTPCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_tproductprice
			    where 	prod_code = _prod_code
			    and     state_id = _prod_state_id
			    and     grade_code = _prod_grade_code
				group	by prod_code,state_id,grade_code
				having	count('*') > 1) 
	then
		-- state id and grade cannot be duplicated
		v_err_code := v_err_code || 'EB01PTPCUD_001';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB01PTPCUD_001', _lang_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_prodquality(INOUT _prodqlty_gid udd_int, _prod_code udd_code, _prod_qltyparam_code udd_code, _prod_range_from udd_rate, _prod_range_to udd_rate, _prod_range_flag udd_flag, _prod_qltyuom_code udd_code, _prod_threshold_value udd_rate, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 26-12-2021
		SP Code : B01PTQCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- prod code cannot be blank
	if _prod_code = '' then
		v_err_code := v_err_code || 'VB01PTQCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTQCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- product quality cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_QC_PARAMETER'
				   and 		master_code = _prod_qltyparam_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PTQCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTQCUD_002', _lang_code);	
	end if;
	
	-- product UOM cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_QC_UOM'
				   and 		master_code = _prod_qltyuom_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PTQCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTQCUD_003', _lang_code);	
	end if;
	
	-- product range flag Validation
	if (_prod_range_flag <> '') then
		if not exists (select 	* 
					   from 	core_mst_tmaster 
					   where 	parent_code = 'QCD_RANGE_FLAG'
					   and 		master_code = _prod_range_flag 
					   and 		status_code = 'A'
					  ) then
			v_err_code := v_err_code || 'VB01PTQCUD_004' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTQCUD_004', _lang_code);	
		end if;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tproductquality
				  where 	prodqlty_gid = _prodqlty_gid
				 ) then
				 
			Delete from 	core_mst_tproductquality
			where		    prodqlty_gid = _prodqlty_gid;
			
			v_succ_code := 'SB01PTQCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tproductquality
					  where		prodqlty_gid = _prodqlty_gid
					 ) then
			insert into core_mst_tproductquality 
			(
				prod_code,
				qltyparam_code,
				range_from,
				range_to,
				range_flag,
				qltyuom_code,
				threshold_value,
				created_by,
				created_date
			)
			values
			(
				_prod_code,
				_prod_qltyparam_code,
				_prod_range_from,
				_prod_range_to,
				_prod_range_flag,
				_prod_qltyuom_code,
				_prod_threshold_value,
				_user_code,
				now()
			) returning prodqlty_gid into _prodqlty_gid;
			
			v_succ_code := 'SB01PTQCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tproductquality
				   where	prodqlty_gid = _prodqlty_gid
				   ) then
			update	core_mst_tproductquality 
				set	qltyparam_code 	= _prod_qltyparam_code,
					range_from 		= _prod_range_from,
					range_to 		= _prod_range_to,
					range_flag 		= _prod_range_flag,
					qltyuom_code 	= _prod_qltyuom_code,
					threshold_value = _prod_threshold_value,
					updated_by 		= _user_code,
					updated_date 	= now()
			where 	prodqlty_gid 	= _prodqlty_gid;
			
			v_succ_code := 'SB01PTQCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_tproductquality
			    where 	prod_code = _prod_code
			    and     qltyparam_code = _prod_qltyparam_code
				group	by prod_code,qltyparam_code
				having	count('*') > 1) 
	then
		-- quality parameter cannot be duplicated
		v_err_code := v_err_code || 'EB01PTQCUD_001';
		v_err_msg  := v_err_msg ||  fn_get_msg('EB01PTQCUD_001', _lang_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_prodtranslate(INOUT _prodtranslate_gid udd_int, _prod_code udd_code, _prod_lang_code udd_code, _prod_desc udd_desc, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : -29-2-2021
		SP Code : B01PTTCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- prod code cannot be blank
	if _prod_code = '' then
		v_err_code := v_err_code || 'VB01PTTCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTTCUD_001', _lang_code) || v_new_line;
	end if;
	
	--Product lang code cannot be blank
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _prod_lang_code
				   and 		default_flag = 'N'
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PTTCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTTCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- prod desc cannot be blank
	if _prod_desc = '' then
		v_err_code := v_err_code || 'VB01PTTCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PTTCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tproducttranslate
				  where 	prodtranslate_gid = _prodtranslate_gid
				 ) then
				 
			Delete from 	core_mst_tproducttranslate
			where		    prodtranslate_gid = _prodtranslate_gid;
			
			v_succ_code := 'SB01PRTCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tproducttranslate
					  where		prod_code = _prod_code
					  and       lang_code = _prod_lang_code
					 ) then
			insert into core_mst_tproducttranslate 
			(
				prod_code,
				lang_code,
				prod_desc
			)
			values
			(
				_prod_code,
				_prod_lang_code,
				_prod_desc
			) returning prodtranslate_gid into _prodtranslate_gid;
			
			v_succ_code := 'SB01PRTCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tproducttranslate
				   where	prodtranslate_gid = _prodtranslate_gid
				   ) then
			update	core_mst_tproducttranslate 
			set		lang_code 			= _prod_lang_code,
					prod_desc 			= _prod_desc
			where 	prodtranslate_gid 	= _prodtranslate_gid;
			
			v_succ_code := 'SB01PRTCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_product(INOUT _prod_gid udd_int, INOUT _prod_code udd_code, _prod_desc udd_desc, _prod_farm_flag udd_flag, _prod_type_code udd_code, _prod_category_code udd_code, _prod_subcategory_code udd_code, _prod_uom_code udd_code, _prod_image udd_text, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, _row_timestamp udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 29-12-2021
		SP Code : B01PRTCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
begin
	-- validation
	-- prod farm flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PG_TYPE'
				   and 		master_code = _prod_farm_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PRTCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PRTCUD_002', _lang_code)|| v_new_line;	
	end if;
	
	-- product type code Validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PROD_TYPE'
				   and 		master_code = _prod_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PRTCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PRTCUD_003', _lang_code)|| v_new_line;
	end if;

	-- category code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_CATEGORY'
				   and 		master_code = _prod_category_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PRTCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PRTCUD_004', _lang_code)|| v_new_line;
	end if;
	
	-- sub category code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_SUBCATEGORY'
				   and 		master_code = _prod_subcategory_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PRTCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PRTCUD_005', _lang_code)|| v_new_line;	
	end if;
	
	-- prod uom code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_UOM'
				   and 		master_code = _prod_uom_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PRTCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PRTCUD_006', _lang_code)|| v_new_line;	
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01PRTCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01PRTCUD_007', _lang_code)|| v_new_line;	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code)|| v_new_line;	
	end if;

	-- timestamp check for concurrency
	select 	to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') into v_timestamp 
	from 	core_mst_tproduct
	where	prod_gid = _prod_gid;
	
	v_timestamp	:= coalesce(v_timestamp, '');
	
	IF (v_timestamp != _row_timestamp) 
	then
		-- Record modified since last fetch so Kindly refetch and continue
		v_err_code := v_err_code || 'VB00CMNCMN_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_002', _lang_code) || v_new_line;	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tproduct
				  where 	prod_code = _prod_code 
				  and 		status_code = 'A'
				 ) then
			Update 	core_mst_tproduct
			set		status_code 	= 'I',
					updated_by 		= _user_code,
					updated_date 	= now(),
					row_timestamp 	= now()
			where 	prod_code 		= _prod_code 
			and 	status_code 	= 'A';
			
			v_succ_code := 'SB01PRTCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tproduct
					  where		prod_code = _prod_code 
					  and 		status_code = 'A'
					 ) then
			insert into core_mst_tproduct 
			(
				prod_code,
				farm_prod_flag,
				prod_type_code,
				category_code,
				subcategory_code,
				uom_code,
				prod_image,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				_prod_code,
				_prod_farm_flag ,
				_prod_type_code,
				_prod_category_code,
				_prod_subcategory_code,
				_prod_uom_code,
				_prod_image,
				_status_code,
				_user_code,
				now(),
				now()
			) returning prod_gid,prod_code into _prod_gid,_prod_code;
			
-- 			_prod_code:= SUBSTRING(_prod_desc, 1, 5) || '_' || _prod_gid;
			_prod_code := (select CONCAT(upper(substring 
							 (regexp_replace(_prod_desc collate pg_catalog.""default"", '[^a-zA-Z]', '', 'g')
							  ,1,5)),'_',_prod_gid));
			update	core_mst_tproduct 
			set 	prod_code = _prod_code
			where 	prod_gid = _prod_gid;
			
			v_succ_code := 'SB01PRTCUD_001';
			
			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tproduct
				   where	prod_gid = _prod_gid 
				   and 		status_code = 'A'
				   ) then
			update	core_mst_tproduct 
			 set	farm_prod_flag 			= _prod_farm_flag,
					prod_type_code 			= _prod_type_code,
					category_code 			= _prod_category_code,
					subcategory_code 		= _prod_subcategory_code,
					uom_code 				= _prod_uom_code,
					prod_image 				= _prod_image,
					status_code 			= _status_code,
					updated_by 				= _user_code,
					updated_date 			= now(),
					row_timestamp 			= now()
			where 	prod_gid = _prod_gid
			and 	status_code = 'A';
			
			v_succ_code := 'SB01PRTCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if  exists(select *
				   from 	core_mst_tproducttranslate
				   where	prod_code = _prod_code
			   		and		lang_code = 'en_US'
				   ) then
			update	core_mst_tproducttranslate 
			set 	prod_desc = _prod_desc
			where 	prod_code = _prod_code
			and		lang_code = 'en_US';
			
	else
	insert into core_mst_tproducttranslate 
			(
				prod_code,
				lang_code,
				prod_desc
			)
			values
			(
				_prod_code,
				'en_US',
				_prod_desc
			); 
	end if;

		
	if exists (	select	count(*)
				from 	core_mst_tproduct
			    where 	prod_code = _prod_code 
				group	by prod_code
				having	count('*') > 1) 
	or exists (select 	'*' 
			   	from  		core_mst_tproducttranslate
			   	where 		prod_desc = _prod_desc
			   	and 	 	lang_code = _lang_code
			  	group by 	prod_desc,lang_code
				having	count('*') > 1)
	then
		-- prod code cannot be duplicated
		v_err_code := v_err_code || 'EB01PRTCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB01PRTCUD_001', _lang_code),_prod_desc);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_report(INOUT _report_gid udd_int, _report_code udd_code, _report_name udd_desc, _sp_name udd_desc, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/* 
		Created By : Mangai
		Created Date : 13-05-2022
		SP Code : B01REPCUD
	*/
	
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

	-- Report Code Validation
	if _report_code = '' then
		v_err_code := v_err_code || 'VB01REPCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01REPCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- Report Name Validation
	if _report_name = '' then
		v_err_code := v_err_code || 'VB01REPCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01REPCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- SP Name Validation
	if _sp_name = '' then
		v_err_code := v_err_code || 'VB01REPCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01REPCUD_003', _lang_code) || v_new_line;
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code);	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_treport
				  where 	report_gid  = _report_gid
				  and 		status_code = 'A'
				 ) then
			Update 	core_mst_treport
			set		status_code  = 'I',
					updated_by   = _user_code,
					updated_date = now()
			where 	report_gid   = _report_gid
			and 	status_code  = 'A';
			
			v_succ_code := 'SB01REPCUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
		elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_treport
					  where		report_code = _report_code
					  and 		status_code = 'A'
					 ) then
			insert into core_mst_treport 
			(
				report_code,
				report_name,
				sp_name,
				status_code,
				created_date,
				created_by
			)
			values
			(
				_report_code,
				_report_name,
				_sp_name,
				_status_code,
				now(),
				_user_code
			) returning report_gid into _report_gid;
			
			v_succ_code := 'SB01REPCUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
		elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_treport
				   where	report_code  = _report_code
				   and 		status_code = 'A'
				   ) then
			update	core_mst_treport 
			set 	report_name	 = _report_name,
					sp_name 	 = _sp_name,
					status_code  = _status_code,
					updated_by   = _user_code,
					updated_date = now()
			where 	report_gid   = _report_gid
			and 	status_code  = 'A';
			
			v_succ_code := 'SB01REPCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_treport
			    where 	report_code = _report_code
				group	by report_code
				having	count('*') > 1) 
	then
		-- report code cannot be duplicated
		v_err_code := v_err_code || 'EB01REPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB01REPCUD_001', _lang_code),_report_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_reportparam(INOUT _reportparam_gid udd_int, _report_code udd_code, _param_code udd_code, _param_type_code udd_code, _param_name udd_desc, _param_desc udd_desc, _param_datatype_code udd_code, _param_order udd_int, _lang_code udd_code, _user_code udd_user, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*  
		Created By : Mangai
		Created Date : 13-05-2022
		SP Code : B01RPACUD
	*/
	
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

	-- Report Code Validation
	if not exists (select 	* 
				   from 	core_mst_treport
				   where 	report_code = _report_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01RPACUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RPACUD_001', _lang_code) || v_new_line;
	end if;
	
	-- Param Code Validation
	if _param_code = '' then
		v_err_code := v_err_code || 'VB01RPACUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RPACUD_002', _lang_code) || v_new_line;
	end if;
	
	-- Param Type Code Validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PARAM_TYPE'
				   and 		master_code = _param_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01RPACUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RPACUD_003', _lang_code) || v_new_line;
	end if;
	
	-- Param Name Validation
	if _param_name = '' then
		v_err_code := v_err_code || 'VB01RPACUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RPACUD_004', _lang_code) || v_new_line;
	end if;
	
	-- Param Desc validation
	if _param_desc = '' then
		v_err_code := v_err_code || 'VB01RPACUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RPACUD_005', _lang_code) || v_new_line;
	end if;
	
	-- Param DataType Code	
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_PARAM_DATATYPE'
				   and 		master_code = _param_datatype_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01RPACUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RPACUD_006', _lang_code) || v_new_line;
	end if;
	
	-- Param Order Validation
	if _param_order = 0 then
		v_err_code := v_err_code || 'VB01RPACUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RPACUD_007', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_treportparam
				  where 	reportparam_gid = _reportparam_gid 
				 ) then
				 
				 delete from core_mst_treportparam
				 where reportparam_gid = _reportparam_gid ;
				 
				 v_succ_code := 'SB01RPACUD_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
		elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_treportparam
					  where		report_code= _report_code
					  and       param_code = _param_code 
					 ) then
			insert into core_mst_treportparam 
			(
				report_code,
				param_code,
				param_type_code,
				param_name,
				param_desc,
				param_datatype_code,
				param_order,
				created_date,
				created_by
			)
			values
			(
				_report_code,
				_param_code,
				_param_type_code,
				_param_name,
				_param_desc,
				_param_datatype_code,
				_param_order,
				now(),
				_user_code
			) returning reportparam_gid into _reportparam_gid;
			
			v_succ_code := 'SB01RPACUD_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
		elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_treportparam
				   where	param_code  = _param_code
				   ) then
			update	core_mst_treportparam 
			set 	report_code = _report_code,
					param_type_code = _param_type_code,
					param_name = _param_name,
					param_desc = _param_desc,
					param_datatype_code = _param_datatype_code,
					param_order = _param_order,
					updated_date = now(),
					updated_by = _user_code
			where	param_code  = _param_code;
			
			v_succ_code := 'SB01RPACUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_treportparam
			    where 	param_code = _param_code 
				group	by param_code
				having	count('*') > 1) 
	then
		-- param code cannot be duplicated
		v_err_code := v_err_code || 'EB01RPACUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB01RPACUD_001', _lang_code),_param_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_role(INOUT _role_gid udd_int, _role_name udd_desc, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, _row_timestamp udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 15-12-2021
		SP Code : B01ROLCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
	v_role_code udd_desc := '';
begin
    v_role_code := replace(_role_name collate pg_catalog.""default"",' ','');
	_status_code := 'A';
	-- validation
	-- Role name cannot be blank
	if _role_name = '' then
		v_err_code := v_err_code || 'VB01RLMCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RLMCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code);	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	-- timestamp check for concurrency
	select 	to_char(row_timestamp,'DD-MM-YYYY HH:MI:SS:MS') into v_timestamp 
	from 	core_mst_trole
	where	role_gid = _role_gid;
	
	v_timestamp	:= coalesce(v_timestamp, '');
	
	IF (v_timestamp != _row_timestamp) 
	then
		-- Record modified since last fetch so Kindly refetch and continue
		v_err_code := v_err_code || 'VB00CMNCMN_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_002', _lang_code) || v_new_line;	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_trole
				  where 	role_gid = _role_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	core_mst_trole
			set		status_code = 'I',
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	role_gid = _role_gid 
			and 	status_code = 'A';
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_trole
					  where		role_code = v_role_code 
					  and 		status_code = 'A'
					 ) then
			insert into core_mst_trole 
			(
				role_code,
				role_name,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				v_role_code,
				_role_name,
				_status_code,
				_user_code,
				now(),
				now()
			) returning role_gid into _role_gid;
			
			v_succ_code := 'SB00CMNCMN_001';
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_trole
				   where	role_gid = _role_gid 
				   and 		status_code = 'A'
				   ) then
			update	core_mst_trole 
			set 	status_code = _status_code,
					updated_by = _user_code,
					updated_date = now(),
					row_timestamp = now()
			where 	role_gid = _role_gid 
			and 	status_code = 'A';
			
			v_succ_code := 'SB00CMNCMN_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_trole
			    where 	role_code = v_role_code 
				group	by role_code
				having	count('*') > 1) 
	then
		-- role code cannot be duplicated
		v_err_code := v_err_code || 'EB01ROLCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB01ROLCUD_001', _lang_code),v_role_code);	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_rolemenurights(INOUT _rolemenurights_gid udd_int, INOUT _role_code udd_code, _menu_code udd_code, _add_flag udd_desc, _modifiy_flag udd_flag, _view_flag udd_flag, _auth_flag udd_flag, _print_flag udd_flag, _inactive_flag udd_flag, _deny_flag udd_flag, _lang_code udd_code, _user_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 16-12-2021
		SP Code : B01RORCDX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin
	-- validation
	-- Role code cannot be blank
	if _role_code = '' then
		v_err_code := v_err_code || 'VB01RLRCXX_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RLRCXX_001', _lang_code) || v_new_line;
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A' 	
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if exists(select 	* 
				  from 		core_mst_trolemenurights
				  where 	role_code = _role_code 
				  and 		menu_code = _menu_code 
				 ) then
				 
			update	core_mst_trolemenurights 
			set 	add_flag = _add_flag,
					modifiy_flag = _modifiy_flag,
					view_flag = _view_flag,
					auth_flag = _auth_flag,
					print_flag = _print_flag,
					inactive_flag = _inactive_flag,
					deny_flag = _deny_flag
			where 	role_code = _role_code
			and 	menu_code = _menu_code
			returning role_code into _role_code;
			
			v_succ_code := 'SB01RLMCUD_002';
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
			
	end if;
	
	if not exists (select 	* 
				   from 	core_mst_trolemenurights 
				   where 	role_code = _role_code
				   and 		menu_code = _menu_code 
				  ) then
					  
			 insert into core_mst_trolemenurights
								(
									role_code,
									menu_code,
									add_flag,
									modifiy_flag,
									view_flag,
									auth_flag,
									print_flag,
									inactive_flag,
									deny_flag
								)
								values
								(
									_role_code,
									_menu_code,
									_add_flag,
									_modifiy_flag,
									_view_flag,
									_auth_flag,
									_print_flag,
									_inactive_flag,
									_deny_flag
								) returning role_code into _role_code;

					 v_succ_code := 'SB01RLMCUD_001';
					_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
					
	end if;		
					
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_rolemenurights_old(INOUT _rolemenurights_gid udd_int, INOUT _role_code udd_code, _role_name udd_desc, _menu_code udd_code, _add_flag udd_desc, _modifiy_flag udd_flag, _view_flag udd_flag, _auth_flag udd_flag, _print_flag udd_flag, _inactive_flag udd_flag, _deny_flag udd_flag, _mode_flag udd_flag, _lang_code udd_code, _user_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 20-12-2021
		SP Code : B01RLMCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_role_code udd_desc := '';

begin
	v_role_code = replace(_role_name collate pg_catalog.""default"",' ','');
	-- validation
	-- Role name cannot be blank
	if _role_name = '' then
		v_err_code := v_err_code || 'VB01RLMCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01RLMCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if ( _mode_flag = 'I' ) then
	
		if not exists(select 	* 
					  from		core_mst_trole
					  where		role_name = _role_name  
					  and 		status_code = 'A'
					 ) then
			insert into core_mst_trole 
			(
				role_code,
				role_name,
				status_code,
				created_by,
				created_date,
				row_timestamp
			)
			values
			(
				v_role_code,
				_role_name,
				'A',
				_user_code,
				now(),
				now()
			) returning role_code into _role_code;
			
					v_succ_code := 'SB01RLMCUD_001';
					_succ_msg := fn_get_msg(v_succ_code,_lang_code);
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
			
		end if;
	end if;
	-- Rolemenurights insert
	if(_menu_code <> '') then
				insert into core_mst_trolemenurights
					(
						role_code,
						menu_code,
						add_flag,
						modifiy_flag,
						view_flag,
						auth_flag,
						print_flag,
						inactive_flag,
						deny_flag
					)
					values
					(
						v_role_code,
						_menu_code,
						_add_flag,
						_modifiy_flag,
						_view_flag,
						_auth_flag,
						_print_flag,
						_inactive_flag,
						_deny_flag
					)	
					
					returning role_code into _role_code;
			
					v_succ_code := 'SB01RLMCUD_001';
					_succ_msg := fn_get_msg(v_succ_code,_lang_code);
	end if;
		
	if (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_trolemenurights
				   where	role_code = _role_code 
				   and 		menu_code = _menu_code
				   ) then
			update	core_mst_trolemenurights 
			set 	add_flag = _add_flag,
					modifiy_flag = _modifiy_flag,
					view_flag = _view_flag,
					auth_flag = _auth_flag,
					print_flag = _print_flag,
					inactive_flag = _inactive_flag,
					deny_flag = _deny_flag
			where 	role_code = _role_code
			and 	menu_code = _menu_code;
			
			v_succ_code := 'SB01RLMCUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_rolemenurightsdelete(_role_code udd_code, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 16-12-2021
		SP Code : B01RLRDXX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_timestamp udd_text := '';
begin
	-- validation
	-- Role code cannot be blank
	if _role_code = '' then
			v_err_code := v_err_code || 'VB01RLRDXX_001' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB01RLRDXX_001', _lang_code) || v_new_line;
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;
	
	if v_err_code <> '' then
		RAISE EXCEPTION '%',v_err_code || v_err_msg;
	end if;
	
		if exists(select 	* 
				  from 		core_mst_trolemenurights
				  where 	role_code = _role_code 
				 ) then
				 
				  delete 
				  from 		core_mst_trolemenurights
				  where 	role_code = _role_code;
				  
				  v_succ_code := 'SB00CMNCMN_003';
				  _succ_msg := fn_get_msg(v_succ_code,_lang_code);
				 
		else
				  _succ_msg := v_err_msg;
		end if;
		
		if (_succ_msg = '')
		then
				  v_err_code := 'VB01RLRDXX_002';
				  _succ_msg := v_succ_code || '-' || fn_get_msg(v_err_code,_lang_code);
		end if;
		
					
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_sale(INOUT _sale_gid udd_int, _pg_id udd_code, _inv_date udd_date, _inv_no udd_code, _buyer_name udd_desc, _collected_amount udd_amount, _sync_status_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By : Mangai
		Created Date : 05-02-2022
		SP Code : B06SALCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_role_code udd_code := 'udyogmitra';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id     = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	

-- Invoice Date Validation
	if _inv_date isnull
	then
		v_err_code := v_err_code || 'VB06SALCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SALCUD_001', _lang_code) || v_new_line;
	end if;	
	
-- Invoice No Validation
	if _inv_no = ''
	then
		v_err_code := v_err_code || 'VB06SALCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SALCUD_002', _lang_code) || v_new_line;
	end if;	
	
-- Buyer Name Validation
	if _buyer_name  = ''
	then
		v_err_code := v_err_code || 'VB06SALCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SALCUD_003', _lang_code) || v_new_line;
	end if;	
	
-- Sync Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_SYNC_STATUS' 
				   and 	  master_code = _sync_status_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_013', _lang_code) || v_new_line;		
	end if;
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code   = 'QCD_STATUS' 
				   and   master_code   = _status_code 
				   and   status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tsale
				  where sale_gid    = _sale_gid
				  and   status_code <> 'I')
			then
			update pg_trn_tsale 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where sale_gid 	    = _sale_gid
				and	pg_id		    = _pg_id
				and status_code	    <> 'I';
			v_succ_code := 'SB06SALCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tsale
				   where sale_gid 	= _sale_gid
				   and pg_id		= _pg_id)
		 then
			insert into pg_trn_tsale(
				sale_gid,
				pg_id,
				inv_date,
				inv_no,
				buyer_name,
				collected_amount,
				sync_status_code,
				status_code,
				created_date,
				created_by
				)
			values(
				_sale_gid,
				_pg_id,
				_inv_date,
				_inv_no,
				_buyer_name,
				_collected_amount,
				_sync_status_code,
				_status_code,
				now(),
				_user_code) returning sale_gid into _sale_gid;
				
-- 				CALL public.pr_sms_invoicetobuyer(
-- 													_pg_id , 
-- 													_user_code , 
-- 													v_role_code , 
-- 													_buyer_name , 
-- 													_inv_date, 
-- 													_lang_code , 
-- 													_succ_msg 
-- 												 );		
				
				v_succ_code := 'SB06SALCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tsale
				   where sale_gid    = _sale_gid
				   and   status_code <> 'I' )
		then
		update pg_trn_tsale
		set		pg_id				= _pg_id,
				inv_date			= _inv_date,
				inv_no				= _inv_no,
				buyer_name			= _buyer_name,
				collected_amount	= _collected_amount,
				sync_status_code	= _sync_status_code,
				status_code			= _status_code,	
				updated_date		= now(),
				updated_by			= _user_code
		where   sale_gid			= _sale_gid
		and	    status_code			<>	'I';
		 v_succ_code	:= 'SB06SALCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tsale
			    where 	pg_id       = _pg_id 
			    and 	inv_date    = _inv_date
			    and 	inv_no      = _inv_no
			    group	by pg_id, inv_date, inv_no
				having	count('*') > 1) 
	then
		-- pg id, inv_date and inv_no cannot be duplicated
		v_err_code := v_err_code || 'EB06SALCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06SALCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_sale(INOUT _sale_gid udd_int, _pg_id udd_code, _inv_date udd_date, _inv_no udd_code, _buyer_name udd_desc, _collected_amount udd_amount, _inv_amount udd_amount, _sync_status_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By : Mangai
		Created Date : 05-02-2022
		SP Code : B06SALCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_role_code udd_code := 'udyogmitra';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id     = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	

-- Invoice Date Validation
	if _inv_date isnull
	then
		v_err_code := v_err_code || 'VB06SALCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SALCUD_001', _lang_code) || v_new_line;
	end if;	
	
-- Invoice No Validation
	if _inv_no = ''
	then
		v_err_code := v_err_code || 'VB06SALCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SALCUD_002', _lang_code) || v_new_line;
	end if;	
	
-- Buyer Name Validation
	if _buyer_name  = ''
	then
		v_err_code := v_err_code || 'VB06SALCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SALCUD_003', _lang_code) || v_new_line;
	end if;	
	
	-- Collected amt Validation
	if  _collected_amount  > _inv_amount
	then
		v_err_code := v_err_code || 'VB06SALCUD_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SALCUD_004', _lang_code) || v_new_line;
	end if;	
	
	-- Sync Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where  parent_code = 'QCD_SYNC_STATUS' 
				   and 	  master_code = _sync_status_code 
				   and 	  status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_013', _lang_code) || v_new_line;		
	end if;
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code   = 'QCD_STATUS' 
				   and   master_code   = _status_code 
				   and   status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tsale
				  where sale_gid    = _sale_gid
				  and   status_code <> 'I')
			then
			update pg_trn_tsale 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where sale_gid 	    = _sale_gid
				and	pg_id		    = _pg_id
				and status_code	    <> 'I';
			v_succ_code := 'SB06SALCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tsale
				  	   where pg_id		= _pg_id
					   and	 inv_date   = _inv_date
					   and	 inv_no 	= _inv_no)
		 then
			insert into pg_trn_tsale(
				sale_gid,
				pg_id,
				inv_date,
				inv_no,
				buyer_name,
				collected_amount,
				inv_amount,
				sync_status_code,
				status_code,
				created_date,
				created_by
				)
			values(
				_sale_gid,
				_pg_id,
				_inv_date,
				_inv_no,
				_buyer_name,
				_collected_amount,
				_inv_amount,
				_sync_status_code,
				_status_code,
				now(),
				_user_code) returning sale_gid into _sale_gid;
				
				CALL public.pr_sms_invoicetobuyer(
													_pg_id , 
													_user_code , 
													v_role_code , 
													_buyer_name , 
													_inv_date, 
													_lang_code , 
													_succ_msg 
												 );		
				
				v_succ_code := 'SB06SALCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tsale
				   where sale_gid    = _sale_gid
				   and   status_code <> 'I' )
		then
		update pg_trn_tsale
		set		pg_id				= _pg_id,
				inv_date			= _inv_date,
				inv_no				= _inv_no,
				buyer_name			= _buyer_name,
				collected_amount	= _collected_amount,
				inv_amount			= _inv_amount,
				sync_status_code	= _sync_status_code,
				status_code			= _status_code,	
				updated_date		= now(),
				updated_by			= _user_code
		where   sale_gid			= _sale_gid
		and	    status_code			<>	'I';
				
		 v_succ_code	:= 'SB06SALCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tsale
			    where 	pg_id       = _pg_id 
			    and 	inv_date    = _inv_date
			    and 	inv_no      = _inv_no
			    group	by pg_id, inv_date, inv_no
				having	count('*') > 1) 
	then
		-- pg id, inv_date and inv_no cannot be duplicated
		v_err_code := v_err_code || 'EB06SALCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06SALCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_saleadjustment(INOUT _saleprod_gid udd_int, _pg_id udd_code, _inv_date udd_date, _inv_no udd_code, _prod_type_code udd_code, _prod_code udd_code, _grade_code udd_code, _sale_qty udd_qty, _inv_qty udd_qty, _adjust_qty udd_qty, _sale_base_amount udd_amount, _sale_amount udd_amount, _inv_amount udd_amount, _sale_rate udd_rate, _record_count udd_int, _min_rec_slno udd_int, _max_rec_slno udd_int, _adjust_type_code udd_code, _adjust_date udd_date, _user_code udd_user, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 12-09-2022
		SP Code      : B01SADCUX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_sale_amount udd_amount := 0;
	v_rec_slno udd_int := 0; 
	v_payment_calc_flag udd_flag := '';
	v_collected_amount udd_amount := 0;
	v_adjust_amount udd_amount := 0;
	
begin
   
	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- Invoice No Validation
	if _inv_no = ''
	then
		v_err_code := v_err_code || 'VB01SADCUX_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB01SADCUX_001', _lang_code) || v_new_line;	
	end if;	
	
	-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code = _prod_code 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
	-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and master_code = _grade_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;	
	
	-- Sale qty Validation
	if _sale_qty <= 0 then
		v_err_code := v_err_code || 'VB01SADCUX_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_002', _lang_code) || v_new_line;		
	end if;
	
	-- Invoice qty Validation
	if _inv_qty <= 0 then
		v_err_code := v_err_code || 'VB01SADCUX_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_003', _lang_code) || v_new_line;		
	end if;

	-- Adjust qty Validation
	if  _adjust_qty > _sale_qty   then
		v_err_code := v_err_code || 'VB01SADCUX_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_004', _lang_code) || v_new_line;		
	end if;
	
	-- Adjust qty Validation
	if  _adjust_qty <= 0   then
		v_err_code := v_err_code || 'VB01SADCUX_011' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_011', _lang_code) || v_new_line;		
	end if;
	
	-- Sale Amount Validation
	if _sale_amount  <= 0 then
		v_err_code := v_err_code || 'VB01SADCUX_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_005', _lang_code) || v_new_line;		
	end if;
	
	-- Invoice amount Validation
	if  _inv_amount <= 0   then
		v_err_code := v_err_code || 'VB01SADCUX_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_006', _lang_code) || v_new_line;		
	end if;
	
	-- Rate Validation
	if  _sale_rate <= 0   then
		v_err_code := v_err_code || 'VB01SADCUX_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_007', _lang_code) || v_new_line;		
	end if;
	
	-- Min rec count Validation
	if  _min_rec_slno <= 0   then
		v_err_code := v_err_code || 'VB01SADCUX_009' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_009', _lang_code) || v_new_line;		
	end if;
	
	-- Max rec count Validation
	if  _max_rec_slno <= 0   then
		v_err_code := v_err_code || 'VB01SADCUX_010' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_010', _lang_code) || v_new_line;		
	end if;
	
	if _inv_date > _adjust_date then
		v_err_code := v_err_code || 'VB01SADCUX_014' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_014', _lang_code) || v_new_line;		
	end if;
	
	-- invoice date validation
	if _inv_date = null then
		v_err_code := v_err_code || 'VB01SADCUX_012' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_012', _lang_code) || v_new_line;		
	end if;

	-- Get sale calc flag 
	select 	payment_calc_flag into v_payment_calc_flag
	from 	pg_trn_tsaleproduct 
	where 	pg_id =  _pg_id 
	and 	inv_no = _inv_no
	and 	inv_date = _inv_date
	and 	rec_slno = _min_rec_slno
	and 	status_code = 'A';

	-- Record count Validation
	if  _record_count <= 0   then
		v_err_code := v_err_code || 'VB01SADCUX_008' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_008', _lang_code) || v_new_line;		
	end if;

	if _record_count > 1 or v_payment_calc_flag = 'Y' then
		v_adjust_amount := _adjust_qty * _sale_rate;
		_adjust_qty := _adjust_qty - _inv_qty;
		v_rec_slno := _max_rec_slno + 1;
	end if;
	_sale_base_amount := _adjust_qty * _sale_rate;
	_sale_amount := _sale_base_amount;
	
	-- Get Collected amount
	select collected_amount into v_collected_amount
	from 	pg_trn_tsale 
	where 	pg_id = _pg_id 
	and   	inv_no = _inv_no
	and   	status_code = 'A';
	
	v_collected_amount := coalesce(v_collected_amount,0);
	
	if v_collected_amount > v_adjust_amount then
		v_err_code := v_err_code || 'VB01SADCUX_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_015', _lang_code) || v_new_line;		
	end if;
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where 	lang_code   = _lang_code
				   and   	status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if  _record_count > 1 or v_payment_calc_flag = 'Y' then 
			insert into pg_trn_tsaleproduct (
											 saleprod_gid,
											 pg_id,
											 inv_date,
											 inv_no,
											 rec_slno,
											 prod_type_code,
											 prod_code,
											 grade_code,
											 sale_rate,
											 sale_qty,
											 sale_base_amount,
											 sale_amount,
											 payment_calc_flag,
											 status_code,
											 inv_qty,
											 adjust_type_code,
											 adjust_date,
											 stock_adj_flag,
											 created_date,
											 created_by
											)
											values
											(
											 _saleprod_gid,
											 _pg_id,
											 _inv_date,
											 _inv_no,
											 v_rec_slno,
											 _prod_type_code,
											 _prod_code,
											 _grade_code,
											 _sale_rate,
											 0,
											 _sale_base_amount,
											 _sale_amount,
											 'N',
											 'A',
											 _adjust_qty,
											 _adjust_type_code,
											 _adjust_date,
											 'Y',	
											 now(),
											 _user_code
											)returning saleprod_gid into _saleprod_gid;

					v_succ_code := 'SB00CMNCMN_001';	
					
		elseif v_payment_calc_flag = 'N' then
				update 	pg_trn_tsaleproduct 
				set 	inv_qty = _adjust_qty,
						sale_base_amount = _sale_base_amount,
						sale_amount = _sale_amount
				where   pg_id = _pg_id
				and		inv_no = _inv_no
				and 	inv_date = _inv_date
-- 				and 	rec_slno = _min_rec_slno
				and  	prod_type_code = _prod_type_code
				and 	prod_code = _prod_code
				and     grade_code = _grade_code
				and 	status_code = 'A';

				v_succ_code := 'SB00CMNCMN_002';
	else
		v_err_code := v_err_code || 'VB01SADCUX_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SADCUX_013', _lang_code) || v_new_line;
		
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	select 	sum(sale_amount) into v_sale_amount
	from 	pg_trn_tsaleproduct
	where 	pg_id =  _pg_id 
	and 	inv_no = _inv_no
	and 	inv_date = _inv_date
	and 	status_code = 'A';

	update pg_trn_tsale set inv_amount = v_sale_amount
	where 	pg_id =  _pg_id 
	and 	inv_no = _inv_no
	and 	inv_date = _inv_date
	and 	status_code = 'A';
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_salejson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B01SALCUX
	*/
	v_colrec record;
	v_updated_date udd_datetime;
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											sale_gid udd_int,
											pg_id udd_code,
											inv_date udd_date,
											inv_no udd_code,
											buyer_name udd_desc,
											collected_amount udd_amount,
											inv_amount udd_amount,
											sync_status_code udd_code,
											status_code udd_code,
											created_date udd_datetime,
											created_by udd_user,
											updated_date udd_text,
											updated_by udd_user,
											buyer_regular_flag udd_code,
											buyer_mobile_no udd_mobile
										)
		  loop
		 	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;

		      insert into pg_trn_tsale  (
			  								sale_gid,
			  								pg_id,
			  								inv_date,
											inv_no,
											buyer_name,
											collected_amount,
				  							inv_amount,
											sync_status_code,
											status_code,
											created_date,
											created_by,
											updated_date,
											updated_by,
											buyer_regular_flag,
											buyer_mobile_no
			  							)
								values  (
											v_colrec.sale_gid,
			  								v_colrec.pg_id,
			  								v_colrec.inv_date,
											v_colrec.inv_no,
											v_colrec.buyer_name,
											v_colrec.collected_amount,
											v_colrec.inv_amount,
											v_colrec.sync_status_code,
											v_colrec.status_code,
											v_colrec.created_date,
											v_colrec.created_by,
											v_updated_date,
											v_colrec.updated_by,
											v_colrec.buyer_regular_flag,
											v_colrec.buyer_mobile_no
										)
										
				on conflict (
								pg_id,
								inv_date,
								inv_no
							)
							do update set   sale_gid			=	v_colrec.sale_gid,
			  								pg_id				=	v_colrec.pg_id,
			  								inv_date			=	v_colrec.inv_date,
											inv_no				=	v_colrec.inv_no,
											buyer_name			=	v_colrec.buyer_name,
											collected_amount	=	v_colrec.collected_amount,
											inv_amount			=	v_colrec.inv_amount,
											sync_status_code	=	v_colrec.sync_status_code,
											status_code			=	v_colrec.status_code,
											updated_date		=	v_updated_date,
											updated_by			=	v_colrec.updated_by,
											buyer_regular_flag	=	v_colrec.buyer_regular_flag,
											buyer_mobile_no		=	v_colrec.buyer_mobile_no;
						END LOOP;
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_saleproduct(INOUT _saleprod_gid udd_int, _pg_id udd_code, _inv_date udd_date, _inv_no udd_code, _rec_slno udd_int, _prod_type_code udd_code, _prod_code udd_code, _grade_code udd_code, _sale_rate udd_rate, _sale_qty udd_qty, _inv_qty udd_qty, _sale_base_amount udd_amount, _hsn_code udd_code, _cgst_rate udd_rate, _sgst_rate udd_rate, _cgst_amount udd_amount, _sgst_amount udd_amount, _sale_amount udd_amount, _sale_remark udd_text, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		SP Code      : B06SAPCUD

		Created By   : Mangai
		Created Date : 05-02-2022
		
		Updated By : Vijayavel J
		Updated Date : 17-04-2022
		
		Updated By : Mohan s/Vijayavel
		Updated Date : 08-08-2022
		
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	
	v_sale_qty 			udd_qty 	:= 0;
	v_inv_qty			udd_qty 	:= 0;
	v_param_sale_qty 	udd_qty 	:= 0;
	v_sale_rate 		udd_rate	:= 0;
	v_sale_base_amount 	udd_amount 	:= 0;
	v_cgst_amount 		udd_amount 	:= 0;
	v_sgst_amount 		udd_amount 	:= 0;
	v_sale_amount 		udd_amount 	:= 0;
	
	v_rec_slno 	udd_int		:= 0;
	v_stock_adj_flag udd_flag	:= 'Y';
	v_stock_adj_flag1 udd_flag	:= '';
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
    			   where pg_id     = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	

-- Invoice Date Validation
	if _inv_date isnull
	then
		v_err_code := v_err_code || 'VB06SAPCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SAPCUD_001', _lang_code) || v_new_line;
	end if;	
	
-- Invoice No Validation
	if _inv_no = ''
	then
		v_err_code := v_err_code || 'VB06SAPCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SAPCUD_002', _lang_code) || v_new_line;
	end if;	
	
-- Record SlNo Validation
	if _rec_slno  < 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SAPCUD_003', _lang_code) || v_new_line;
	end if;	
	
-- Product Type Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_PROD_TYPE' 
				   and master_code = _prod_type_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;		
	end if;

-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code = _prod_code 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and master_code = _grade_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;	
	
-- Sale Rate Validation
	if _sale_rate <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_004', _lang_code) || v_new_line;		
	end if;
	
-- Sale Quantity Validation
	if _sale_qty <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_005', _lang_code) || v_new_line;		
	end if;
	
-- Invoice Quantity Validation
	if _inv_qty <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_009 ' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_009 ', _lang_code) || v_new_line;		
	end if;
	
-- Sale Base Amount Validation
	_sale_base_amount := _inv_qty * _sale_rate;
	
	if _sale_base_amount <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_006', _lang_code) || v_new_line;		
	end if;
	
-- Sale Amount validation
	_sale_amount := _sale_base_amount + _cgst_amount + _sgst_amount;

	if _sale_amount <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_007', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code = _lang_code
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if _mode_flag = 'U' then 
		-- Getting sale qty old value
		if exists(select '*' from pg_trn_tsaleproduct
		   where	pg_id = _pg_id
		   and 		inv_date = _inv_date
		   and 		inv_no = _inv_no
		   and 		rec_slno = _rec_slno
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code) then
		   
		   select 	sale_qty,inv_qty,sale_rate,stock_adj_flag 
		   into 	v_sale_qty, v_inv_qty,v_sale_rate, v_stock_adj_flag1
		   from 	pg_trn_tsaleproduct
		   where	pg_id = _pg_id
		   and 		inv_date = _inv_date
		   and 		inv_no = _inv_no
		   and 		rec_slno = _rec_slno
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code;

		   v_sale_rate := coalesce(v_sale_rate,0);
		   v_sale_qty := coalesce(v_sale_qty,0);
		   v_inv_qty := coalesce(v_inv_qty,0);
		   v_stock_adj_flag1 := coalesce(v_stock_adj_flag1,'');
	   end if;
	   
	   if v_stock_adj_flag1 <> 'Y' then
	   		v_err_code := v_err_code || 'VB06SAPCUD_008' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_008', _lang_code) || v_new_line;		
	   end if;

	   select 	max(rec_slno) into v_rec_slno
	   from 	pg_trn_tsaleproduct
	   where	pg_id = _pg_id
	   and 		inv_date = _inv_date
	   and 		inv_no = _inv_no;

	   if (_sale_qty <> 0 and _sale_qty <> v_sale_qty) or 
		  (_inv_qty <> 0 and _inv_qty <> v_inv_qty) or 
	   	  (_sale_rate <> v_sale_rate and v_sale_rate <> 0) then
		  
			_saleprod_gid := v_rec_slno;
			_rec_slno  := v_rec_slno + 1;
			
			v_param_sale_qty := _sale_qty;
	   		_sale_qty  		 := _sale_qty - v_sale_qty;
			_inv_qty		 := _inv_qty  - v_inv_qty;
			
			_mode_flag := 'I';

			_sale_base_amount 	:= _sale_base_amount - v_sale_base_amount;
			_cgst_amount 		:= _cgst_amount - v_cgst_amount;
			_sgst_amount 		:= _sgst_amount - v_sgst_amount;
			_sale_amount 		:= _sale_amount - v_sale_amount;

			if _sale_rate <> v_sale_rate then
				if  _sale_qty = 0 then
					_sale_qty	:= v_sale_qty;
					_sale_rate 	:= _sale_rate - v_sale_rate;
					v_stock_adj_flag := 'N';
				else
					_sale_rate  := ((v_param_sale_qty*_sale_rate)-(v_sale_qty*v_sale_rate))/_sale_qty;
				end if;
			else
				if _inv_qty <> v_inv_qty and _sale_qty = v_sale_qty then
					v_stock_adj_flag := 'N';
					
					update pg_trn_tsaleproduct
						set		inv_qty			= _inv_qty,
								sale_remark			= _sale_remark,
								updated_date		= now(),
								updated_by			= _user_code
					   where	pg_id = _pg_id
					   and 		inv_date = _inv_date
					   and 		inv_no = _inv_no
					   and 		rec_slno = _rec_slno
					   and 		prod_code = _prod_code
					   and 		grade_code = _grade_code;
				end if;
			end if;
	   end if; 
	end if;
	_inv_qty := _sale_qty;
	_sale_base_amount := _inv_qty * _sale_rate;
	_sale_amount := _inv_qty * _sale_rate + _cgst_amount + _sgst_amount;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tsaleproduct
				  where saleprod_gid = _saleprod_gid)
			then
				delete from pg_trn_tsaleproduct
				where saleprod_gid = _saleprod_gid;
			v_succ_code := 'SB06SAPCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif (_mode_flag = 'I') then
		if not exists (select * from pg_trn_tsaleproduct
				      	   where	pg_id = _pg_id
						   and 		inv_date = _inv_date
						   and 		inv_no = _inv_no
						   and 		rec_slno = _rec_slno
						   and 		prod_code = _prod_code
						   and 		grade_code = _grade_code)
		 then
			insert into pg_trn_tsaleproduct(
					saleprod_gid,
					pg_id,
					inv_date,
					inv_no,
					rec_slno,
					prod_type_code,
					prod_code,
					grade_code,
					sale_rate,
					sale_qty,
					inv_qty,
					sale_base_amount,
					hsn_code,
					cgst_rate,
					sgst_rate,
					cgst_amount,
					sgst_amount,
					sale_amount,
				    sale_remark,
					stock_adj_flag,
					created_date,
					created_by
					)
			values (
					_saleprod_gid,
					_pg_id,
					_inv_date,
					_inv_no,
					_rec_slno,
					_prod_type_code,
					_prod_code,
					_grade_code,
					_sale_rate,
					_sale_qty,
					_inv_qty,
					_sale_base_amount,
					_hsn_code,
					_cgst_rate,
					_sgst_rate,
					_cgst_amount,
					_sgst_amount,
					_sale_amount,
					_sale_remark,
					v_stock_adj_flag,
					now(),
					_user_code) returning saleprod_gid into _saleprod_gid;
				v_succ_code := 'SB06SAPCUD_001';
				
				select 	sum(sale_base_amount) into v_sale_base_amount
				from 	pg_trn_tsaleproduct
				where 	pg_id =  _pg_id 
				and 	inv_no = _inv_no
				and 	inv_date = _inv_date;
				
				update pg_trn_tsale set inv_amount = v_sale_base_amount
				where 	pg_id =  _pg_id 
				and 	inv_no = _inv_no
				and 	inv_date = _inv_date
				and 	status_code = 'A';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif (_mode_flag = 'U') then
		if exists (select * from pg_trn_tsaleproduct
				   where	pg_id = _pg_id
				   and 		inv_date = _inv_date
				   and 		inv_no = _inv_no
				   and 		rec_slno = _rec_slno
				   and 		prod_code = _prod_code
				   and 		grade_code = _grade_code)
		then
		update pg_trn_tsaleproduct
			set		--pg_id				= _pg_id,
					--inv_date			= _inv_date,
					--inv_no				= _inv_no,
					--rec_slno			= _rec_slno,
					--prod_type_code		= _prod_type_code,
					--prod_code			= _prod_code,
					--grade_code			= _grade_code,
					--sale_rate			= _sale_rate,
					--sale_qty			= _sale_qty,
					--sale_base_amount	= _sale_base_amount,
					--hsn_code			= _hsn_code,
					--cgst_rate			= _cgst_rate,
					--sgst_rate			= _sgst_rate,
					--cgst_amount			= _cgst_amount,
					--sgst_amount			= _sgst_amount,
					--sale_amount			= _sale_amount,
					sale_remark			= _sale_remark,
					updated_date		= now(),
					updated_by			= _user_code
		   where	pg_id = _pg_id
		   and 		inv_date = _inv_date
		   and 		inv_no = _inv_no
		   and 		rec_slno = _rec_slno
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code;
		 v_succ_code	:= 'SB06SAPCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
		 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	 
	
	if exists (	select	count(*) from pg_trn_tsaleproduct
			    where		pg_id = _pg_id
			    and 		inv_date = _inv_date
			    and 		inv_no = _inv_no
			    and 		rec_slno = _rec_slno
			    and 		prod_code = _prod_code
			    and 		grade_code = _grade_code
				group	by pg_id,inv_date,inv_no,rec_slno
				having	count('*') > 1) 
	then
		-- pg id, inv_date, inv_no and rec_slno cannot be duplicated
		v_err_code := v_err_code || 'EB06SAPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06SAPCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_saleproduct(INOUT _saleprod_gid udd_int, _pg_id udd_code, _inv_date udd_date, _inv_no udd_code, _rec_slno udd_int, _prod_type_code udd_code, _prod_code udd_code, _grade_code udd_code, _sale_rate udd_rate, _sale_qty udd_qty, _sale_base_amount udd_amount, _hsn_code udd_code, _cgst_rate udd_rate, _sgst_rate udd_rate, _cgst_amount udd_amount, _sgst_amount udd_amount, _sale_amount udd_amount, _sale_remark udd_text, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 05-02-2022
		
		Updated By : Vijayavel J
		Updated Date : 17-04-2022
		
		SP Code      : B06SAPCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	
	v_sale_qty 			udd_qty 	:= 0;
	v_param_sale_qty 	udd_qty 	:= 0;
	v_sale_rate 		udd_rate	:= 0;
	v_sale_base_amount 	udd_amount 	:= 0;
	v_cgst_amount 		udd_amount 	:= 0;
	v_sgst_amount 		udd_amount 	:= 0;
	v_sale_amount 		udd_amount 	:= 0;
	
	v_rec_slno 	udd_int		:= 0;
	v_stock_adj_flag udd_flag	:= 'Y';
	v_stock_adj_flag1 udd_flag	:= '';
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
    			   where pg_id     = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	

-- Invoice Date Validation
	if _inv_date isnull
	then
		v_err_code := v_err_code || 'VB06SAPCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SAPCUD_001', _lang_code) || v_new_line;
	end if;	
	
-- Invoice No Validation
	if _inv_no = ''
	then
		v_err_code := v_err_code || 'VB06SAPCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SAPCUD_002', _lang_code) || v_new_line;
	end if;	
	
-- Record SlNo Validation
	if _rec_slno  < 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SAPCUD_003', _lang_code) || v_new_line;
	end if;	
	
-- Product Type Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_PROD_TYPE' 
				   and master_code = _prod_type_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;		
	end if;

-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code = _prod_code 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and master_code = _grade_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;	
	
-- Sale Rate Validation
	if _sale_rate <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_004', _lang_code) || v_new_line;		
	end if;
	
-- Sale Quantity Validation
	if _sale_qty <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_005', _lang_code) || v_new_line;		
	end if;
	
-- Sale Base Amount Validation
	_sale_base_amount := _sale_qty * _sale_rate;
	
	if _sale_base_amount <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_006', _lang_code) || v_new_line;		
	end if;
	
-- Sale Amount validation
	_sale_amount := _sale_base_amount + _cgst_amount + _sgst_amount;
	if _sale_amount <= 0
	then
		v_err_code := v_err_code || 'VB06SAPCUD_007' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_007', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code = _lang_code
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if _mode_flag = 'U' then 
		-- Getting sale qty old value
		if exists(select '*' from pg_trn_tsaleproduct
		   where	pg_id = _pg_id
		   and 		inv_date = _inv_date
		   and 		inv_no = _inv_no
		   and 		rec_slno = _rec_slno
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code) then
		   
		   select 	sale_qty,sale_rate,stock_adj_flag 
		   into 	v_sale_qty, v_sale_rate, v_stock_adj_flag1
		   from 	pg_trn_tsaleproduct
		   where	pg_id = _pg_id
		   and 		inv_date = _inv_date
		   and 		inv_no = _inv_no
		   and 		rec_slno = _rec_slno
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code;

		   v_sale_rate := coalesce(v_sale_rate,0);
		   v_sale_qty := coalesce(v_sale_qty,0);
		   v_stock_adj_flag1 := coalesce(v_stock_adj_flag1,'');
	   end if;
	   
	   if v_stock_adj_flag1 <> 'Y' then
	   		v_err_code := v_err_code || 'VB06SAPCUD_008' || ',';
			v_err_msg  := v_err_msg ||  fn_get_msg('VB06SAPCUD_008', _lang_code) || v_new_line;		
	   end if;

	   select 	max(rec_slno) into v_rec_slno
	   from 	pg_trn_tsaleproduct
	   where	pg_id = _pg_id
	   and 		inv_date = _inv_date
	   and 		inv_no = _inv_no;

	   if (_sale_qty <> 0 and _sale_qty <> v_sale_qty) or 
	   	  (_sale_rate <> v_sale_rate and v_sale_rate <> 0) then
		  
			_saleprod_gid := v_rec_slno;
			_rec_slno  := v_rec_slno + 1;
			
			v_param_sale_qty := _sale_qty;
	   		_sale_qty  		 := _sale_qty - v_sale_qty;
			
			_mode_flag := 'I';

			_sale_base_amount 	:= _sale_base_amount - v_sale_base_amount;
			_cgst_amount 		:= _cgst_amount - v_cgst_amount;
			_sgst_amount 		:= _sgst_amount - v_sgst_amount;
			_sale_amount 		:= _sale_amount - v_sale_amount;

			if _sale_rate <> v_sale_rate then
				if  _sale_qty = 0 then
					_sale_qty	:= v_sale_qty;
					_sale_rate 	:= _sale_rate - v_sale_rate;
					v_stock_adj_flag := 'N';
				else
					_sale_rate  := ((v_param_sale_qty*_sale_rate)-(v_sale_qty*v_sale_rate))/_sale_qty;
				end if;
			end if;
	   end if; 
	end if;
	
	_sale_base_amount := _sale_qty * _sale_rate;
	_sale_amount := _sale_qty * _sale_rate + _cgst_amount + _sgst_amount;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tsaleproduct
				  where saleprod_gid = _saleprod_gid)
			then
				delete from pg_trn_tsaleproduct
				where saleprod_gid = _saleprod_gid;
			v_succ_code := 'SB06SAPCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif (_mode_flag = 'I') then
		if not exists (select * from pg_trn_tsaleproduct
				      	   where	pg_id = _pg_id
						   and 		inv_date = _inv_date
						   and 		inv_no = _inv_no
						   and 		rec_slno = _rec_slno
						   and 		prod_code = _prod_code
						   and 		grade_code = _grade_code)
		 then
			insert into pg_trn_tsaleproduct(
					saleprod_gid,
					pg_id,
					inv_date,
					inv_no,
					rec_slno,
					prod_type_code,
					prod_code,
					grade_code,
					sale_rate,
					sale_qty,
					sale_base_amount,
					hsn_code,
					cgst_rate,
					sgst_rate,
					cgst_amount,
					sgst_amount,
					sale_amount,
				    sale_remark,
					stock_adj_flag,
					created_date,
					created_by
					)
			values (
					_saleprod_gid,
					_pg_id,
					_inv_date,
					_inv_no,
					_rec_slno,
					_prod_type_code,
					_prod_code,
					_grade_code,
					_sale_rate,
					_sale_qty,
					_sale_base_amount,
					_hsn_code,
					_cgst_rate,
					_sgst_rate,
					_cgst_amount,
					_sgst_amount,
					_sale_amount,
					_sale_remark,
					v_stock_adj_flag,
					now(),
					_user_code) returning saleprod_gid into _saleprod_gid;
				v_succ_code := 'SB06SAPCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif (_mode_flag = 'U') then
		if exists (select * from pg_trn_tsaleproduct
				   where	pg_id = _pg_id
				   and 		inv_date = _inv_date
				   and 		inv_no = _inv_no
				   and 		rec_slno = _rec_slno
				   and 		prod_code = _prod_code
				   and 		grade_code = _grade_code)
		then
		update pg_trn_tsaleproduct
			set		--pg_id				= _pg_id,
					--inv_date			= _inv_date,
					--inv_no				= _inv_no,
					--rec_slno			= _rec_slno,
					--prod_type_code		= _prod_type_code,
					--prod_code			= _prod_code,
					--grade_code			= _grade_code,
					--sale_rate			= _sale_rate,
					--sale_qty			= _sale_qty,
					--sale_base_amount	= _sale_base_amount,
					--hsn_code			= _hsn_code,
					--cgst_rate			= _cgst_rate,
					--sgst_rate			= _sgst_rate,
					--cgst_amount			= _cgst_amount,
					--sgst_amount			= _sgst_amount,
					--sale_amount			= _sale_amount,
					sale_remark			= _sale_remark,
					updated_date		= now(),
					updated_by			= _user_code
		   where	pg_id = _pg_id
		   and 		inv_date = _inv_date
		   and 		inv_no = _inv_no
		   and 		rec_slno = _rec_slno
		   and 		prod_code = _prod_code
		   and 		grade_code = _grade_code;
		 v_succ_code	:= 'SB06SAPCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
		 v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	 
	
	if exists (	select	count(*) from pg_trn_tsaleproduct
			    where		pg_id = _pg_id
			    and 		inv_date = _inv_date
			    and 		inv_no = _inv_no
			    and 		rec_slno = _rec_slno
			    and 		prod_code = _prod_code
			    and 		grade_code = _grade_code
				group	by pg_id,inv_date,inv_no,rec_slno
				having	count('*') > 1) 
	then
		-- pg id, inv_date, inv_no and rec_slno cannot be duplicated
		v_err_code := v_err_code || 'EB06SAPCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06SAPCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_saleproductjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B01SAPCUX
	*/
	v_colrec record;
	v_updated_date udd_datetime;
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											saleprod_gid udd_int,
											pg_id udd_code,
											inv_date udd_date,
											inv_no udd_code,
											rec_slno udd_int,
											prod_type_code udd_code,
											prod_code udd_code,
											grade_code udd_code,
											sale_rate udd_rate,
											sale_qty udd_qty,
											inv_qty udd_qty,
											sale_base_amount udd_amount,
											hsn_code udd_code,
											cgst_rate udd_rate,
											sgst_rate udd_rate,
											cgst_amount udd_amount,
											sgst_amount udd_amount,
											sale_amount udd_amount,
											created_date udd_datetime,
											created_by udd_user,
											updated_date udd_text,
											updated_by udd_user
										)
		  loop
		  	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
			  v_colrec.sale_amount := v_colrec.sale_base_amount + v_colrec.cgst_amount + v_colrec.sgst_amount;
		      insert into pg_trn_tsaleproduct(
			  								saleprod_gid,
			  								pg_id,
			  								inv_date,
											inv_no,
											rec_slno,
											prod_type_code,
				  							prod_code,
				  							grade_code,
				  							sale_rate,
				  							sale_qty,
				  							inv_qty,
											sale_base_amount,
											hsn_code,
											cgst_rate,
											sgst_rate,
											cgst_amount,
											sgst_amount,
											sale_amount,
											created_date,
											created_by,
											updated_date,
											updated_by
			  							)
								values  (
											v_colrec.saleprod_gid,
			  								v_colrec.pg_id,
			  								v_colrec.inv_date,
											v_colrec.inv_no,
											v_colrec.rec_slno,
											v_colrec.prod_type_code,
											v_colrec.prod_code,
											v_colrec.grade_code,
											v_colrec.sale_rate,
											v_colrec.sale_qty,
											v_colrec.inv_qty,
											v_colrec.sale_base_amount,
											v_colrec.hsn_code,
											v_colrec.cgst_rate,
											v_colrec.sgst_rate,
											v_colrec.cgst_amount,
											v_colrec.sgst_amount,
											v_colrec.sale_amount,
											v_colrec.created_date,
											v_colrec.created_by,
											v_updated_date,
											v_colrec.updated_by
										)
										
				on conflict (
								pg_id,
								inv_date,
								inv_no,
								rec_slno,
								prod_code,
								grade_code
							)
							do update set   saleprod_gid		=	v_colrec.saleprod_gid,
			  								pg_id				=	v_colrec.pg_id,
			  								inv_date			=	v_colrec.inv_date,
											inv_no				=	v_colrec.inv_no,
											rec_slno			=	v_colrec.rec_slno,	
											prod_type_code		=	v_colrec.prod_type_code,
											prod_code			=	v_colrec.prod_code,
											grade_code			=	v_colrec.grade_code,
											sale_rate			=	v_colrec.sale_rate,
											sale_qty			=	v_colrec.sale_qty,
											inv_qty				=	v_colrec.inv_qty,
											sale_base_amount	=	v_colrec.sale_base_amount,
											hsn_code			=	v_colrec.hsn_code,
											cgst_rate			=	v_colrec.cgst_rate,
											sgst_rate			=	v_colrec.sgst_rate,
											cgst_amount			=	v_colrec.cgst_amount,
											sgst_amount			=	v_colrec.sgst_amount,
											sale_amount			=	v_colrec.sale_amount,
											updated_date		=	v_updated_date,
											updated_by			=	v_colrec.updated_by;
						END LOOP;
	END
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_screen(INOUT _screen_gid udd_int, _screen_code udd_code, _screen_name udd_desc, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01SCRCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	-- screen code validation
	if _screen_code = '' then
		v_err_code := v_err_code || 'VB01SCRCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SCRCUD_001', _lang_code) || v_new_line;
	end if;
	
	-- screen name validation
	if _screen_name = '' then
		v_err_code := v_err_code || 'VB01SCRCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SCRCUD_002', _lang_code) || v_new_line;
	end if;
	
	-- status code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_STATUS'
				   and 		master_code = _status_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;	
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tscreen
				  where 	screen_gid 	= _screen_gid 
				  and 		status_code = 'A'
				 ) then
			Update 	core_mst_tscreen
			set		status_code 	= 'I',
					updated_by 		= _user_code,
					updated_date 	= now()					
			where 	screen_gid 		= _screen_gid 
			and 	status_code 	= 'A';
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tscreen
					  where		screen_code = _screen_code
					  and 		status_code = 'A'
					 ) then
			insert into core_mst_tscreen 
			(
				screen_code,
				screen_name,
				status_code,
				created_by,
				created_date			
			)
			values
			(
				_screen_code,
				_screen_name,
				_status_code,
				_user_code,
				now()
				
			) returning screen_gid into _screen_gid;			
			v_succ_code := 'SB00CMNCMN_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;	
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tscreen
				   where	screen_gid 	= _screen_gid 
				   and 		status_code = 'A'
				   ) then
			update	core_mst_tscreen 
			set	    screen_name			= _screen_name,
					status_code 		= _status_code,
					updated_by 			= _user_code,
					updated_date 		= now()					
			where 	screen_gid			= _screen_gid
			and 	status_code 		= 'A';
			
			v_succ_code := 'SB00CMNCMN_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;		
	end if;
	
	if exists (	select	count(*)
				from 	core_mst_tscreen
			    where 	screen_code 	= _screen_code 
				group	by screen_code
				having	count('*') > 1) 
	then
		-- screen code  cannot be duplicated
		v_err_code := v_err_code || 'VB01SCRCUD_003';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('VB01SCRCUD_003', _lang_code),_screen_code);
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
			
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_screendata(INOUT _screendata_gid udd_int, _screen_code udd_code, _langcode udd_code, _ctrl_type_code udd_code, _ctrl_id udd_desc, _data_field udd_desc, _label_desc udd_desc, _tooltip_desc udd_desc, _default_label_desc udd_desc, _default_tooltip_desc udd_desc, _ctrl_slno udd_int, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Muthu
		Created Date : 04-01-2022
		SP Code : B01SCDCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);	
begin
	-- validation
	
	-- screen code validation
	if not exists (select 	* 
				   from 	core_mst_tscreen 
				   where 	screen_code = _screen_code				  
				  ) then
		v_err_code := v_err_code || 'VB01SCDCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SCDCUD_001', _lang_code)|| v_new_line;
	end if;
	
	-- ctrl_type_code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_CTRL_TYPE'
				   and 		master_code = _ctrl_type_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB01SCDCUD_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SCDCUD_002', _lang_code) || v_new_line;	
	end if;
	
	-- ctrl id validation
	if _ctrl_id = '' then
		v_err_code := v_err_code || 'VB01SCDCUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB01SCDCUD_003', _lang_code) || v_new_line;
	end if;

	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;
	end if;
	
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag  = 'D' then
		if exists(select 	* 
				  from 		core_mst_tscreendata
				  where 	screendata_gid 	= _screendata_gid 				 
				 ) then
				 
			Delete from 	core_mst_tscreendata
			where		    screendata_gid = _screendata_gid;
			
			v_succ_code := 'SB00CMNCMN_003';
		else
			-- Record not in active status to be deleted
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elsif ( _mode_flag = 'I' ) then
		if not exists(select 	* 
					  from		core_mst_tscreendata
					  where		screen_code = _screen_code
					  and       screendata_gid = _screendata_gid
					 ) then
			insert into core_mst_tscreendata 
			(
				screen_code,
				lang_code,
				ctrl_type_code,
				ctrl_id,
				data_field,
				label_desc,
				tooltip_desc,
				default_label_desc,				
				default_tooltip_desc,
				ctrl_slno,				
				created_by,
				created_date			
			)
			values
			(
				_screen_code,
				_langcode,
				_ctrl_type_code,
				_ctrl_id,
				_data_field,
				_label_desc,
				_tooltip_desc,
				_default_label_desc,				
				_default_tooltip_desc,
				_ctrl_slno,
				_user_code,
				now()
				
			) returning screendata_gid into _screendata_gid;			
			v_succ_code := 'SB00CMNCMN_001';			
		else
			-- Record already exists
			v_err_code := v_err_code || 'EB00CMNCMN_002';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;	
	elsif (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	core_mst_tscreendata
				   where	screendata_gid 	= _screendata_gid 
				   ) then
			update	core_mst_tscreendata 
			set	    lang_code				= _langcode,
					ctrl_type_code			= _ctrl_type_code,
					ctrl_id					= _ctrl_id,
					data_field				= _data_field,
					label_desc				= _label_desc,
					tooltip_desc			= _tooltip_desc,
					default_label_desc		= _default_label_desc,
					default_tooltip_desc	= _default_tooltip_desc,
					ctrl_slno				= _ctrl_slno,
					updated_by 				= _user_code,
					updated_date 			= now()					
			where 	screendata_gid			= _screendata_gid;
			
			
			v_succ_code := 'SB00CMNCMN_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;		
	end if;
	
	if exists (	select	count(*) from core_mst_tscreendata
			    where 	screen_code = _screen_code 
			    and 	lang_code    = _langcode
			    and     ctrl_id     = _ctrl_id
			    and     data_field  = _data_field 
				group	by screen_code, lang_code, ctrl_id, data_field
				having	count('*') > 1) 
	then
		-- screen_code, ctrl_id, data_field and lang_code cannot be duplicated
		v_err_code := v_err_code || 'EB01SCDCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB01SCDCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
			
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_session(INOUT _session_gid udd_int, _pg_id udd_code, _session_id udd_code, _session_date udd_date, _collpoint_no udd_int, _latitude_code udd_code, _longitude_code udd_code, _start_timestamp udd_datetime, _end_timestamp udd_datetime, _sync_status_code udd_code, _status_code udd_code, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
    /*
		Created By : Mangai
		Created Date : 03-02-2022
		SP Code : B06SESCUD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- Session ID Validation
	if _session_id = ''
	then
		v_err_code := v_err_code || 'VB06SESCUD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SESCUD_001', _lang_code) || v_new_line;	
	end if;	
	
-- Session Date Validation
	if _session_date isnull
	then
		v_err_code := v_err_code || 'VB06SESCUD_002' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SESCUD_002', _lang_code) || v_new_line;	 
	end if;

-- Collection Point No Validation
	if not exists (select * from pg_mst_tcollectionpoint
				   where collpoint_no = _collpoint_no)
	then
		v_err_code := v_err_code || 'VB06SESCUD_003' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SESCUD_003', _lang_code) || v_new_line;	
	end if;	

-- Start TimeStamp Validation
	if _start_timestamp isnull
	then
		v_err_code := v_err_code || 'VB06SESCUD_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB06SESCUD_004', _lang_code) || v_new_line;	
	end if;

-- Sync Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_SYNC_STATUS' 
				   and   master_code = _sync_status_code 
				   and   status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_013' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_013', _lang_code) || v_new_line;		
	end if;
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code   = 'QCD_STATUS' 
				   and   master_code   = _status_code 
				   and   status_code   = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code = _lang_code
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
		
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tsession
				  where session_gid = _session_gid
				  and status_code   <> 'I')
			then
			update pg_trn_tsession 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where session_gid 	= _session_gid
					and	pg_id		= _pg_id
					and status_code	<> 'I';
			v_succ_code := 'SB06SESCUD_003';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tsession
				   where session_gid = _session_gid
				   and	 pg_id	     = _pg_id)
		 then
			insert into pg_trn_tsession
			(
				pg_id,
				session_id,
				session_date,
				collpoint_no,
				latitude_code,
				longitude_code,
				start_timestamp,
				end_timestamp,
				sync_status_code,
				status_code,
				created_date,
				created_by
			)
			values
			(
				_pg_id,
				_session_id,
				_session_date,
				_collpoint_no,
				_latitude_code,
				_longitude_code,
				_start_timestamp,
				_end_timestamp,
				_sync_status_code,
				_status_code,
				now(),
				_user_code
			  ) returning session_gid into _session_gid;
			  v_succ_code := 'SB06SESCUD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	elseif _mode_flag = 'U' then
		if exists (select * from pg_trn_tsession
				   where session_gid   = _session_gid
				   and status_code     <> 'I' )
		then
		update pg_trn_tsession
		set		pg_id				=	_pg_id,
				session_id			=	_session_id,
				session_date		=	_session_date,
				collpoint_no		=	_collpoint_no,
				latitude_code		=	_latitude_code,
				longitude_code		=	_longitude_code,
				start_timestamp		=	_start_timestamp,
				end_timestamp		=	_end_timestamp,
				sync_status_code	=	_sync_status_code,
				status_code			=	_status_code,
				updated_date		=	now(),
				updated_by			=	_user_code
		 where  session_gid			=	_session_gid
		 and	status_code			<>	'I';
		 v_succ_code	:= 'SB06SESCUD_002';
	else
		 v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if exists (	select	count(*) from pg_trn_tsession
			    where 	pg_id      = _pg_id 
			    and 	session_id = _session_id
				group	by pg_id, session_id
				having	count('*') > 1) 
	then
		-- pg id and session id cannot be duplicated
		v_err_code := v_err_code || 'EB06SESCUD_001';
		v_err_msg  := v_err_msg ||  FORMAT(fn_get_msg('EB06SESCUD_001', _lang_code));	
		
		raise exception '%',v_err_code || '-' || v_err_msg;
	else
		_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if; 
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_sessionjson(_jsonquery udd_jsonb)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 26-02-2022
		SP Code : B01SESCUX
	*/
	
	v_colrec record;
	v_updated_date udd_datetime;

begin 
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
													(
														session_gid udd_int,
														pg_id udd_code,
														session_id udd_code,
														session_date udd_date,
														collpoint_no udd_int,
														latitude_code udd_code,
														longitude_code udd_code,
														start_timestamp udd_date,
														end_timestamp udd_date,
														sync_status_code udd_code,
														status_code udd_code,
														created_date udd_date,
														created_by udd_code,
														updated_date udd_text,
														updated_by udd_code
														) 
												
			LOOP 
			
			 select	 fn_text_todatetime(v_colrec.updated_date) 
			 into 	 v_updated_date;
			 
			insert into pg_trn_tsession (
														session_gid ,
														pg_id ,
														session_id ,
														session_date ,
														collpoint_no ,
														latitude_code ,
														longitude_code ,
														start_timestamp ,
														end_timestamp ,
														sync_status_code ,
														status_code ,
														created_date ,
														created_by ,
														updated_date ,
														updated_by 
													)
										values		(
														v_colrec.session_gid ,
														v_colrec.pg_id ,
														v_colrec.session_id ,
														v_colrec.session_date ,
														v_colrec.collpoint_no ,
														v_colrec.latitude_code ,
														v_colrec.longitude_code ,
														v_colrec.start_timestamp ,
														v_colrec.end_timestamp ,
														v_colrec.sync_status_code ,
														v_colrec.status_code, 
														v_colrec.created_date, 
														v_colrec.created_by, 
														v_updated_date, 
														v_colrec.updated_by 
													)
						on CONFLICT ( pg_id,
									  session_id)  
									 do update set  session_gid = v_colrec.session_gid,
													pg_id = v_colrec.pg_id,
													session_id = v_colrec.session_id,
													session_date = v_colrec.session_date,
													collpoint_no = v_colrec.collpoint_no,
													latitude_code = v_colrec.latitude_code,
													longitude_code = v_colrec.longitude_code,
													start_timestamp = v_colrec.start_timestamp,
													end_timestamp = v_colrec.end_timestamp,
													sync_status_code = v_colrec.sync_status_code,
													status_code = v_colrec.status_code,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;

			END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_shgprofilejson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By   : Mangai
		Created Date : 26-02-2022
		SP Code      : B01SHPCUX
	*/
	v_colrec record;
	v_updated_date timestamp;
	v_created_date timestamp;
	
begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items 
	 									(
											shg_id 				integer,
											state_id 			integer,
											district_id 		integer,
											block_id 			integer,
											panchayat_id 		integer,
											village_id 			integer,
											shg_code 		    varchar(22),
											shg_name 			varchar(80),
											shg_type_code 		smallint,
											language_id 		varchar(2),
											shg_name_local 		varchar(120),
											parent_cbo_code 	bigint,
											parent_cbo_type 	smallint,
											is_active 			boolean,
											activation_status 	smallint,
											uploaded_by 		varchar(100),
											status 				smallint,
											promoter_code 		varchar(5),
											cbo_type			smallint,
											created_date		text,
											updated_date		text
										)
		  loop
		  	  select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
		  	  select fn_text_todatetime(v_colrec.created_date) into v_created_date;
			  		  
		      insert into shg_profile  (
			  								shg_id,
											state_id,
											district_id,
											block_id,
											panchayat_id,
											village_id,
											shg_code,
											shg_name,
											shg_type_code,
											language_id,
											shg_name_local,
											parent_cbo_code,
											parent_cbo_type,
											is_active,
											activation_status,
											uploaded_by,
											status,
											promoter_code,
											cbo_type,
				  							created_date,
				  							updated_date
				  
			  							)
								values  (											
			  								v_colrec.shg_id,
											v_colrec.state_id,
											v_colrec.district_id,
											v_colrec.block_id,
											v_colrec.panchayat_id,
											v_colrec.village_id,
											v_colrec.shg_code,
											v_colrec.shg_name,
											v_colrec.shg_type_code,
											v_colrec.language_id,
											v_colrec.shg_name_local,
											v_colrec.parent_cbo_code,
											v_colrec.parent_cbo_type,
											v_colrec.is_active,
											v_colrec.activation_status,
											v_colrec.uploaded_by,
											v_colrec.status,
											v_colrec.promoter_code,
											v_colrec.cbo_type,
											v_created_date,
											v_updated_date
										)
										
				on conflict (
								shg_id
							)
							do update set   shg_id 			= v_colrec.shg_id,
											state_id		= v_colrec.state_id,
											district_id		= v_colrec.district_id,
											block_id		= v_colrec.block_id,
											panchayat_id	= v_colrec.panchayat_id,
											village_id		= v_colrec.village_id,
											shg_code		= v_colrec.shg_code,
											shg_name		= v_colrec.shg_name,
											shg_type_code	= v_colrec.shg_type_code,
											language_id		= v_colrec.language_id,
											shg_name_local	= v_colrec.shg_name_local,
											parent_cbo_code	= v_colrec.parent_cbo_code,
											parent_cbo_type	= v_colrec.parent_cbo_type,
											is_active		= v_colrec.is_active,
											activation_status= v_colrec.activation_status,
											uploaded_by		= v_colrec.uploaded_by,
											status			= v_colrec.status,
											promoter_code	= v_colrec.promoter_code,
											cbo_type		= v_colrec.cbo_type,
											updated_date	= v_updated_date;

						END LOOP;
						open result_succ_msg for select 	
									'Data Synced Successfully';	
			END		
	
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_smstran(_pg_id udd_code, _smstemplate_code udd_code, _dlt_template_id udd_code, _mobile_no udd_mobile, _sms_text udd_text, _user_code udd_code, _role_code udd_code)
 LANGUAGE plpgsql
AS $procedure$
declare
    /*
		Created By : Mohan
		Created Date : 17-03-2022
		SP Code : B04SMSCXX
	*/
begin 
	insert into pg_trn_tsmstran (	pg_id,
									smstemplate_code,
									dlt_template_id,
									mobile_no,
									sms_text,
									user_code,
									role_code,
								 	scheduled_date,
								 	sms_delivered_flag,
								 	status_code,
									created_date,
									created_by)
							values(	_pg_id,
								   	_smstemplate_code,
									_dlt_template_id,
									_mobile_no,
									_sms_text,
									_user_code,
									_role_code,
								   	now(),
								   	'N',
									'A',
								    now(),
								    'system');
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_smstran(INOUT _smstran_gid udd_int, _pg_id udd_code, _smstemplate_code udd_code, _mobile_no udd_mobile, _sms_text udd_text, _scheduled_date udd_datetime, _sms_delivered_flag udd_flag, _user_code udd_code, _role_code udd_code, _status_code udd_code, _lang_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 25-02-2022
		SP Code      : B04SMSCXD
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id     = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
-- SMS Template Code Validation
	if not exists (select * from core_mst_tsmstemplate
				   where smstemplate_code = _smstemplate_code 
				   and   status_code      = 'A')
	then
		v_err_code := v_err_code || 'VB04SMSCXD_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB04SMSCXD_001', _lang_code) || v_new_line;
	end if;	
	
-- Status Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code   = 'QCD_STATUS' 
				   and   master_code   = _status_code 
				   and   status_code   = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_001', _lang_code) || v_new_line;		
	end if;
	
-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code   = _lang_code
				   and   status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	
	if _mode_flag = 'D' then
		if exists(select * from pg_trn_tsmstran
				  where smstran_gid = _smstran_gid
				  and   status_code <> 'I')
			then
			update pg_trn_tsmstran 
				set	status_code 	= 'I',
					updated_by		= _user_code,
					updated_date	= now()
				where smstran_gid 	= _smstran_gid
				--and	  pg_id		    = _pg_id
				and   status_code	<> 'I';
			v_succ_code := 'SB04SMSCXD_002';
		else
			-- Error message
			v_err_code := v_err_code || 'EB00CMNCMN_001';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_001', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
		
	elseif _mode_flag = 'I' then
		if not exists (select * from pg_trn_tsmstran
				   where smstran_gid 	= _smstran_gid)
		 then
			insert into pg_trn_tsmstran(
				pg_id,
				smstemplate_code,
				mobile_no,
				sms_text,
				scheduled_date,
				sms_delivered_flag,
				user_code,
				role_code,
				status_code,
				created_date,
				created_by)
			values(
				_pg_id,
				_smstemplate_code,
				_mobile_no,
				_sms_text,
				_scheduled_date,
				'N',
				_user_code,
				_role_code,
				_status_code,
				now(),
				_user_code) returning smstran_gid into _smstran_gid;
				v_succ_code := 'SB04SMSCXD_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;	
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_sqliteattachment(INOUT _sqliteattachment_gid udd_int, _pg_id udd_code, _role_code udd_code, _user_code udd_code, _mobile_no udd_mobile, _lang_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 22-03-2022
		SP Code      : B04SLACXX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where 	pg_id  = _pg_id 
				   and 		status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where 	lang_code   = _lang_code
				   and   	status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'I' then
		if not exists (select * from pg_trn_tsqliteattachment
				   	   where 	sqliteattachment_gid = _sqliteattachment_gid
				   	   and   	pg_id		     = _pg_id)
		 then
			insert into pg_trn_tsqliteattachment(
												pg_id,
												role_code,
												user_code,
												mobile_no,
												created_date,
												created_by
															)
										values(
												_pg_id,
												_role_code,
												_user_code,
												_mobile_no,
												now(),
												_user_code
												) returning sqliteattachment_gid into _sqliteattachment_gid;
												v_succ_code := 'SB00CMNCMN_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_sqliteattachment(INOUT _sqliteattachment_gid udd_int, _pg_id udd_code, _role_code udd_code, _user_code udd_code, _mobile_no udd_mobile, _lang_code udd_code, _mode_flag udd_flag, INOUT _file_path udd_desc, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 22-03-2022
		SP Code      : B04SLACXX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
begin

	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where 	pg_id  = _pg_id 
				   and 		status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where 	lang_code   = _lang_code
				   and   	status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if _mode_flag = 'I' then
		if not exists (select * from pg_trn_tsqliteattachment
				   	   where 	sqliteattachment_gid = _sqliteattachment_gid
				   	   and   	pg_id		     = _pg_id)
		 then
		 	select fn_get_configvalue('sqllite_filepath') into _file_path;
			insert into pg_trn_tsqliteattachment(
												pg_id,
												role_code,
												user_code,
												mobile_no,
												created_date,
												created_by
															)
										values(
												_pg_id,
												_role_code,
												_user_code,
												_mobile_no,
												now(),
												_user_code
												) 
												returning sqliteattachment_gid,_file_path into _sqliteattachment_gid;
												v_succ_code := 'SB00CMNCMN_001';
			  
		else
	       -- Record already exists
		   v_err_code := v_err_code || 'EB00CMNCMN_002';
		   v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_002', _lang_code) || v_new_line;	
			
		   RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_statemasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Thianeswaran
		Created Date : 25-02-2022
		SP Code : B01STMCUX
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														state_id integer,
														state_code char(2),
														state_name_en varchar(50),
														state_name_hi varchar(100),
														state_name_local varchar(100),
														state_short_local_name varchar(10),
														state_short_name_en varchar(10),
														category smallint,
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
				
				insert into state_master (
														state_id,
														state_code,
														state_name_en,
														state_name_hi,
														state_name_local,
														state_short_local_name,
														state_short_name_en,
														category,
														is_active,
														created_date,
														created_by,
														updated_date,
														updated_by
												)
							values              (
													v_colrec.state_id,
													v_colrec.state_code,
													v_colrec.state_name_en,
													v_colrec.state_name_hi,
													v_colrec.state_name_local,
													v_colrec.state_short_local_name,
													v_colrec.state_short_name_en,
													v_colrec.category,
													v_colrec.is_active,
													v_created_date,
													v_colrec.created_by,
													v_updated_date,
													v_colrec.updated_by
							)
							
		on CONFLICT ( state_id )  do update set  
													state_id = v_colrec.state_id,
													state_code = v_colrec.state_code,
													state_name_en = v_colrec.state_name_en,
													state_name_hi = v_colrec.state_name_hi,
													state_name_local = v_colrec.state_name_local,
													state_short_local_name = v_colrec.state_short_local_name,
													state_short_name_en = v_colrec.state_short_name_en,
													category = v_colrec.category,
													is_active = v_colrec.is_active,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;
		END LOOP;
		open result_succ_msg for select 	
   			'Data Synced Successfully';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_user(_user_code udd_code, _user_name udd_desc, _role_code udd_code, _mobile_no udd_mobile, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 05-09-2022
		SP Code      : B04USRCXX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	v_otp udd_int := 0; 
begin
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where 	lang_code   = _lang_code
				   and   	status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;
	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	-- OTP Generation 
	select left((random()*1000000000+999999)::udd_code,4) into v_otp;
	
		if not exists (select * from core_mst_tuser
				   	   where 	user_code = _user_code
					   and		user_name = _user_name
					   and		mobile_no = _mobile_no)
		 then
			insert into core_mst_tuser(
										user_code,
										user_name,
										role_code,
										mobile_no,
										otp,
										otp_on,
										otp_expire_flag,
										status_code,
										created_date,
										created_by
												)
							values(
									_user_code,
									_user_name,
									_role_code,
									_mobile_no,
									v_otp,
									now(),
									'N',
									'A',
									now(),
									_user_code
									) ;
									v_succ_code := 'SB00CMNCMN_001';
			-- OTP SMS Send area						
			call pr_sms_pgloginotp('',
								_user_code,
								_role_code,
								v_otp::udd_desc,
								_mobile_no,
								_lang_code,
								_succ_msg);
			  
		else
	      	  update core_mst_tuser 
			  set 	 otp = v_otp,
					 otp_on = now(),
					 otp_expire_flag = 'N',
					 updated_date = now(),
					 updated_by = _user_code
			  where user_code = _user_code
			  and	user_name = _user_name
			  and	mobile_no = _mobile_no;
					
			  v_succ_code := 'SB00CMNCMN_002';
					
			 -- OTP SMS Send area
			 call pr_sms_pgloginotp( 'OTP',
									 _user_code,
									 _role_code,
									 _mobile_no,
									 v_otp::udd_mobile,
									 _lang_code,
									 _succ_msg);
		  
		end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_userblock(INOUT _userblock_gid udd_int, _user_code udd_code, _block_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan s
		Created Date : 07-06-2022
		SP Code      : (user block details)
	*/
begin

	
			insert into core_mst_tuserblock(
										user_code,
										block_code,
										created_date,
										created_by
										)
							values(
									_user_code,
									_block_code,
									now(),
									_user_code
									) 
									on CONFLICT ( user_code) 
									 do update set  block_code 	 = _block_code,
													updated_date = now(),
													updated_by 	 = _user_code
									
									returning userblock_gid into _userblock_gid;
								
								_succ_msg := 'Created/Updated Successfully';
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_usertoken(INOUT _user_code udd_user, INOUT _user_token udd_text, INOUT _url udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 10-06-2022
		SP Code      : USER TOKEN
	*/
	v_user_token udd_text := '';
begin
		-- RANDOM String Generation
		SELECT md5(random()::text) into v_user_token;
		
		insert into core_mst_tusertoken(
									user_code,
									user_token,
									url,
									token_expired_date,
									token_expired_flag,
									created_date,
									created_by
												)
						values(
								_user_code,
								v_user_token,
								_url,
								now(),
								'N',
								now(),
								_user_code
								)
					on conflict (
								user_code,
								url
								)
							do update set   user_token			=	v_user_token,
			  								token_expired_flag	=	'N',
			  								token_expired_date	=	now(),
											updated_date		=	now(),
											updated_by			=	_user_code
											
								returning user_token into _user_token;
								_succ_msg := 'Success';
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_iud_villagemasterjson(_jsonquery udd_text, INOUT result_succ_msg refcursor DEFAULT 'rs_succ_msg'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
declare 
/*
		Created By : Thianeswaran
		Created Date : 28-02-2022
		SP Code : B01VLMCUX  
		Updated By : Mangai
*/
v_colrec record;
v_updated_date timestamp;
v_created_date timestamp;

begin
    for v_colrec in select * from jsonb_to_recordset(_jsonquery::udd_jsonb) as items
													(
														village_id integer,
														state_id integer,
														district_id integer,
														block_id integer,
														panchayat_id bigint,
														village_code char(16),
														village_name_en varchar(100),
														village_name_local varchar(200),
														is_active boolean,
														created_date text,
														created_by integer,
														updated_date text,
														updated_by integer
													)
				LOOP 
				select fn_text_todatetime(v_colrec.updated_date) into v_updated_date;
				select fn_text_todatetime(v_colrec.created_date) into v_created_date;
								
				insert into village_master (
														village_id,
														state_id,
														district_id,
														block_id,
														panchayat_id,
														village_code,
														village_name_en,
														village_name_local,
														is_active,
														created_date,
														created_by,
														updated_date,
														updated_by
												)
							values              (
													v_colrec.village_id,
													v_colrec.state_id,
													v_colrec.district_id,
													v_colrec.block_id,
													v_colrec.panchayat_id,
													v_colrec.village_code,
													v_colrec.village_name_en,
													v_colrec.village_name_local,
													v_colrec.is_active,
													v_created_date,
													v_colrec.created_by,
													v_updated_date,
													v_colrec.updated_by
							)
							
		on CONFLICT (village_id )  do update set  
													village_id = v_colrec.village_id,
													state_id = v_colrec.state_id,
													district_id = v_colrec.district_id,
													block_id = v_colrec.block_id,
													panchayat_id = v_colrec.panchayat_id,
													village_code = v_colrec.village_code,
													village_name_en = v_colrec.village_name_en,
													village_name_local = v_colrec.village_name_local,
													is_active = v_colrec.is_active,
													updated_date = v_updated_date,
													updated_by = v_colrec.updated_by;
		END LOOP;
		open result_succ_msg for select 	
   			'Data Synced Successfully';
		
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_mob_funddisbursementlist(_pg_id udd_code, _udyogmitra_id udd_code, _from_date udd_date, _to_date udd_date, _lang_code udd_code, INOUT _result_funddisb refcursor DEFAULT 'rs_funddisb'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 14-02-2022
		SP Code : B05FDRG01
	*/
begin
	-- stored procedure body
	open _result_funddisb for select 
								 fdt.funddisbtranche_gid as funddisbtranche_gid,
								 fd.source_inst_code as source_inst_code,		
								 fn_get_masterdesc('QCD_FUND_SOURCE',fd.source_inst_code,_lang_code) as source_inst_desc,
								 fd.funddisb_type_code as funddisb_type_code,
								 fn_get_masterdesc('QCD_FUND_TYPE',fd.funddisb_type_code,_lang_code) as ""Head"",
								 fd.loan_acc_no as loan_acc_no,
								 sum(fd.sanctioned_amount) as sanctioned_amount,
								 sum(fdt.tranche_amount) as tranche_amount,
								 fd.sanctioned_date as sanctioned_date,
								 fdt.tranche_no as tranche_no,
								 fdt.tranche_date as tranche_date,
								 '' as remarks,
								 fdt.received_date  as received_date,
								 fdt.received_ref_no as received_ref_no
				  from 			 pg_mst_tproducergroup as pg
-- 				  temparory commanded instraction from Vjvel on 04-mar-2022
-- 				  inner join 	 pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
-- 				  and 			 tran_status_code = 'A'
				  inner join 	 pg_trn_tfunddisbursement as fd on pg.pg_id = fd.pg_id
				  inner join 	 pg_trn_tfunddisbtranche as fdt on fd.funddisb_id = fdt.funddisb_id
				  and            fdt.tranche_status_code = 'QCD_DISB'
				  where 		 fd.pg_id = _pg_id
				  and			 fdt.tranche_date >= _from_date
				  and 			 fdt.tranche_date <= _to_date
-- 				  and 			 um.udyogmitra_id = _udyogmitra_id
				  and 			 fd.status_code = 'A' 
				  group by 		 fd.source_inst_code,fd.funddisb_type_code,fd.loan_acc_no,
				  fdt.received_date,fdt.received_ref_no,fd.sanctioned_date,fdt.tranche_no,
				  fdt.funddisbtranche_gid;  
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_mob_fundrepaymentlist(_pg_id udd_code, _lang_code udd_code, INOUT _result_fundrepymtlist refcursor DEFAULT 'rs_fdrepymtlist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 15-01-2022
		SP Code : B05FRPG03
	*/
begin
	-- stored procedure body
	open _result_fundrepymtlist for select 	
								 fd.funddisb_id as ""FundDisb ID"",
								 fd.funddisb_type_code as funddisb_type_code,
								 fn_get_masterdesc('QCD_FUND_TYPE',fd.funddisb_type_code,_lang_code) as ""Head"",
								 fd.source_inst_code as ""source_inst_code"",								 
								 fn_get_masterdesc('QCD_FUND_SOURCE',fd.source_inst_code,_lang_code) as ""Source"",
								 fd.loan_acc_no as ""Account No."",
								 fd.sanctioned_amount as ""Sanctioned Amount"",
								 fdr.paid_amount as ""Repaid Amount"",
								 (fd.sanctioned_amount - fdr.paid_amount) as ""O/S Amount""
				  from 		  pg_trn_tfunddisbursement as fd
				  inner join  pg_trn_tfundrepymt as fdr on fd.pg_id = fdr.pg_id
				  and 		  fdr.status_code = 'A'
				  where 	  fdr.pg_id = _pg_id
				  and 		  fd.funddisb_type_code = 'GRANT'
				  and		  fd.status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_bussplanapproval(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _lang_code udd_code, INOUT _result_bplist refcursor DEFAULT 'rs_bplist'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 19-03-2022
		SP Code : B08BPLG01
	*/
begin
	-- stored procedure body
	open _result_bplist for select 	
								 bp.bussplan_id as bussplan_id,
								 pg.pg_id as pg_id,
								 pg.pg_name as pg_name,
								 fn_get_villagedesc(pgadd.village_id) as village_id,
								 fn_get_blockdesc(pgadd.block_id) as block_id,
								 bp.period_from,
								 bp.period_to,
								 bp.bussplan_remark as remark,
								 fn_get_masterdesc('QCD_STATUS',bp.status_code,_lang_code) as bussplan_Status
				  from 		 pg_mst_tproducergroup as pg
				  inner join pg_mst_taddress as pgadd on pg.pg_id = pgadd.pg_id
				  and 		 pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
				  inner join pg_trn_tbussplan as bp on pg.pg_id = bp.pg_id
				  and        bp.status_code = 'A'
				  where      bp.pg_id = _pg_id
				  order by   bp.bussplan_id desc;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_cashbook(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _mode_code udd_code, _from_date udd_date, _to_date udd_date, _user_code udd_user, _role_code udd_code, _lang_code udd_code, INOUT _result_cashbook refcursor DEFAULT 'rs_cashbook'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 05-03-2022
		SP Code : B08CASR01
	*/
	
	v_open_dr_amount udd_amount := 0;
	v_open_cr_amount udd_amount := 0;
	v_close_dr_amount udd_amount := 0;
	v_close_cr_amount udd_amount := 0;
	v_amount udd_amount := 0;
	
begin
	if _mode_code = '' then
		_mode_code := null;
	end if;
	
	-- opening
	select 	
			   coalesce(sum(dr_amount*-1+cr_amount),0) into v_amount
	from	   pg_trn_tcashflow_view 
	where 	   pg_id 	 	 = _pg_id
	and		   tran_date 	< _from_date
	and 	   status_code 	 = 'A';

	v_amount = coalesce(v_amount,0);
	
	if (v_amount < 0) then
		v_open_dr_amount = abs(v_amount);
	else
		v_open_cr_amount = v_amount;
	end if;
	
	--closing
	select 	
			   coalesce(sum(dr_amount*-1+cr_amount),0) into v_amount
	from	   pg_trn_tcashflow_view 
	where 	   pg_id 	 	 = _pg_id
	and		   tran_date 	<= _to_date
	and 	   status_code 	 = 'A';

	v_amount = coalesce(v_amount,0);
	
	if (v_amount < 0) then
		v_close_dr_amount = abs(v_amount);
	else
		v_close_cr_amount = v_amount;
	end if;
	
	-- stored procedure body 
	open _result_cashbook for 
							select a.* from 
							(
							select 	
							   1 as sl_no,
							   _from_date as tran_date,
							   'Opening' as tran_remark,
							   '' as tran_ref_no,
							   '' as paymode, 
							   '' as pay_mode_desc,
							   v_open_cr_amount as reciept,
							   v_open_dr_amount as payment
							union all 
							select 
								   2 as sl_no,
								   tran_date,
								   tran_remark,
								   tran_ref_no,
								   pay_mode_code as paymode,
								   fn_get_masterdesc('QCD_PAY_MODE',pay_mode_code,_lang_code) as pay_mode_desc,
								   cr_amount as reciept,
								   dr_amount as payment
						from	   pg_trn_tcashflow_view
						where	   tran_date >= _from_date 
						and 	   tran_date <= _to_date
						and 	   pay_mode_code = coalesce(_mode_code,pay_mode_code)
						and   	   pg_id = _pg_id 
						and 	   status_code = 'A'
							union all 
							select 	
									   3 as sl_no,
									   _to_date as tran_date,
									   'Closing' as tran_remark,
							  		   '' as tran_ref_no,
									   '' as paymode,
									   '' as pay_mode_desc,							   
									   v_close_cr_amount as reciept,
									   v_close_dr_amount as payment						
							) as a order by a.tran_date,a.sl_no;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_commission(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _from_date udd_date, _to_date udd_date, _user_code udd_user, _role_code udd_code, _lang_code udd_code, INOUT _result_commission refcursor DEFAULT 'rs_commission'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 07-03-2022
		SP Code : B08COMR01
	*/
begin
	-- stored procedure body
	open _result_commission for select 
									fx.pgfundledger_gid as pgfundexp_gid,
									'' as ref_no,
									fx.tran_date as expense_date,
									fx.pgfund_code,
									fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code)
																	as pgfund_code_desc,
									fx.pgfund_ledger_code as expense_head_code,
									fn_get_masterdesc('QCD_ACC_HEAD',fx.pgfund_ledger_code,_lang_code)
																	as expense_head_desc,
									fx.beneficiary_name,
									fx.dr_amount as expense_amount,
									fx.recovery_flag,
									fn_get_masterdesc('QCD_YES_NO',recovery_flag,_lang_code)
																	as recovery_flag_desc,
									coalesce(fx.pgfund_remark,'') as expense_remark ,
									pg.pg_name
						from 		pg_trn_tpgfundledger as fx
						inner join  pg_mst_tproducergroup as pg
						on          fx.pg_id = pg.pg_id
						and         pg.status_code = 'A'
						where 		fx.tran_date >= _from_date
						and 		fx.tran_date <= _to_date
						and 		fx.pg_id = _pg_id
						and 		fx.pgfund_trantype_code = 'QCD_PGFUND_EXPENSES'
						and 		fx.recovery_flag = 'Y'
						and         fx.status_code <> 'I';
	
	/*select
								   tran_date as expense_date,
								   pgfund_remark as expense_remark,
								   beneficiary_name as ref_no,
								   dr_amount as amount
						from	   pg_trn_tpgfundledger
						where   tran_date >= _from_date 
						and 	tran_date <= _to_date
						and     pg_id = _pg_id 
						and     pgfund_trantype_code = 'QCD_PGFUND_EXPENSES'
						and 	recovery_flag = 'Y'
						and     status_code = 'A';*/
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_incomeexpense(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _from_date udd_date, _to_date udd_date, _lang_code udd_code, INOUT _result_income_expense refcursor DEFAULT 'rs_incomeexpense'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
begin
	/*
		Created By : Mohan
		Created Date : 30-03-2022
		SP Code : B08IEXR01
	*/
	-- stored procedure body
	open _result_income_expense for select 	
									incomeexpense_gid,
									pg_id,
									acchead_type_code,
									fn_get_masterdesc('QCD_ACC_HEAD_TYPE',acchead_type_code,_lang_code) as acchead_type_desc,
									acchead_code,
									fn_get_masterdesc('QCD_ACC_HEAD',acchead_code,_lang_code) as acchead_desc,
									tran_date,	
									case 
										when acchead_type_code = 'QCD_EXPENSE' 
											then dr_amount 
										else 0
									end as dr_amount,
									case
										when acchead_type_code = 'QCD_INCOME' 
											then cr_amount 
										else 0
									end as cr_amount,
									narration_code,
									fn_get_masterdesc('QCD_ACC_NARRATION',narration_code,_lang_code) as narration_desc,	
									tran_ref_no,
									tran_remark,
									pay_mode_code,
									fn_get_masterdesc('QCD_PAY_MODE',pay_mode_code,_lang_code) as pay_mode_desc,
									status_code,
									fn_get_masterdesc('QCD_STATUS',status_code,_lang_code) as status_desc,
									created_date,
									created_by,
									updated_date,
									updated_by
						from 		pg_trn_tincomeexpense 
						where 		tran_date >= _from_date
						and 		tran_date <= _to_date
						and 		pg_id      = _pg_id
						and 		status_code = 'A'
						order by 	incomeexpense_gid;
						
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_memberbook(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _pgmember_id udd_code, _mode_code udd_code, _from_date udd_date, _to_date udd_date, _user_code udd_user, _role_code udd_code, _lang_code udd_code, INOUT _result_memberbook refcursor DEFAULT 'rs_memberbook'::refcursor, INOUT _result_memberdtl refcursor DEFAULT 'rs_memberdtl'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 05-03-2022
		
		Updated By : Vijayavel J
		Updated Date : 01-04-2022
		
		SP Code : B08MBKR01
	*/
	
	v_amount udd_amount := 0;
	v_dr_amount udd_amount := 0;
	v_cr_amount udd_amount := 0;
begin
	-- opening
	select 	
			   coalesce(sum(dr_amount*-1+cr_amount),0) into v_amount
	from	   pg_trn_tpgmemberledger 
	where 	   pg_id 	 	 = _pg_id
	and 	   pgmember_id	 = _pgmember_id
	and		   tran_date 	 < _from_date
	and 	   status_code 	 = 'A';

	v_amount = coalesce(v_amount,0);
	
	if v_amount >= 0 then
		v_cr_amount = v_amount;
	else 
		v_dr_amount = abs(v_amount);
	end if;	
	-- stored procedure body
	open _result_memberbook for select a.*,
								   sum(coalesce(a.closing_amount-a.dr_amount+a.cr_amount,0) * -1)
								   over (order by a.tran_date,a.pgmemberledger_gid) as bal_amount 
						from
						(
							select 	
									   -1 as pgmemberledger_gid,
									   _from_date::udd_date as tran_date,
									   'Opening' as tran_narration,
									   '' as paymode_code,
									   '' as paymode_desc,
									   v_dr_amount as dr_amount,
									   v_cr_amount as cr_amount,
									   0 as closing_amount
							union all 
							select 	
								pgmemberledger_gid,
								tran_date::udd_date as tran_date,
								tran_narration,
								paymode_code,
								fn_get_masterdesc('QCD_PAY_MODE',paymode_code,'en_US') 
									as paymode_desc,
								dr_amount,
								cr_amount,
								0 as closing_amount 
							from	   pg_trn_tpgmemberledger
							where 	   pg_id 	 	 = _pg_id
							and		   pgmember_id	 = _pgmember_id
							and 	   tran_date 	 >= _from_date
							and 	   tran_date 	 < _to_date + INTERVAL '1 day'
							and 	   paymode_code  = 
							case 
									when _mode_code isnull or _mode_code = ''  then 
										coalesce(paymode_code,_mode_code)
									else 
										coalesce(_mode_code,paymode_code) 
							end 
							and 	   status_code 	 = 'A'
						) as a order by a.tran_date,a.pgmemberledger_gid;
						
						
	-- Member detail					
	open _result_memberdtl for select 
									pm.pgmember_gid,
									pm.pg_id,
									pg.pg_name,
									pm.pgmember_id,
									concat(pm.pgmember_id,' & ',pm.pgmember_name) as pgmember_code_name,
									pm.pgmember_type_code,
									fn_get_masterdesc('QCD_PGMEMBER_TYPE',pm.pgmember_type_code,_lang_code) as pgmember_type_desc,
									pm.pgmember_name,
									pm.pgmember_ll_name,
									pm.fatherhusband_name,
									pm.fatherhusband_ll_name,
									pm.dob_date,
									pm.gender_code,
									fn_get_masterdesc('QCD_GENDER',pm.gender_code,_lang_code) as gender_desc,
									pm.caste_code,
									fn_get_masterdesc('LOKOS_SOCIAL_CAT',pm.caste_code,_lang_code) as caste_desc,
									pm.mobile_no_active,
									pm.mobile_no_alternative,
									pm.member_remark as remarks,
									pm.pgmember_photo,
									pm.shg_id,
									pm.shgmember_id,
									pm.sync_status_code,
									pm.dbo_available_flag,
									fn_get_masterdesc('QCD_YES_NO',pm.dbo_available_flag,_lang_code) as dbo_available_flag_desc,
									pm.age,
									pm.age_ason_date,
									pm.status_code,
									fn_get_masterdesc('QCD_STATUS',pm.status_code,_lang_code) as status_desc,
									pm.created_date,
									pm.created_by,
									pm.updated_date,
									pm.updated_by
						  from 		pg_mst_tpgmember as pm
						  inner join pg_mst_tproducergroup as pg on pm.pg_id = pg.pg_id
						  where     pm.pg_id = _pg_id 
						  and       pm.pgmember_id = _pgmember_id
						  order by 	pm.pgmember_gid;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_payment(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _tran_date udd_date, _pgmember_id udd_code, _lang_code udd_code, INOUT _result_payment refcursor DEFAULT 'rs_payment'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 05-03-2022
		
		updated By : Mohan S
		Updated date : 12-08-2022
		
		SP Code : B08PYMR01
	*/
begin
	-- stored procedure body 
	if _pgmember_id = '' then
		_pgmember_id := null;
	end if;
	open _result_payment for select distinct
									   ml.pg_id,
									   ml.tran_date::udd_date,
									   concat(m.pgmember_id,' & ',m.pgmember_name) as membercode_name,
									   m.pgmember_id,
									   m.pgmember_name,
									   m.pgmember_type_code,
									   fn_get_masterdesc('QCD_PGMEMBER_TYPE',m.pgmember_type_code,_lang_code) as pgmember_type_desc,
									   m.pgmember_clas_code,
									   fn_get_masterdesc('QCD_PGMEMBER_CLAS',m.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
									   fn_get_dueamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date) as paymentdue,
									   fn_get_paidamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date) as paid,
									   fn_get_pymtosamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date) as outstanding
							from	   pg_trn_tpgmemberledger as ml
							inner join pg_mst_tpgmember as m
							on	   	   ml.pg_id = m.pg_id
							and		   ml.pgmember_id	= m.pgmember_id
							and		   m.status_code = 'A'
							where 	   ml.pg_id = _pg_id
							and		   ml.tran_date < _tran_date::udd_date  + INTERVAL '1 DAY'
							and 	   ml.pgmember_id = coalesce(_pgmember_id,ml.pgmember_id) 	
							and 	   ml.status_code = 'A';
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_riskfund(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _pgfund_code udd_code, _from_date udd_date, _to_date udd_date, _user_code udd_user, _role_code udd_code, _lang_code udd_code, INOUT _result_riskfund refcursor DEFAULT 'rs_riskfund'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 11-03-2022
		SP Code : B08RKFR01
	*/
	
	v_open_dr_amount udd_amount := 0;
	v_open_cr_amount udd_amount := 0;
	v_close_dr_amount udd_amount := 0;
	v_close_cr_amount udd_amount := 0;
	v_amount udd_amount := 0;
begin
	-- stored procedure body
	if _pgfund_code = '' then
		_pgfund_code = null;
	end if;
	
	-- opening
	select 	
			   coalesce(sum(dr_amount*-1+cr_amount),0) into v_amount
	from	   pg_trn_tpgfundledger 
	where 	   pg_id 	 	 = _pg_id
	and		   pgfund_code	 = coalesce(_pgfund_code,pgfund_code)
	and		   tran_date 	< _from_date
	and 	   status_code 	 = 'A';

	v_amount = coalesce(v_amount,0);
	
	if (v_amount < 0) then
		v_open_dr_amount = abs(v_amount);
	else
		v_open_cr_amount = v_amount;
	end if;
	
	--closing
	select 	
			   coalesce(sum(dr_amount*-1+cr_amount),0) into v_amount
	from	   pg_trn_tpgfundledger 
	where 	   pg_id 	 	 = _pg_id
	and		   pgfund_code	 = coalesce(_pgfund_code,pgfund_code)
	and		   tran_date 	<= _to_date
	and 	   status_code 	 = 'A';

	v_amount = coalesce(v_amount,0);
	
	if (v_amount < 0) then
		v_close_dr_amount = abs(v_amount);
	else
		v_close_cr_amount = v_amount;
	end if;
	
	open _result_riskfund for 
					select a.* from 
					(
					select 	
							   1 as sl_no,
							   _from_date as tran_date,
							   'Opening' as pgfund_remark,
							   _pgfund_code,
							   fn_get_masterdesc('QCD_PGFUND',_pgfund_code,_lang_code) as pgfund_desc,
							   '' as pgfund_ledger_code,
							   '' as pgfund_ledger_desc,
							   '' as ref_no,
							   '' as type,
							   '' as recovery_flag,
							   '' as recovery_desc,
							   v_open_cr_amount as inflow,
							   v_open_dr_amount as outflow
					union all 
					select 	
							   2 as sl_no,
							   tran_date,
							   concat(coalesce(fn_get_masterdesc('QCD_ACC_HEAD',pgfund_ledger_code,_lang_code),''),
									  '/',coalesce(pgfund_remark,'')) as pgfund_remark,
							   pgfund_code,
							   fn_get_masterdesc('QCD_PGFUND',pgfund_code,_lang_code) as pgfund_desc,
							   pgfund_ledger_code,
							   fn_get_masterdesc('QCD_ACC_HEAD',pgfund_ledger_code,_lang_code) as pgfund_ledger_desc,
							   '' as ref_no,
							   fn_get_masterdesc('QCD_PGFUND_TRANTYPE',pgfund_trantype_code,_lang_code) as type,
							   recovery_flag,
							   fn_get_masterdesc('QCD_YES_NO',recovery_flag,_lang_code) as recovery_desc,
							   cr_amount as inflow,
							   dr_amount as outflow
					from	   pg_trn_tpgfundledger 
					where 	   pg_id 	 	 = _pg_id
					and		   pgfund_code	 = coalesce(_pgfund_code,pgfund_code)
					and		   tran_date 	>= _from_date
					and 	   tran_date 	<= _to_date
					and 	   status_code 	 = 'A'
					union all 
					select 	
							   3 as sl_no,
							   _to_date as tran_date,
							   'Closing' as pgfund_remark,
							   _pgfund_code,
							   fn_get_masterdesc('QCD_PGFUND',_pgfund_code,_lang_code) as pgfund_desc,
							   '' as pgfund_ledger_code,
							   '' as pgfund_ledger_desc,
							   '' as ref_no,
							   '' as type,
							   '' as recovery_flag,
							   '' as recovery_desc,
							   v_close_cr_amount as inflow,
							   v_close_dr_amount as outflow						
					) as a order by a.sl_no;
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_saledistribution(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _from_date udd_date, _to_date udd_date, _pgmember_id udd_code, _lang_code udd_code, INOUT _result_saledistribution refcursor DEFAULT 'rs_saledistribution'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 05-03-2022
		
		Updated By : Mohan S
		Updated Date : 17-08-2022
		
		SP Code : B08SDBR01
	*/
begin
	-- stored procedure body 
	open _result_saledistribution for select distinct
									   ml.pg_id,
									   concat(m.pgmember_id,' & ',m.pgmember_name) as membercode_name,
									   m.pgmember_id,
									   m.pgmember_name,
									   m.pgmember_type_code,
									   fn_get_masterdesc('QCD_PGMEMBER_TYPE',m.pgmember_type_code,_lang_code) as promoter_type_desc,
									   m.pgmember_clas_code,
									   fn_get_masterdesc('QCD_PGMEMBER_CLAS',m.pgmember_clas_code,_lang_code) as pgmember_clas_desc,
									   ml.tran_date,
									   fn_get_tranamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date,'QCD_SALES') as grosssale,
									   fn_get_tranamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date,'QCD_MEM_PROCCOST') as costadj,
									   fn_get_tranamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date,'QCD_PG_COMMISSION') as commissionadj,
									   fn_get_tranamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date,'QCD_SALES') -
									   fn_get_tranamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date,'QCD_MEM_PROCCOST') -
									   fn_get_tranamount(ml.pg_id,ml.pgmember_id,ml.tran_date::udd_date,'QCD_PG_COMMISSION') as netsale
							from	   pg_trn_tpgmemberledger as ml
							inner join pg_mst_tpgmember as m
							on	   	   ml.pg_id = m.pg_id
							and		   ml.pgmember_id	= m.pgmember_id
							and		   m.status_code = 'A'
							where 	   ml.pg_id = _pg_id
							and		   ml.tran_date > _from_date::udd_date  - INTERVAL '1 DAY'
							and		   ml.tran_date < _to_date::udd_date    + INTERVAL '1 DAY'
							and 	   ml.pgmember_id = 	
							case 
									when _pgmember_id isnull or _pgmember_id = ''  then 
										coalesce(ml.pgmember_id,_pgmember_id)
									else 
										coalesce(_pgmember_id,ml.pgmember_id) 
							end 
							and ml.status_code = 'A';
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_rpt_sales(_block_id udd_int, _panchayat_id udd_int, _village_id udd_int, _pg_id udd_code, _buyer_name udd_desc, _paymode udd_code, _from_date udd_date, _to_date udd_date, _user_code udd_user, _role_code udd_code, _lang_code udd_code, INOUT _result_sales refcursor DEFAULT 'rs_sales'::refcursor)
 LANGUAGE plpgsql
AS $procedure$
DECLARE 
	/*
		Created By : Mohan S
		Created Date : 23-02-2022
		SP Code : B08SLER01
	*/
begin
	-- stored procedure body
	open _result_sales for select 	
							   sv.inv_no,
							   sv.inv_date,
							   sv.buyer_name,
							   case 
							   	when sv.buyer_regular_flag = 'Y' then fn_get_masterdesc('QCD_BUYER_TYPE','QCD_REGULAR',_lang_code)
								else fn_get_masterdesc('QCD_BUYER_TYPE','QCD_ONETIME',_lang_code)
							   end as buyer_type,
							   sp.rec_slno,
							   sp.prod_code,
							   fn_get_productdesc(sp.prod_code, _lang_code) as prod_desc,
							   fn_get_masterdesc('QCD_GRADE',sp.grade_code,_lang_code) as grade_desc,
							   sp.sale_qty,
							   sp.sale_rate,
							   sp.sale_qty*sp.sale_rate as sale_value,
							   sp.cgst_amount+sp.sgst_amount as tax,
							   sp.sale_qty*sp.sale_rate+sp.cgst_amount+sp.sgst_amount as gross,
							   'Cash' as mode,
							   sv.collected_amount as collected,
							   sv.tot_sale_amount - sv.collected_amount as outstanding
					from	   pg_trn_tsale_view as sv
					inner join pg_trn_tsaleproduct as sp 
					on 		sv.pg_id = sp.pg_id 
					and   	sv.inv_no = sp.inv_no 
					and 	sv.inv_date = sp.inv_date 
					where 	sv.inv_date >= _from_date 
					and 	sv.inv_date <= _to_date
					and     sv.pg_id = _pg_id 
					and 	sv.buyer_name = 
					case 
							when _buyer_name isnull or _buyer_name = ''  then 
								coalesce(sv.buyer_name,_buyer_name)
							else 
								coalesce(_buyer_name,sv.buyer_name) 
					end 
					and     sv.status_code = 'A'
					group by   
							   sv.inv_date,
							   sv.inv_no,
							   sv.buyer_name,
							   sv.buyer_regular_flag,
							   sp.rec_slno,
							   sp.prod_code,
							   sp.grade_code,
							   sp.sale_qty,
							   sp.sale_rate,
							   sp.sale_amount,
							   sp.cgst_amount,
							   sp.sgst_amount,
							   sv.tot_gst_amount,
							   sv.tot_sale_amount,
							   sv.collected_amount;
	
end;
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_onboarding(_end_count udd_int, INOUT _pg_gid udd_int, INOUT _pg_id udd_code, INOUT _pgaddress_gid udd_int, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 23-05-2022
		SP Code : (Onboarding load test)
	*/
	v_max_pg_gid udd_int := 0;
	v_start_count udd_int := 0;
	v_pg_name udd_desc := 'Loadtest';
	v_pg_name1 udd_code  := '';
begin
	
	while v_start_count < _end_count loop
		select 	max(pg_gid)+1 into v_max_pg_gid 
		from 	pg_mst_tproducergroup;
		
		v_pg_name1 := v_pg_name || v_max_pg_gid::udd_desc;
		
		call public.pr_iud_pgproducergroup (_pg_gid, _pg_id, v_pg_name1, 'परफ्यूज़र', 'F', '2022-05-11', 'NRLMINNOVFUND',
											0, 0, 0, 0, 0, '', '','', '', 'A', 'en_US', 'Admin', 'I', '', _succ_msg);

	    CALL public.pr_iud_pgaddress (_pgaddress_gid, _pg_id , 'QCD_ADDRTYPE_REG', 'No-23 , New Road,Delhi', 
									'353435','491763', '205832', '2171', '349', '29', 'en_US', 'Admin' , 'I', _succ_msg );
		
		_pg_gid := 0;
		_pgaddress_gid := 0;
		v_start_count := v_start_count + 1;
		
	end loop;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_paymentprocess()
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
		SP Code : B01PAYRUN (PAY - Payment Run)
	*/
	v_inv_date 	udd_date;
	v_pg_id		udd_code;
	
	v_rec record;
begin
	-- get sale calc details
	FOR v_rec IN select distinct 	
								pg_id,
								inv_date
					 from		pg_trn_tsaleproduct
					 where 		payment_calc_flag	= 'N'
					 and 		status_code			= 'A'

	LOOP
		call pr_run_pgmembersalebrkp(v_rec.pg_id,v_rec.inv_date);
		call pr_run_pgmembersaleledger(v_rec.pg_id);

		call pr_run_pgmemberproccostbrkp(v_rec.pg_id,v_rec.inv_date);
		call pr_run_pgmemberproccostledger(v_rec.pg_id);
		
		call pr_run_pgmembercommbrkp(v_rec.pg_id,v_rec.inv_date);
		call pr_run_pgmembercommledger(v_rec.pg_id);
	END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_pgmembercommbrkp(_pg_id udd_code, _comm_date udd_date)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
		
		SP Code : B01MCBRUN (MSB - PG Member Commission Breakup)
	*/
	v_pgmembercommcalc_gid udd_int	:= 0;
	
	v_tot_sale_qty	udd_qty	:= 0;
	v_sale_qty		udd_qty := 0;
	
	v_tot_sale_amount 	udd_amount 	:= 0;
	v_sale_amount 		udd_amount 	:= 0;
	
	v_pgmember_id		udd_code 	:= '';
	v_tot_comm_amount 	udd_amount 	:= 0;
	v_calc_comm_amount	udd_amount	:= 0;
	
	v_paymentcalc_date 	udd_datetime;
	
	v_pgmembersalecalc_rec 	record;
begin
	v_paymentcalc_date := now();
	
	-- get procure cost details
	select 	coalesce(sum(dr_amount),0) into v_tot_comm_amount
	from	pg_trn_tpgfundledger 
	where 	pg_id 			= _pg_id 
	and 	tran_date 		= _comm_date 
	and		pgfund_trantype_code 	= 'QCD_PGFUND_EXPENSES'
	and		recovery_flag			= 'Y' 
	and		recovered_flag			= 'N' 
	and 	payment_calc_flag		= 'N'
	and 	status_code				= 'A';
	
	-- return for zero value
	if (v_tot_comm_amount = 0) then
		return;
	end if;
	
	-- get total sales amount
	select 	
			coalesce(sum(dr_amount),0), 
			coalesce(sum(calc_applied_qty),0)
	into 
			v_tot_sale_amount,
			v_tot_sale_qty
	from	pg_trn_tpgmembersalecalc as s
	where 	s.pg_id 		= _pg_id 
	and 	s.sale_date 	= _comm_date
	and 	s.status_code	= 'A';

	-- get pgmember sale calc
	FOR v_pgmembersalecalc_rec IN select 	
										s.pg_id,
										s.pgmember_id,
										s.sale_date,
										sum(s.calc_applied_qty) as sale_qty,
										sum(s.dr_amount) as sale_amount
								  from	pg_trn_tpgmembersalecalc as s
								  where s.pg_id 		= _pg_id 
								  and 	s.sale_date 	= _comm_date
								  and 	s.status_code	= 'A'
								  group by 
										s.pg_id,
										s.pgmember_id,
										s.sale_date
								  having sum(s.dr_amount) > 0
	LOOP
		-- v_calc_comm_amount := (v_pgmembersalecalc_rec.sale_amount/v_tot_sale_amount)*v_tot_comm_amount;
		v_calc_comm_amount := (v_pgmembersalecalc_rec.sale_qty/v_tot_sale_qty)*v_tot_comm_amount;

		insert into pg_trn_tpgmembercommcalc
		(	
			pg_id,
			pgmember_id,
			paymentcalc_date,
			comm_date,
			dr_amount,
			cr_amount,
			status_code,
			created_date,
			created_by
		 )	
		 values 
		 (
			 _pg_id,
			 v_pgmembersalecalc_rec.pgmember_id,
			 v_paymentcalc_date,
			 _comm_date,
			 0,
			 v_calc_comm_amount,
			 'A',
			 now(),
			 'system'
		 ) returning pgmembercommcalc_gid into v_pgmembercommcalc_gid;
		
		-- insert the reference details
		insert into pg_trn_tpgmembercommcalcdtl
		(
				pgmembercommcalc_gid,
				pgmembersalecalc_gid
		)
		select 
				v_pgmembercommcalc_gid,
				pgmembersalecalc_gid 
		from 	pg_trn_tpgmembersalecalc
		where 	pg_id		= _pg_id
		and		sale_date	= _comm_date
		and		pgmember_id	= v_pgmembersalecalc_rec.pgmember_id;

		-- update payment process status in comm cost table
		update 	pg_trn_tpgfundledger 
		set		payment_calc_flag	= 'Y',
				paymentcalc_date	= v_paymentcalc_date,
				recovered_flag		= 'Y',
				updated_date		= now(),
				updated_by			= 'admin'
		where 	pg_id 					= _pg_id
		and 	tran_date				= _comm_date
		and		pgfund_trantype_code 	= 'QCD_PGFUND_EXPENSES'
		and		recovery_flag			= 'Y' 
		and		recovered_flag			= 'N' 
		and		payment_calc_flag		= 'N'
		and 	status_code 			= 'A';
	END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_pgmembercommledger(_pg_id udd_code)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 13-03-2022
		
		SP Code : B01PCLRUN (PCL - PG Commission Ledger)
	*/
	v_tran_date 		udd_datetime;
	v_tran_narration 	udd_text := '';
	v_succ_msg 			udd_text;

	v_dr_amount 		udd_amount := 0;
	v_cr_amount 		udd_amount := 0;
	
	v_pgmemberledger_gid udd_int := 0;
	v_commcalc_rec record;
begin
	v_tran_date := now();
	
	-- get commission calc details
	FOR v_commcalc_rec IN select 	
								pg_id,
								pgmember_id,
								comm_date,
								sum(cr_amount+(dr_amount*-1.0)) as tran_amount
					 from		pg_trn_tpgmembercommcalc  
					 where 		pg_id 				= _pg_id 
					 and 		ledger_tran_flag	= 'N'
					 and 		status_code			= 'A'
					 group by 	pg_id,
								pgmember_id,
								comm_date

	LOOP
		v_dr_amount := 0;
		v_cr_amount := 0;
		v_pgmemberledger_gid := 0;
		
		if v_commcalc_rec.tran_amount > 0 then
			v_cr_amount := v_commcalc_rec.tran_amount;
			v_tran_narration := 'PG Comm Adjusted';
		else
			v_dr_amount := v_commcalc_rec.tran_amount * (-1.0);
			v_tran_narration := 'PG Comm Reversed';
		end if;
		
		-- insert in pgmember ledger table
		call pr_iud_pgmemberledger
			(
				v_pgmemberledger_gid,
				v_commcalc_rec.pg_id,
				v_commcalc_rec.pgmember_id,
				'QCD_PG_COMMISSION',
				v_commcalc_rec.comm_date,
				v_dr_amount,
				v_cr_amount,
				v_tran_narration,
				'',
				'',
				'A',
				'',
				'en_US',
				'admin',
				'I',
				v_succ_msg
			);
		
		-- update in pgmembercommcalc table
		update 	pg_trn_tpgmembercommcalc
		set		ledger_tran_flag 	= 'Y',
				tran_date 			= v_tran_date,
				updated_date		= now(),
				updated_by			= 'system'
		where	pg_id				= v_commcalc_rec.pg_id
		and		pgmember_id 		= v_commcalc_rec.pgmember_id
		and		comm_date 			= v_commcalc_rec.comm_date 
		and		ledger_tran_flag 	= 'N'
		and		status_code			= 'A';
	END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_pgmemberproccostbrkp(_pg_id udd_code, _proc_date udd_date)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
		
		SP Code : B01MPBRUN (MSB - PG Member Procurement Cost Breakup)
	*/
	v_pgmemberproccostcalc_gid udd_int	:= 0;
	
	v_tot_sale_amount 	udd_amount 	:= 0;
	v_sale_amount 		udd_amount 	:= 0;
	
	v_tot_sale_qty 	udd_qty := 0;
	v_sale_qty 		udd_qty := 0;
	
	v_pgmember_id		udd_code 	:= '';
	v_tot_proc_cost 	udd_amount 	:= 0;
	v_calc_proc_cost	udd_amount	:= 0;
	
	v_paymentcalc_date 	udd_datetime;
	
	v_dr_amt udd_amount := 0;
	v_cr_amt udd_amount := 0;

	v_pgmembersalecalc_rec 	record;
begin
	v_paymentcalc_date := now();
	
	-- get procure cost details
	select coalesce(sum(
			pc.package_cost+
			pc.loading_unloading_cost+
			pc.transport_cost+
			pc.other_cost),0) into v_tot_proc_cost
	from	pg_trn_tprocurecost as pc 
	where 	pc.pg_id 			= _pg_id 
	and 	pc.proc_date 		= _proc_date 
	and 	pc.payment_calc_flag= 'N'
	and 	pc.status_code		= 'A';
	
	-- return for zero value
	if (v_tot_proc_cost = 0) then
		return;
	end if;
	
	-- get total sales amount
	select 	
			coalesce(sum(dr_amount),0),
			coalesce(sum(calc_applied_qty),0)
	into	v_tot_sale_amount,
			v_tot_sale_qty
	from	pg_trn_tpgmembersalecalc as s
	where 	s.pg_id 		= _pg_id 
	and 	s.sale_date 	= _proc_date
	and 	s.status_code	= 'A';

	-- get pgmember sale calc
	FOR v_pgmembersalecalc_rec IN select 	
										s.pg_id,
										s.pgmember_id,
										s.sale_date,
										sum(s.calc_applied_qty) as sale_qty,
										sum(s.dr_amount) as sale_amount
								  from	pg_trn_tpgmembersalecalc as s
								  where s.pg_id 		= _pg_id 
								  and 	s.sale_date 	= _proc_date
								  and 	s.status_code	= 'A'
								  group by 
										s.pg_id,
										s.pgmember_id,
										s.sale_date
								  having sum(s.dr_amount) > 0
	LOOP
		-- v_calc_proc_cost := (v_pgmembersalecalc_rec.sale_amount/v_tot_sale_amount)*v_tot_proc_cost;
		v_calc_proc_cost := (v_pgmembersalecalc_rec.sale_qty/v_tot_sale_qty)*v_tot_proc_cost;

		insert into pg_trn_tpgmemberproccostcalc
		(	
			pg_id,
			pgmember_id,
			paymentcalc_date,
			proc_date,
			dr_amount,
			cr_amount,
			status_code,
			created_date,
			created_by
		 )	
		 values 
		 (
			 _pg_id,
			 v_pgmembersalecalc_rec.pgmember_id,
			 v_paymentcalc_date,
			 _proc_date,
			 0,
			 v_calc_proc_cost,
			 'A',
			 now(),
			 'system'
		 ) returning pgmemberproccostcalc_gid into v_pgmemberproccostcalc_gid;
		
		-- insert the reference details
		insert into pg_trn_tpgmemberproccostcalcdtl
		(
				pgmemberproccostcalc_gid,
				pgmembersalecalc_gid
		)
		select 
				v_pgmemberproccostcalc_gid,
				pgmembersalecalc_gid 
		from 	pg_trn_tpgmembersalecalc
		where 	pg_id		= _pg_id
		and		sale_date	= _proc_date
		and		pgmember_id	= v_pgmembersalecalc_rec.pgmember_id;

		-- update payment process status in proc cost table
		update 	pg_trn_tprocurecost 
		set		payment_calc_flag	= 'Y',
				paymentcalc_date	= v_paymentcalc_date,
				updated_date		= now(),
				updated_by			= 'admin'
		where 	pg_id 				= _pg_id
		and 	proc_date			= _proc_date
		and		payment_calc_flag	= 'N'
		and 	status_code			= 'A';
	END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_pgmemberproccostledger(_pg_id udd_code)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
		
		SP Code : B01MPLRUN (MPL - PG Member Procure Cost Ledger)
	*/
	v_tran_date udd_datetime;
	v_succ_msg udd_text;

	v_dr_amount udd_amount := 0;
	v_cr_amount udd_amount := 0;
	v_pgmemberledger_gid udd_int := 0;
	v_proccostcalc_rec record;
begin
	v_tran_date := now();
	
	-- get procure cost calc details
	FOR v_proccostcalc_rec IN select 	
								pg_id,
								pgmember_id,
								proc_date,
								sum(cr_amount+(dr_amount*-1.0)) as tran_amount
					 from		pg_trn_tpgmemberproccostcalc  
					 where 		pg_id 				= _pg_id 
					 and 		ledger_tran_flag	= 'N'
					 and 		status_code			= 'A'
					 group by 	pg_id,
								pgmember_id,
								proc_date

	LOOP
		v_dr_amount := 0;
		v_cr_amount := 0;
		v_pgmemberledger_gid := 0;
		
		if v_proccostcalc_rec.tran_amount > 0 then
			v_cr_amount = v_proccostcalc_rec.tran_amount;
		else
			v_dr_amount = v_proccostcalc_rec.tran_amount * (-1.0);
		end if;
		
		-- insert in pgmember ledger table
		call pr_iud_pgmemberledger
			(
				v_pgmemberledger_gid,
				v_proccostcalc_rec.pg_id,
				v_proccostcalc_rec.pgmember_id,
				'QCD_MEM_PROCCOST',
				v_proccostcalc_rec.proc_date,
				v_dr_amount,
				v_cr_amount,
				'Proc cost Adjusted',
				'',
				'',
				'A',
				'',
				'en_US',
				'admin',
				'I',
				v_succ_msg
			);
		
		-- update in pgmemberpaymentcalc table
		update 	pg_trn_tpgmemberproccostcalc
		set		ledger_tran_flag 	= 'Y',
				tran_date 			= v_tran_date,
				updated_date		= now(),
				updated_by			= 'system'
		where	pg_id				= v_proccostcalc_rec.pg_id
		and		pgmember_id 		= v_proccostcalc_rec.pgmember_id
		and		proc_date			= v_proccostcalc_rec.proc_date
		and		ledger_tran_flag 	= 'N'
		and		status_code			= 'A';
	END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_pgmembersalebrkp(_pg_id udd_code, _sale_date udd_date)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 27-02-2022
		
		Updated By : Vijayavel J
		Updated Date : 14-03-2022
		
		SP Code : B01MSBRUN (MSB - PG Member Sale Breakup)
	*/
	v_tot_sale_qty udd_qty := 0;
	v_tot_pgmember_stock_qty udd_qty := 0;
	
	v_calc_sale_qty udd_qty := 0;
	v_calc_sale_amt udd_amount := 0;
	
	v_tot_sale_amt udd_amount := 0;
	v_paymentcalc_date udd_datetime;
	
	v_dr_amt udd_amount := 0;
	v_cr_amt udd_amount := 0;

	v_sale_rec record;
	v_stock_rec record;
	v_pgmember_rec record;
begin
	v_paymentcalc_date := now();
	
	-- set perishable product stock in stock table
	call pr_set_peri_productstock(_pg_id,_sale_date);
	
	-- set pgmember stock
	call pr_set_nonperi_pgmemberstockbydate(_pg_id,_sale_date);
	
	-- get sale details
	FOR v_sale_rec IN select 	s.pg_id,
								s.inv_date,
								sp.prod_type_code,
								sp.prod_code,
								sp.grade_code,
								sum(sp.sale_qty) as tot_sale_qty,
								sum(sp.sale_base_amount) as tot_sale_amt
					 from		pg_trn_tsale as s 
					 inner join pg_trn_tsaleproduct as sp on	s.pg_id 	= sp.pg_id 
														  and 	s.inv_date 	= sp.inv_date 
														  and 	s.inv_no 	= sp.inv_no
					 where 		s.pg_id 			= _pg_id 
					 and 		s.inv_date 			= _sale_date 
					 and 		sp.payment_calc_flag= 'N'
					 and 		s.status_code		= 'A'
					 group by 	s.pg_id,
								s.inv_date,
								sp.prod_type_code,
								sp.prod_code,
								sp.grade_code

	LOOP
	
		-- get product stock record
		FOR v_stock_rec IN select 	s.pg_id,
									s.prod_type_code,
									s.prod_code,
									s.grade_code,
									s.stock_date,
									(s.opening_qty+s.proc_qty-s.sale_qty) as stock_qty
						 from		pg_trn_tproductstockbydate as s
						 where 		s.pg_id 		= v_sale_rec.pg_id 
						 and 		s.prod_code 	= v_sale_rec.prod_code
						 and 		s.grade_code 	= v_sale_rec.grade_code
						 and		s.stock_date	= v_sale_rec.inv_date
						 and 		s.status_code	= 'A'
		LOOP
		
			insert into pg_trn_tsalecalc(	pg_id,
										 	paymentcalc_date,
										 	sale_date,
										 	prod_type_code,
										 	prod_code,
										 	grade_code,
										 	sale_qty,
										 	stock_qty,
										 	status_code,
										 	created_date,
										 	created_by
										 )	
										 values 
										 (
											 v_stock_rec.pg_id,
											 v_paymentcalc_date,
											 _sale_date,
											 v_stock_rec.prod_type_code,
											 v_stock_rec.prod_code,
											 v_stock_rec.grade_code,
											 v_sale_rec.tot_sale_qty,
											 v_stock_rec.stock_qty,
											 'A',
											 now(),
											 'system'
										 );
										 
			-- get pgmember total stock for the product 
			select	
					coalesce(sum(opening_qty+proc_qty-sale_qty),0) into v_tot_pgmember_stock_qty 
			from	pg_trn_tpgmemberstockbydate as s
			where 	s.pg_id 		= v_stock_rec.pg_id 
			and 	s.prod_code 	= v_stock_rec.prod_code
			and 	s.grade_code 	= v_stock_rec.grade_code
			and		s.stock_date	= v_stock_rec.stock_date
			and 	s.status_code	= 'A';
			
			v_tot_pgmember_stock_qty := coalesce(v_tot_pgmember_stock_qty,0);
			
			-- get pgmember stock record
			FOR v_pgmember_rec IN select	
										s.pg_id,
										s.pgmember_id,
										s.prod_type_code,
										s.prod_code,
										s.grade_code,
										s.stock_date,
										(s.opening_qty+s.proc_qty - s.sale_qty) as stock_qty
							 from		pg_trn_tpgmemberstockbydate as s
							 where 		s.pg_id 		= v_stock_rec.pg_id 
							 and 		s.prod_code 	= v_stock_rec.prod_code
							 and 		s.grade_code 	= v_stock_rec.grade_code
							 and		s.stock_date	= v_stock_rec.stock_date 
							 and 		s.status_code	= 'A'
							 
							 
			LOOP
			
			if v_tot_pgmember_stock_qty > 0 then
					v_calc_sale_qty := (v_pgmember_rec.stock_qty/v_tot_pgmember_stock_qty)*v_sale_rec.tot_sale_qty;
					v_calc_sale_amt := (v_pgmember_rec.stock_qty/v_tot_pgmember_stock_qty)*v_sale_rec.tot_sale_amt;
			end if;
				
			
				v_dr_amt := 0;
				v_cr_amt := 0;
				
				if v_calc_sale_amt > 0 then
					v_dr_amt = v_calc_sale_amt;
				else
					v_cr_amt = v_calc_sale_amt * (-1.0);
				end if;
				
				-- update stock in pgmember stock table
				update 	pg_trn_tpgmemberstock set
						sale_qty 	= sale_qty + v_calc_sale_qty,
						updated_date= now(),
						updated_by	= 'system'
				where 	pg_id 		= v_pgmember_rec.pg_id 
				and		pgmember_id = v_pgmember_rec.pgmember_id 
				and 	prod_code 	= v_pgmember_rec.prod_code
				and 	grade_code 	= v_pgmember_rec.grade_code
				and 	status_code	= 'A';

				update 	pg_trn_tpgmemberstockbydate set
						sale_qty 	= sale_qty + v_calc_sale_qty,
						updated_date= now(),
						updated_by	= 'system'
				where 	pg_id 		= v_pgmember_rec.pg_id 
				and		pgmember_id = v_pgmember_rec.pgmember_id 
				and 	prod_code 	= v_pgmember_rec.prod_code
				and 	grade_code 	= v_pgmember_rec.grade_code
				and 	stock_date 	= v_pgmember_rec.stock_date
				and 	status_code	= 'A';
				
				if (v_pgmember_rec.prod_type_code = 'N') then
					update 	pg_trn_tpgmemberstockbydate set
							opening_qty 	= opening_qty - v_calc_sale_qty,
							updated_date	= now(),
							updated_by		= 'system'
					where 	pg_id 			= v_pgmember_rec.pg_id 
					and		pgmember_id 	= v_pgmember_rec.pgmember_id 
					and 	prod_code 		= v_pgmember_rec.prod_code
					and 	grade_code 		= v_pgmember_rec.grade_code
					and 	stock_date 		> v_pgmember_rec.stock_date
					and 	status_code		= 'A';
				end if;
				

				-- insert record in pgmembersalecalc table
				insert into pg_trn_tpgmembersalecalc
							(
								pg_id,
								pgmember_id,
								paymentcalc_date,
								sale_date,
								prod_type_code,
								prod_code,
								grade_code,
								calc_source_code,
								calc_applied_qty,
								stock_qty,
								dr_amount,
								cr_amount,
								status_code,
								created_date,
								created_by
							)
							values
							(
								v_pgmember_rec.pg_id,
								v_pgmember_rec.pgmember_id,
								v_paymentcalc_date,
								_sale_date,
								v_pgmember_rec.prod_type_code,
								v_pgmember_rec.prod_code,
								v_pgmember_rec.grade_code,
								'QCD_SALES',
								v_calc_sale_qty,
								v_pgmember_rec.stock_qty,
								v_dr_amt,
								v_cr_amt,
								'A',
								now(),
								'system'
							);
			END LOOP;
		END LOOP;

		-- update payment process status in saleproduct table
		update 	pg_trn_tsaleproduct 
		set		payment_calc_flag	= 'Y',
				paymentcalc_date	= v_paymentcalc_date
		where 	pg_id 				= v_sale_rec.pg_id
		and 	inv_date			= v_sale_rec.inv_date
		and		prod_code			= v_sale_rec.prod_code
		and 	grade_code			= v_sale_rec.grade_code;
	END LOOP;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_pgmembersaleledger(_pg_id udd_code)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 27-02-2022
		
		Updated By : Vijayavel J
		Updated Date : 14-03-2022
		
		SP Code : B01MSLRUN (MSL - PG Member Sale Ledger)
	*/
	v_tran_date udd_datetime;
	v_succ_msg udd_text;

	v_dr_amount udd_amount := 0;
	v_cr_amount udd_amount := 0;
	v_tran_narration	 udd_text:= '';
	v_pgmemberledger_gid udd_int := 0;
	v_salecalc_rec record;
begin
	v_tran_date := now();
	
	-- get sale calc details
	FOR v_salecalc_rec IN select 	
								s.pgmembersalecalc_gid,
								s.pg_id,
								s.pgmember_id,
								s.calc_source_code,
								(s.cr_amount+(s.dr_amount*-1.0)) as tran_amount,
								s.prod_code,
								s.grade_code,
								s.sale_date,
								s.calc_applied_qty,
								p.uom_code
					 from		pg_trn_tpgmembersalecalc as s
					 left join	core_mst_tproduct as p 
					 on			s.prod_code 			= p.prod_code
					 and		p.status_code 			= 'A'
					 where 		s.pg_id 				= _pg_id 
					 and 		s.ledger_tran_flag		= 'N'
					 and 		s.status_code			= 'A'
					 order by sale_date
	LOOP
		v_dr_amount := 0;
		v_cr_amount := 0;
		v_pgmemberledger_gid := 0;
		
		if v_salecalc_rec.tran_amount > 0 then
			v_cr_amount = v_salecalc_rec.tran_amount;
			v_tran_narration := 'Invoice Adjusted ' 
				 || fn_get_productdesc(v_salecalc_rec.prod_code,'en_US') || '/'
				 || fn_get_masterdesc('QCD_GRADE',v_salecalc_rec.grade_code,'en_US') || '/'
				 || round(v_salecalc_rec.calc_applied_qty,2)::udd_text || ' '
				 || v_salecalc_rec.uom_code;
		else
			v_dr_amount = v_salecalc_rec.tran_amount * (-1.0);
			v_tran_narration := 'Sale of ' 
				 || fn_get_productdesc(v_salecalc_rec.prod_code,'en_US') || '/'
				 || fn_get_masterdesc('QCD_GRADE',v_salecalc_rec.grade_code,'en_US') || '/'
				 || round(v_salecalc_rec.calc_applied_qty,2)::udd_text || ' '
				 || v_salecalc_rec.uom_code;
		end if;
						 
		 -- || fn_get_masterdesc('QCD_UOM',v_salecalc_rec.uom_code,'en_US'); 

		-- insert in pgmember ledger table
			call pr_iud_pgmemberledger
				(
					v_pgmemberledger_gid,
					v_salecalc_rec.pg_id,
					v_salecalc_rec.pgmember_id,
					v_salecalc_rec.calc_source_code,
					v_salecalc_rec.sale_date,
					v_dr_amount,
					v_cr_amount,
					v_tran_narration,
					'',
					'',
					'A',
					'',
					'en_US',
					'admin',
					'I',
					v_succ_msg
				);
		
		-- update in pgmemberpaymentcalc table
		update 	pg_trn_tpgmembersalecalc
		set		ledger_tran_flag 	= 'Y',
				tran_date 			= v_tran_date,
				updated_date		= now(),
				updated_by			= 'system'
		where	pgmembersalecalc_gid= v_salecalc_rec.pgmembersalecalc_gid
		and		ledger_tran_flag 	= 'N'
		and		status_code			= 'A';
	END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_pgpaymentprocess(_pg_id udd_code)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 15-03-2022
		SP Code : B01PPYRUN (PPY - PG Payment Run)
	*/
	v_inv_date 	udd_date;
	v_pg_id		udd_code;
	
	v_rec record;
begin
	-- get sale calc details
	FOR v_rec IN select a.tran_date from 
					(
						select	inv_date as tran_date
						from	pg_trn_tsaleproduct
						where 	pg_id 				= _pg_id 
						and 	payment_calc_flag	= 'N'
						and 	status_code			= 'A'
						
						union 
						
						select	proc_date as tran_date
						from	pg_trn_tprocurecost
						where 	pg_id 				= _pg_id 
						and 	payment_calc_flag	= 'N'
						and 	status_code			= 'A'
						
						union 
						
						select 	tran_date 
						from	pg_trn_tpgfundledger 
						where 	pg_id 				= _pg_id 
						and		recovery_flag		= 'Y'
						and 	recovered_flag		= 'N'
						and		dr_amount			> 0 
						and 	payment_calc_flag	= 'N'
						and 	status_code			= 'A'
					) as a 

	LOOP
		call pr_run_pgmembersalebrkp(_pg_id,v_rec.tran_date);
		call pr_run_pgmembersaleledger(_pg_id);

		call pr_run_pgmemberproccostbrkp(_pg_id,v_rec.tran_date);
		call pr_run_pgmemberproccostledger(_pg_id);
		
		call pr_run_pgmembercommbrkp(_pg_id,v_rec.tran_date);
		call pr_run_pgmembercommledger(_pg_id);
	END LOOP;
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_run_undopaymentprocess()
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
		SP Code : B01PAYUDO (PAY - Payment Run)
	*/
begin
	update pg_trn_tprocure set status_code = 'I';
	update pg_trn_tprocureproduct set status_code = 'I';
	update pg_trn_tsaleproduct set payment_calc_flag = 'N',paymentcalc_date = null,status_code = 'I';
	update pg_trn_tprocurecost set payment_calc_flag = 'N',paymentcalc_date = null;
	update pg_trn_tpgfundledger set recovered_flag = 'N',
									payment_calc_flag = 'N',
									paymentcalc_date = null 
								where payment_calc_flag = 'Y';

	delete from pg_trn_tproductstock;
	delete from pg_trn_tproductstockbydate;
	delete from pg_trn_tpgmemberstock;
	delete from pg_trn_tpgmemberstockbydate;
	delete from pg_trn_tsalecalc;
	delete from pg_trn_tpgmembersalecalc;
	delete from pg_trn_tpgmemberproccostcalc;
	delete from pg_trn_tpgmemberproccostcalcdtl;
	delete from pg_trn_tpgmembercommcalc;
	delete from pg_trn_tpgmembercommcalcdtl;
	delete from pg_trn_tpgmemberledger;
	delete from pg_trn_tpgmemberledgersumm;

	update pg_trn_tprocure set status_code = 'A';
	update pg_trn_tprocureproduct set status_code = 'A';
	update pg_trn_tsaleproduct set status_code = 'A';
	update pg_trn_tprocurecost set status_code = 'A';
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_bussplandelete(_pg_id udd_code, _bussplan_id udd_code, _prod_code udd_code)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 14-03-2022
		SP Code : B04BPPXXD
	*/
begin	
	
		-- bussplanproduct delete
		delete from pg_trn_tbussplanproduct
		where  		pg_id = _pg_id
		and    		bussplan_id 	= _bussplan_id
		and    		prod_code = _prod_code;

		-- bussplanproduce delete
		delete from pg_trn_tbussplanproduce
		where  		pg_id = _pg_id
		and   		bussplan_id 	= _bussplan_id
		and    		prod_code = _prod_code;
		
		-- bussplanfinyear delete
		delete from pg_trn_tbussplanfinyear
		where  		pg_id = _pg_id
		and    		bussplan_id 	= _bussplan_id
		and    		prod_code = _prod_code;

		
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_bussplanproduce(INOUT _bussplanproduce_gid udd_int, _pg_id udd_code, _bussplan_id udd_code, _finyear_id udd_code, _produce_month udd_date, _prod_type_code udd_code, _prod_code udd_code, _uom_code udd_code, _sowing_flag udd_code, _harvesting_qty udd_qty, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 04-03-2022
		SP Code : B04BPPXUX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);

begin	
	-- validation
	-- pg id validation
	if not exists (select   * 
				   from 	pg_mst_tproducergroup
				   where 	pg_id = _pg_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB05FDBCUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB05FDBCUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- bussplan id validation 
	if not exists (select   * 
				   from 	pg_trn_tbussplan
				   where 	bussplan_id = _bussplan_id
				   and 		pg_id = _pg_id
				  )then
		v_err_code := v_err_code || 'VB00CMNCMN_018' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_018', _lang_code) || v_new_line;	
	end if;
	
	-- prod code validation
	if not exists (select 	* 
				   from 	core_mst_tproduct 
				   where 	prod_code = _prod_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_016', _lang_code) || v_new_line;	
	end if;
	
	-- prod type code validation
	if(_prod_type_code = '')then 
		select 		prod_type_code into _prod_type_code
		from 		core_mst_tproduct 
		where 		prod_code = _prod_code
	    and 		status_code = 'A';
		
	else
		if not exists (select 		*
						from 		core_mst_tproduct
						where 		prod_type_code = _prod_type_code
					    and         prod_code = _prod_code
	    				and 		status_code = 'A')then
		v_err_code := v_err_code || 'VB00CMNCMN_015' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_015', _lang_code) || v_new_line;
		end if;
	end if;
	
	-- uom code validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_UOM'
				   and 		master_code = _uom_code 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_019' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_019', _lang_code)|| v_new_line;	
	end if;
	
	-- finyear id validation 
	if not exists (select   * 
				   from 	core_mst_tfinyear
				   where 	finyear_id = _finyear_id
				   and 		status_code = 'A'
				  )then
		v_err_code := v_err_code || 'VB04BPECUD_001' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_001', _lang_code) || v_new_line;	
	end if;
	
	-- sowing flag validation
	if not exists (select 	* 
				   from 	core_mst_tmaster 
				   where 	parent_code = 'QCD_YES_NO'
				   and 		master_code = _sowing_flag 
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB04BPECUD_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_004', _lang_code);	
	end if;
	
	-- harvesting qty validation
	if _harvesting_qty < 0 then
		v_err_code := v_err_code || 'VB04BPECUD_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_003', _lang_code) || v_new_line;
	end if;
	
	-- sowing and harvesting validation
	/*if _sowing_flag = 'Y' and _harvesting_qty > 0 then
		v_err_code := v_err_code || 'VB04BPECUD_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_005', _lang_code);	
	end if;*/
	
	-- language code validation
	if not exists (select 	* 
				   from 	core_mst_tlanguage 
				   where 	lang_code = _lang_code
				   and 		status_code = 'A'
				  ) then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code);	
	end if;

	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if (_mode_flag = 'U') then 
		if  exists(select 	*
				   from 	pg_trn_tbussplanproduce
				   where	bussplanproduce_gid = _bussplanproduce_gid
				   ) then
			update	pg_trn_tbussplanproduce 
			set 	pg_id = _pg_id,
					bussplan_id = _bussplan_id,
					finyear_id = _finyear_id,
					produce_month = _produce_month,
					prod_type_code = _prod_type_code,
					prod_code = _prod_code,
					uom_code = _uom_code,
					sowing_flag = _sowing_flag,
					harvesting_qty = _harvesting_qty,
					updated_by = _user_code,
					updated_date = now()
			where 	bussplanproduce_gid = _bussplanproduce_gid;
			
			v_succ_code := 'SB04BPECUD_002';
		else
			v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
		end if;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := fn_get_msg(v_succ_code,_lang_code);
	end if;
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_bussplanproducejson(_bussplanproduce udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 04-03-2022
		SP Code : B04BPEXUX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	
	v_pg_id udd_code := '';
	v_bussplan_id udd_code := '';
	
	v_colrec record;
	v_colrec_prod record;
	v_colrec_prod_mnth record;

begin
	 FOR v_colrec IN select * from jsonb_to_recordset(_bussplanproduce::udd_jsonb) as items 
													(
														bussplanproduce_gid udd_int,
														pg_id udd_code,
														bussplan_id udd_code,
														finyear_id udd_code,
														produce_month udd_date,
														prod_type_code udd_code,
														prod_code udd_code,
														uom_code udd_code,
														sowing_flag udd_code,
														harvesting_qty udd_qty,
														lang_code udd_code,
														user_code udd_code,
														mode_flag udd_flag,
														succ_msg udd_text
														) 
												
			LOOP 
			--v_colrec.harvesting_qty := coalesce(v_colrec.harvesting_qty,0);
			-- sowing and harvesting validation
			/*if v_colrec.sowing_flag = 'Y' and v_colrec.harvesting_qty > 0 then
				v_err_code := v_err_code || 'VB04BPECUD_005';
				v_err_msg  := v_err_msg ||  fn_get_msg('VB04BPECUD_005', v_colrec.lang_code) || v_new_line;	
				
				raise exception '%',v_err_code || '-' || v_err_msg;
			end if;*/
			
			v_pg_id := v_colrec.pg_id;
			v_bussplan_id := v_colrec.bussplan_id;
			
			call pr_set_bussplanproduce(
									   v_colrec.bussplanproduce_gid,
									   v_colrec.pg_id,
									   v_colrec.bussplan_id,
									   v_colrec.finyear_id,
									   v_colrec.produce_month,
									   v_colrec.prod_type_code,
									   v_colrec.prod_code,
									   v_colrec.uom_code,
									   v_colrec.sowing_flag,
									   v_colrec.harvesting_qty,
									   v_colrec.lang_code,
									   v_colrec.user_code,
									   v_colrec.mode_flag,
									   v_colrec.succ_msg);
										
			END LOOP;
			 -- Sowing flag validation
			 FOR v_colrec_prod IN select distinct prod_code from pg_trn_tbussplanproduce
								  where pg_id = v_pg_id 
								  and bussplan_id = v_bussplan_id
												
				LOOP 
					 FOR v_colrec_prod_mnth IN select produce_month 
					 						   from pg_trn_tbussplanproduce
											   where pg_id = v_pg_id 
											   and bussplan_id = v_bussplan_id
											   and sowing_flag = 'Y'
											   and  prod_code = v_colrec_prod.prod_code
					Loop 
			
					if not exists ( select * from pg_trn_tbussplanproduce
									where pg_id =  v_pg_id
									and bussplan_id = v_bussplan_id
									and produce_month > v_colrec_prod_mnth.produce_month 
									and prod_code = v_colrec_prod.prod_code
									and harvesting_qty > 0)  then 
							v_err_code := v_err_code || 'VB00CMNCMN_023' || ',';
							v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_023', 'en_US') || v_new_line;		
							raise exception '%',v_err_code || '-' || v_err_msg;
					end if;
					
				end loop;
			end loop;
			
			 -- Harvesting qty validation
			 FOR v_colrec_prod IN select distinct prod_code from pg_trn_tbussplanproduce
								  where pg_id = v_pg_id 
								  and bussplan_id = v_bussplan_id
												
				LOOP 
					 FOR v_colrec_prod_mnth IN select produce_month 
					 						   from pg_trn_tbussplanproduce
											   where pg_id = v_pg_id 
											   and bussplan_id = v_bussplan_id
											   and harvesting_qty > 0
											   and  prod_code = v_colrec_prod.prod_code
					Loop 
					
					if not exists ( select * from pg_trn_tbussplanproduce
									where pg_id =  v_pg_id
									and bussplan_id = v_bussplan_id
									and produce_month < v_colrec_prod_mnth.produce_month 
									and prod_code = v_colrec_prod.prod_code
									and sowing_flag = 'Y')  then 
							v_err_code := v_err_code || 'VB00CMNCMN_024' || ',';
							v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_024', 'en_US') || v_new_line;		
							raise exception '%',v_err_code || '-' || v_err_msg;
					end if;
					
				end loop;
			end loop;
			
			select 'Bussplan Produce Updated Successfully' into _succ_msg;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_invoiceadjustment(INOUT _sale_gid udd_int, INOUT _saleprod_gid udd_int, _pg_id udd_code, _inv_no udd_code, _adjust_type_code udd_code, _adjust_date udd_date, _prod_code udd_code, _grade_code udd_code, _sale_qty udd_qty, _inv_qty udd_qty, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 17-08-2022
		SP Code      : B04COLXUX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	
	v_inv_date udd_date := null;
	v_sale_qty udd_qty := 0;
	v_oldsale_amount udd_amount := 0;
	v_oldinv_amount udd_amount := 0;
	v_sale_rate udd_rate := 0;
	v_oldsaleprod_amount udd_amount := 0;
	v_newsale_amount udd_amount := 0;
	v_newsaleprod_amount udd_amount := 0;
	v_newinv_amount  udd_amount := 0;
begin
	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- Invoice no empty validation
	if _inv_no = '' then
		v_err_code := v_err_code || 'VB04COLXUX_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB04COLXUX_001', _lang_code) || v_new_line;
	end if;
	
	-- Adjust Type Code Validation

	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_ADJUST_TYPE' 
				   and master_code = _adjust_type_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB04COLXUX_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_002', _lang_code) || v_new_line;		
	end if;	
	
	-- Adjust date validation
	if _adjust_date >  CURRENT_DATE then
		v_err_code := v_err_code || 'VB04COLXUX_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_003', _lang_code) || v_new_line;		
	end if;
	
	-- Get invoice amount,invoice date
	if exists (select * from pg_trn_tsale
			   where 	pg_id = _pg_id
			   and 	 	inv_no = _inv_no
			   and 	 	status_code = 'A')then
			   
		   select 	inv_amount,inv_date 
		   into 	v_oldinv_amount,v_inv_date
		   from 	pg_trn_tsale
		   where 	pg_id = _pg_id
		   and 	 	inv_no = _inv_no
		   and 	 	status_code = 'A';
		   
		   v_oldinv_amount := coalesce(v_oldinv_amount,0);		   		   
	 end if;
	
	-- adjust date should be greater than sale date
	if v_inv_date > _adjust_date  then
		v_err_code := v_err_code || 'VB04COLXUX_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_004', _lang_code) || v_new_line;		
	end if;
	
	-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code = _prod_code 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
	-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and master_code = _grade_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;	
	
	-- sale qty validation
	if _sale_qty < 0 then
		v_err_code := v_err_code || 'VB04COLXUX_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_005', _lang_code) || v_new_line;		
	end if;
	
	-- Get sale rate and sale amount
	if exists (select * from pg_trn_tsaleproduct
			   where pg_id       = _pg_id
			   and 	 inv_no      = _inv_no
			   and   prod_code   = _prod_code
			   and   grade_code  = _grade_code
			   and 	 status_code = 'A')then
			   
		select sale_rate, sale_amount,sale_qty
		into   v_sale_rate,v_oldsale_amount,v_sale_qty
		from   pg_trn_tsaleproduct
		where  pg_id       = _pg_id
		and    inv_no      = _inv_no
-- 		and    rec_slno    = _rec_slno
		and    prod_code   = _prod_code
		and    grade_code  = _grade_code;
		
		v_sale_rate      := coalesce(v_sale_rate,0);
		v_oldsale_amount := coalesce(v_oldsale_amount,0);
		v_sale_qty      := coalesce(v_sale_qty,0);
		
	end if;
	
	-- inv_qty validation
	if _inv_qty > v_sale_qty then
		v_err_code := v_err_code || 'VB04COLXUX_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_006', _lang_code) || v_new_line;		
	end if;
	
	-- Get new sale product amount
	v_newsale_amount := v_sale_rate * _inv_qty;
	v_newinv_amount  := v_oldinv_amount - v_oldsale_amount + v_newsale_amount;
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code = _lang_code
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;

	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
		
	if _mode_flag = 'U' then 
		 update pg_trn_tsale 
		 set    inv_amount   = v_newinv_amount,
		 		updated_date = now(),
				updated_by   = _user_code
		 where  pg_id        = _pg_id
		 and    inv_no       = _inv_no
		 and 	status_code  = 'A';
		 
		 update pg_trn_tsaleproduct
		 set    sale_amount      = v_newsale_amount,
		 		sale_base_amount = v_newsale_amount,
		 		adjust_type_code = _adjust_type_code,
				adjust_date      = _adjust_date,
				inv_qty          = _inv_qty,
				updated_date     = now(),
				updated_by       = _user_code
		 where  pg_id       = _pg_id
		 and    inv_no      = _inv_no
		 and    prod_code   = _prod_code
		 and    grade_code  = _grade_code
		 and    status_code = 'A';
		 
		 v_succ_code := 'SB00CMNCMN_002';
	else
		    v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;

	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_invoiceadjustment(INOUT _sale_gid udd_int, INOUT _saleprod_gid udd_int, _pg_id udd_code, _inv_no udd_code, _adjust_type_code udd_code, _adjust_date udd_date, _prod_code udd_code, _grade_code udd_code, _sale_qty udd_qty, _inv_qty udd_qty, _rec_slno udd_int, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 17-08-2022
		SP Code      : B04COLXUX
	*/
	v_err_code 	udd_text := '';
	v_err_msg 	udd_text := '';
	v_succ_code udd_text := '';
	v_new_line text = chr(13)||chr(10);
	
	v_inv_date udd_date := null;
	v_sale_qty udd_qty := 0;
	v_oldsale_amount udd_amount := 0;
	v_oldinv_amount udd_amount := 0;
	v_sale_rate udd_rate := 0;
	v_oldsaleprod_amount udd_amount := 0;
	v_newsale_amount udd_amount := 0;
	v_newsaleprod_amount udd_amount := 0;
	v_newinv_amount  udd_amount := 0;
begin
	-- PG ID Validation
	if not exists (select * from pg_mst_tproducergroup
				   where pg_id = _pg_id 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_004' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_004', _lang_code) || v_new_line;
	end if;	
	
	-- Invoice no empty validation
	if _inv_no = '' then
		v_err_code := v_err_code || 'VB04COLXUX_001' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB04COLXUX_001', _lang_code) || v_new_line;
	end if;
	
	-- Adjust Type Code Validation

	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_ADJUST_TYPE' 
				   and master_code = _adjust_type_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB04COLXUX_002' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_002', _lang_code) || v_new_line;		
	end if;	
	
	-- Adjust date validation
	if _adjust_date >  CURRENT_DATE then
		v_err_code := v_err_code || 'VB04COLXUX_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_003', _lang_code) || v_new_line;		
	end if;
	
	-- Get invoice amount,invoice date
	if exists (select * from pg_trn_tsale
			   where 	pg_id = _pg_id
			   and 	 	inv_no = _inv_no
			   and 	 	status_code = 'A')then
			   
		   select 	inv_amount,inv_date 
		   into 	v_oldinv_amount,v_inv_date
		   from 	pg_trn_tsale
		   where 	pg_id = _pg_id
		   and 	 	inv_no = _inv_no
		   and 	 	status_code = 'A';
		   
		   v_oldinv_amount := coalesce(v_oldinv_amount,0);		   		   
	 end if;

	-- adjust date should be greater than sale date
	if v_inv_date > _adjust_date  then
		v_err_code := v_err_code || 'VB04COLXUX_004' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_004', _lang_code) || v_new_line;		
	end if;
	
	-- Product Code Validation
	if not exists (select * from core_mst_tproduct
				   where prod_code = _prod_code 
				   and status_code = 'A')
	then
		v_err_code := v_err_code || 'VB00CMNCMN_016' || ',';
		v_err_msg  := v_err_msg || fn_get_msg ('VB00CMNCMN_016', _lang_code) || v_new_line;
	end if;	
	
	-- Grade Code Validation
	if not exists (select * from core_mst_tmaster 
				   where parent_code = 'QCD_GRADE' 
				   and master_code = _grade_code 
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_017' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_017', _lang_code) || v_new_line;		
	end if;	
	
	-- sale qty validation
	if _sale_qty < 0 then
		v_err_code := v_err_code || 'VB04COLXUX_005' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_005', _lang_code) || v_new_line;		
	end if;
	
	-- Get sale rate and sale amount
	if exists (select * from pg_trn_tsaleproduct
			   where pg_id       = _pg_id
			   and 	 inv_no      = _inv_no
			   and   prod_code   = _prod_code
			   and   grade_code  = _grade_code
			   and 	 status_code = 'A')then
			   
		select sale_rate, sale_amount,sale_qty
		into   v_sale_rate,v_oldsale_amount,v_sale_qty
		from   pg_trn_tsaleproduct
		where  pg_id       = _pg_id
		and    inv_no      = _inv_no
		and    rec_slno    = _rec_slno
		and    prod_code   = _prod_code
		and    grade_code  = _grade_code;
		
		v_sale_rate      := coalesce(v_sale_rate,0);
		v_oldsale_amount := coalesce(v_oldsale_amount,0);
		v_sale_qty      := coalesce(v_sale_qty,0);
			raise notice '%',v_sale_rate;
			raise notice '%',v_oldsale_amount;
			raise notice '%',v_sale_qty;
	end if;
	
	-- inv_qty validation
	if _inv_qty > v_sale_qty then
		v_err_code := v_err_code || 'VB04COLXUX_006' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB04COLXUX_006', _lang_code) || v_new_line;		
	end if;
	
	-- Get new sale product amount
	v_newsale_amount := v_sale_rate * _inv_qty;
-- 	v_newinv_amount  := v_oldinv_amount - v_oldsale_amount + v_newsale_amount;
	
	-- language code validation
	if not exists (select * from core_mst_tlanguage 
				   where lang_code = _lang_code
				   and status_code = 'A') 
	then
		v_err_code := v_err_code || 'VB00CMNCMN_003' || ',';
		v_err_msg  := v_err_msg ||  fn_get_msg('VB00CMNCMN_003', _lang_code) || v_new_line;		
	end if;

	
	if length(v_err_code) > 0 then
		v_err_code := substring(v_err_code,1,length(v_err_code)-1);
		RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
		
	if _mode_flag = 'U' then 
		 
		 
		 update pg_trn_tsaleproduct
		 set    sale_amount      = v_newsale_amount,
		 		sale_base_amount = v_newsale_amount,
		 		adjust_type_code = _adjust_type_code,
				adjust_date      = _adjust_date,
				inv_qty          = _inv_qty,
				updated_date     = now(),
				updated_by       = _user_code
		 where  pg_id       = _pg_id
		 and    inv_no      = _inv_no
		 and    prod_code   = _prod_code
		 and    grade_code  = _grade_code
		 and    rec_slno    = _rec_slno
		 and    status_code = 'A';
		 
		 select sum(sale_base_amount) into v_newinv_amount
		 from   pg_trn_tsaleproduct
		 where  pg_id        = _pg_id
		 and    inv_no       = _inv_no;
		 
		 update pg_trn_tsale 
		 set    inv_amount   = v_newinv_amount,
		 		updated_date = now(),
				updated_by   = _user_code
		 where  pg_id        = _pg_id
		 and    inv_no       = _inv_no
		 and 	status_code  = 'A';
		 
		 v_succ_code := 'SB00CMNCMN_002';
	else
		    v_err_code := v_err_code || 'EB00CMNCMN_003';
			v_err_msg  := v_err_msg ||  fn_get_msg('EB00CMNCMN_003', _lang_code) || v_new_line;	
			
			RAISE EXCEPTION '%',v_err_code || '-' || v_err_msg;
	end if;
	
	if(v_succ_code <> '' )then
			_succ_msg := v_succ_code || '-' || fn_get_msg(v_succ_code,_lang_code);
	end if;

	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_nonperi_pgmemberstockbydate(_pg_id udd_code, _stock_date udd_date)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 14-03-2022
		SP Code : B01SMSSET (SMS - Set @PG Member Stock Non-Perishable by stock date)
	*/
	
	v_colrec record;
begin
	 -- update procurement @product level
	 FOR v_colrec IN select 	p.pg_id,
								p.pgmember_id,
								p.prod_type_code,
								p.prod_code,
								p.grade_code,
								p.uom_code
					 from		pg_trn_tpgmemberstock as p 
					 left join  pg_trn_tpgmemberstockbydate as d on  p.pg_id 	= d.pg_id 
															 and p.pgmember_id 	= d.pgmember_id
															 and p.prod_code	= d.prod_code
															 and p.grade_code	= d.grade_code
															 and d.stock_date 	= _stock_date
															 and d.status_code  = 'A'
					 where 	p.pg_id 			= _pg_id 
					 and 	p.prod_type_code 	= 'N' 
					 and	d.pg_id				is null
					 and 	p.status_code		= 'A'
	LOOP
		if (fn_get_pgmemberopeningqty(v_colrec.pg_id,
									  v_colrec.pgmember_id,
									  _stock_date,
									  v_colrec.prod_code,
									  v_colrec.grade_code) > 0) then
			insert into pg_trn_tpgmemberstockbydate
					(
						pg_id,
						pgmember_id,
						prod_type_code,
						prod_code,
						grade_code,
						uom_code,
						stock_date,
						opening_qty,
						proc_qty,
						status_code,
						created_date,
						created_by
					)
					select
						v_colrec.pg_id,
						v_colrec.pgmember_id,
						v_colrec.prod_type_code,
						v_colrec.prod_code,
						v_colrec.grade_code,
						v_colrec.uom_code,
						_stock_date,
						fn_get_pgmemberopeningqty(v_colrec.pg_id,
												  v_colrec.pgmember_id,
												  _stock_date,
												  v_colrec.prod_code,
												  v_colrec.grade_code),
						0,
						'A',
						now(),
						'system';
		end if;
	END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_peri_productstock(_pg_id udd_code, _stock_date udd_date)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Vijayavel J
		Created Date : 27-02-2022
		SP Code : B01SPPSET (SPP - Stock @ProductLevel Perishable)
	*/
	
	v_colrec record;
	
begin
	-- set perishable qty zero in product stock
	 update pg_trn_tproductstock 
	 set	proc_qty 		= 0,
			sale_qty		= 0,
	 		stock_qty 		= 0
	 where	pg_id 			= _pg_id 
	 and 	prod_type_code 	= 'P';

	-- set perishable qty zero in pgmember stock
	 update pg_trn_tpgmemberstock  
	 set 	proc_qty 		= 0
	 where	pg_id 			= _pg_id 
	 and 	prod_type_code 	= 'P';

	 -- update procurement @product level
	 FOR v_colrec IN select 	p.pg_id,
								p.proc_date,
								pp.prod_type_code,
								pp.prod_code,
								pp.grade_code,
								sum(pp.proc_qty) as tot_proc_qty
					 from		pg_trn_tprocure as p 
					 inner join pg_trn_tprocureproduct as pp on  p.pg_id 		= pp.pg_id 
					 										 and p.session_id 	= pp.session_id 
															 and p.pgmember_id 	= pp.pgmember_id
															 and p.proc_date 	= pp.proc_date 
					 where 	p.pg_id 			= _pg_id 
					 and 	p.proc_date 		= _stock_date 
					 and 	pp.prod_type_code 	= 'P' 
					 and 	p.status_code		= 'A'
					 group by p.pg_id,
							p.proc_date,
							pp.prod_type_code,
							pp.prod_code,
							pp.grade_code

	LOOP 
	insert into pg_trn_tproductstock (			
											pg_id,
											prod_type_code,
											prod_code,
											grade_code,
											proc_qty,
											stock_qty,
											status_code,
											created_date,
											created_by
										)
								values	(
											v_colrec.pg_id,
											v_colrec.prod_type_code,
											v_colrec.prod_code,
											v_colrec.grade_code,
											v_colrec.tot_proc_qty,
											v_colrec.tot_proc_qty,
											'A',
											now(),
											'system'
										)
				on CONFLICT ( 	pg_id,
								prod_type_code,
								prod_code,
								grade_code)  
							 do update set  
								proc_qty 	= v_colrec.tot_proc_qty,
								stock_qty 	= v_colrec.tot_proc_qty;

	END LOOP;

	 -- update sale @product level
	 FOR v_colrec IN select 	s.pg_id,
								s.inv_date,
								sp.prod_type_code,
								sp.prod_code,
								sp.grade_code,
								sum(sp.sale_qty) as tot_sale_qty
					 from		pg_trn_tsale as s 
					 inner join pg_trn_tsaleproduct as sp on  s.pg_id 	= sp.pg_id 
															 and s.inv_date = sp.inv_date 
															 and s.inv_no 	= sp.inv_no
					 where 	s.pg_id 			= _pg_id 
					 and 	s.inv_date 			= _stock_date 
					 and 	sp.prod_type_code 	= 'P' 
					 and 	s.status_code		= 'A'
					 group by 
					 		s.pg_id,
							s.inv_date,
							sp.prod_type_code,
							sp.prod_code,
							sp.grade_code

	LOOP 
		update 	pg_trn_tproductstock
		set		sale_qty 	= v_colrec.tot_sale_qty,
				stock_qty	= stock_qty - v_colrec.tot_sale_qty
		where 	pg_id 		= v_colrec.pg_id
		and 	prod_code 	= v_colrec.prod_code
		and 	grade_code	= v_colrec.grade_code;
	END LOOP;

	 -- update @pgmember level
	 FOR v_colrec IN select 	p.pg_id,
	 							p.pgmember_id,
								p.proc_date,
								p.pgmember_id,
								pp.prod_type_code,
								pp.prod_code,
								pp.grade_code,
								sum(pp.proc_qty) as tot_proc_qty
					 from		pg_trn_tprocure as p 
					 inner join pg_trn_tprocureproduct as pp on  p.pg_id = pp.pg_id 
					 										 and p.session_id = pp.session_id 
															 and p.pgmember_id = pp.pgmember_id
															 and p.proc_date = pp.proc_date 
					 where 		p.pg_id 			= _pg_id 
					 and 		p.proc_date 		= _stock_date 
					 and 		pp.prod_type_code 	= 'P' 
					 and 		p.status_code		= 'A'
					 group by 	p.pg_id,
					 			p.pgmember_id,
								p.proc_date,
								pp.prod_type_code,
								pp.prod_code,
								pp.grade_code

	LOOP 
	insert into pg_trn_tpgmemberstock (			
											pg_id,
											pgmember_id,
											prod_type_code,
											prod_code,
											grade_code,
											proc_qty,
											status_code,
											created_date,
											created_by
										)
								values	(
											v_colrec.pg_id,
											v_colrec.pgmember_id,
											v_colrec.prod_type_code,
											v_colrec.prod_code,
											v_colrec.grade_code,
											v_colrec.tot_proc_qty,
											'A',
											now(),
											'system'
										)
				on CONFLICT ( 	pg_id,
								pgmember_id,
								prod_type_code,
								prod_code,
								grade_code)  
							 do update set  
								proc_qty = v_colrec.tot_proc_qty;

	END LOOP;

end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_smstran(_smstran_gid udd_int, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mohan S
		Created Date : 10-03-2022
		SP Code : B04SMSXXD
	*/
begin	
			update  pg_trn_tsmstran 
			set 	status_code = 'I',
					updated_date = now(),
					updated_by = 'Admin'
			where 	smstran_gid = _smstran_gid;
			
			_succ_msg := 'Record Deleted Successfully';
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_smstranrejected(_smstran_gid udd_int, _remark udd_text, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$
declare
	/*
		Created By : Mangai
		Created Date : 30-03-2022
		SP Code : B04SMSXXU
	*/
begin	
			update  pg_trn_tsmstran 
			set 	sms_remark   = _remark,
					updated_date = now(),
					updated_by   = 'Admin'
			where 	smstran_gid  = _smstran_gid;
			
			_succ_msg := 'Record Updated Successfully';
	
end
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_usertokencompare(_user_code udd_user, _user_token udd_text, _url udd_text, INOUT _token_expired_flag udd_flag)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 10-06-2022
		SP Code      : USER TOKEN COMPARE
	*/
begin
	if exists (	select * from core_mst_tusertoken
			 	where 	user_code 	= _user_code 
			   	and  	user_token 	= _user_token
			  	and 	url 	  	= _url
			  	and 	token_expired_flag = 'N') then
		
		update 	core_mst_tusertoken 
		set 	token_expired_date = now(),
				token_expired_flag = 'Y',
				updated_date = now(),
				updated_by 	 = _user_code
		where 	user_code 	= _user_code 
		and  	user_token 	= _user_token
		and 	url 	  	= _url;
		
		_token_expired_flag := 'N';
	else 
		_token_expired_flag := 'Y';
		
	end if;
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_set_usertokenexpired(_user_code udd_user, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 21-06-2022
		SP Code      : USER TOKEN EXPIRED
	*/
begin
		update 	core_mst_tusertoken 
		set 	token_expired_date = now(),
				token_expired_flag = 'Y',
				updated_date = now(),
				updated_by 	 = _user_code
		where 	user_code 	= _user_code ;
		
		_succ_msg := 'User Token Expired Successfully...!';
	
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_sms_forgetpswd(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _forgetpassword udd_desc, _mobile_no udd_mobile, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan S
		Created Date : 31-03-2022
		SP Code      : B01FRGCXX
	*/
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_UM_FRGPSWD';
begin
	
			-- send sms
			SELECT 
					sms_template,dlt_template_id 
			into 	v_sms_template,v_dlt_template_id
			FROM 	core_mst_tsmstemplate
			where 	smstemplate_code = v_smstemplate_code
			and		lang_code = _lang_code
			and 	status_code = 'A';
			
			v_sms_template := coalesce(v_sms_template,'');
			v_dlt_template_id := coalesce(v_dlt_template_id,'');
			
			if (v_dlt_template_id <> '') then
				v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Pwd#}',_forgetpassword);
				
				-- Store procedure Call
				call pr_iud_smstran(_pg_id,
									v_smstemplate_code,
									v_dlt_template_id,
									_mobile_no,
									v_sms_template,
									_user_code,
									_role_code);
									
				_succ_msg := 'Record Created Successfully';
			end if;
			
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_sms_invoicetobuyer(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _buyer_name udd_code, _inv_date udd_date, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 18-04-2022
		SP Code      : B01INVCXX
	*/
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_pgname udd_desc := ''; 
	v_smstemplate_code udd_code := 'SMST_BUY_INVOICE';
begin
	
			-- send sms invoice to buyer
				SELECT 
					sms_template,dlt_template_id into v_sms_template,v_dlt_template_id
				FROM 	core_mst_tsmstemplate
				where 	smstemplate_code = v_smstemplate_code
				and 	lang_code = _lang_code
				and 	status_code = 'A';

				v_sms_template := coalesce(v_sms_template,'');
				v_dlt_template_id := coalesce(v_dlt_template_id,'');
				v_pgname := fn_get_pgname(_pg_id);

				if (v_dlt_template_id <> '') then
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Buyer_Name#}',_buyer_name);
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Payment_Date#}',_inv_date :: udd_text);
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#PG_Name#}',v_pgname);
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#link#}','http://169.38.77.190:82/TAC/TAC');
					
					-- Store procedure Call
					call pr_iud_smstran(_pg_id,
										v_smstemplate_code,
										v_dlt_template_id,
										'7667763488',
										v_sms_template,
										_user_code,
										'udyogmitra');
				end if;
													
				_succ_msg := 'Record Created Successfully';

end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_sms_mpin(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _forgetmpin udd_desc, _mobile_no udd_mobile, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan S
		Created Date : 28-03-2022
		SP Code      : B01MPNCXX
	*/
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_UM_MPIN';
begin
	
			-- send sms
			SELECT 
					sms_template,dlt_template_id 
			into 	v_sms_template,v_dlt_template_id
			FROM 	core_mst_tsmstemplate
			where 	smstemplate_code = v_smstemplate_code
			and		lang_code = _lang_code
			and 	status_code = 'A';
			
			v_sms_template := coalesce(v_sms_template,'');
			v_dlt_template_id := coalesce(v_dlt_template_id,'');
			
			if (v_dlt_template_id <> '') then
				v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#MPIN#}',_forgetmpin);
				
				-- Store procedure Call
				call pr_iud_smstran(_pg_id,
									v_smstemplate_code,
									v_dlt_template_id,
									_mobile_no,
									v_sms_template,
									_user_code,
									_role_code);
									
				_succ_msg := 'Record Created Successfully';
			end if;
			
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_sms_pgloginotp(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _mobile_no udd_mobile, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 08-09-2022
		SP Code      : B01OTPCUX
	*/
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_PG_OTP';
begin
	
			-- send sms credentials
				SELECT 
					sms_template,dlt_template_id into v_sms_template,v_dlt_template_id
				FROM 	core_mst_tsmstemplate
				where 	smstemplate_code = v_smstemplate_code
				and 	lang_code = _lang_code
				and 	status_code = 'A';

				v_sms_template := coalesce(v_sms_template,'');
				v_dlt_template_id := coalesce(v_dlt_template_id,'');

				if (v_dlt_template_id <> '') then
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#otp#}',_otp);

					-- Store procedure Call
					call pr_iud_smstran(_pg_id,
										v_smstemplate_code,
										v_dlt_template_id,
										_mobile_no,
										v_sms_template,
										_user_code,
										'Udyogmitra');
				end if;
									
				_succ_msg := 'Record Created Successfully';

			
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_sms_pgloginotp(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _mobile_no udd_mobile, _otp udd_mobile, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan
		Created Date : 08-09-2022
		SP Code      : B01OTPCUX
	*/
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_PG_OTP';
begin
	
			-- send sms credentials
				SELECT 
					sms_template,dlt_template_id into v_sms_template,v_dlt_template_id
				FROM 	core_mst_tsmstemplate
				where 	smstemplate_code = v_smstemplate_code
				and 	lang_code = _lang_code
				and 	status_code = 'A';

				v_sms_template := coalesce(v_sms_template,'');
				v_dlt_template_id := coalesce(v_dlt_template_id,'');

				if (v_dlt_template_id <> '') then
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#otp#}',_otp);

					-- Store procedure Call
					call pr_iud_smstran(_pg_id,
										v_smstemplate_code,
										v_dlt_template_id,
										_mobile_no,
										v_sms_template,
										_user_code,
										'Udyogmitra');
				end if;
									
				_succ_msg := 'Record Created Successfully';

			
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_sms_udyogmitra(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _udyogmitra_id udd_code, _password udd_desc, _mobile_no udd_mobile, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 07-04-2022
		SP Code      : B01UDMCUX
	*/
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_UM_CREDENT';
	v_smstemplate_code1 udd_code := 'SMST_UM_APPLINK';
begin
	
			-- send sms credentials
				SELECT 
					sms_template,dlt_template_id into v_sms_template,v_dlt_template_id
				FROM 	core_mst_tsmstemplate
				where 	smstemplate_code = v_smstemplate_code
				and 	lang_code = _lang_code
				and 	status_code = 'A';

				v_sms_template := coalesce(v_sms_template,'');
				v_dlt_template_id := coalesce(v_dlt_template_id,'');

				if (v_dlt_template_id <> '') then
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#User_ID#}',_udyogmitra_id);
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Password#}',_password);

					-- Store procedure Call
					call pr_iud_smstran(_pg_id,
										v_smstemplate_code,
										v_dlt_template_id,
										_mobile_no,
										v_sms_template,
										_user_code,
										'udyogmitra');
				end if;

				-- send sms app link
				SELECT 
					sms_template,dlt_template_id into v_sms_template,v_dlt_template_id
				FROM 	core_mst_tsmstemplate
				where 	smstemplate_code = v_smstemplate_code1
				and 	lang_code = _lang_code
				and 	status_code = 'A';

				v_sms_template := coalesce(v_sms_template,'');
				v_dlt_template_id := coalesce(v_dlt_template_id,'');

				if (v_dlt_template_id <> '') then
					-- Previous Version
 					-- v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Google_Drive_Link#}','http://bitly.ws/szDa');
					-- v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Google_Drive_Link#}','https://bit.ly/3x2PChu');
 					-- Below link is for Uat app link 
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Google_Drive_Link#}','https://bit.ly/3Hx2ikR');
					

					-- Store procedure Call
					call pr_iud_smstran(_pg_id,
										v_smstemplate_code1,
										v_dlt_template_id,
										_mobile_no,
										v_sms_template,
										_user_code,
										'udyogmitra');
				end if;
									
				_succ_msg := 'Record Created Successfully';

			
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_sms_udyogmitramapping(_pg_id udd_code, _user_code udd_code, _role_code udd_code, _udyogmitra_name udd_desc, _mobile_no udd_mobile, _lang_code udd_code, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mangai
		Created Date : 19-04-2022
		SP Code      : B01UDMCXX
	*/
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_pgname udd_desc := '';
	v_smstemplate_code udd_code := 'SMST_UM_MAPPING';
begin
	
			-- send sms udyogmitra mapping
				SELECT 
					sms_template,dlt_template_id into v_sms_template,v_dlt_template_id
				FROM 	core_mst_tsmstemplate
				where 	smstemplate_code = v_smstemplate_code
				and 	lang_code = _lang_code
				and 	status_code = 'A';

				v_sms_template := coalesce(v_sms_template,'');
				v_dlt_template_id := coalesce(v_dlt_template_id,'');
				v_pgname := (select fn_get_pgname(_pg_id));

				if (v_dlt_template_id <> '') then
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Udyog_Mitra_Name#}',_udyogmitra_name);
					v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#PG_Name#}',v_pgname);

					-- Store procedure Call
					call pr_iud_smstran(_pg_id,
										v_smstemplate_code,
										v_dlt_template_id,
										_mobile_no,
										v_sms_template,
										_user_code,
										'udyogmitra');
				end if;
													
				_succ_msg := 'Record Created Successfully';

			
end 
$procedure$
"
"CREATE OR REPLACE PROCEDURE public.pr_uxx_procureproduct_update(INOUT _procprod_gid udd_int, _pg_id udd_code, _session_id udd_code, _pgmember_id udd_code, _rec_slno udd_int, _proc_date udd_date, _prod_type_code udd_code, _prod_code udd_code, _grade_code udd_code, _proc_rate udd_rate, _proc_qty udd_qty, _advance_amount udd_amount, _uom_code udd_code, _proc_remark udd_text, _lang_code udd_code, _user_code udd_code, _mode_flag udd_flag, INOUT _succ_msg udd_text)
 LANGUAGE plpgsql
AS $procedure$

declare
    /*
		Created By   : Mohan S
		Created Date : 26-03-2022
		SP Code      : B06PRPUXX
	*/
	v_advance_amount udd_amount := 0;
begin
	call pr_iud_procureproduct(_procprod_gid,_pg_id,_session_id,_pgmember_id,_rec_slno,_proc_date,_prod_type_code,
							  _prod_code,_grade_code,_proc_rate,_proc_qty,_uom_code,_proc_remark,_lang_code,
							  _user_code,_mode_flag,_succ_msg);
	
	-- 	Get advance amount
	select advance_amount into v_advance_amount from pg_trn_tprocure
	where  pg_id 		= _pg_id
	and    session_id 	= _session_id
	and    pgmember_id 	= _pgmember_id;
	
	-- advance amount update
	if v_advance_amount <> _advance_amount and _rec_slno = 1 then
		update pg_trn_tprocure
		set		
				advance_amount 		   = _advance_amount,
				updated_date		   = now(),
				updated_by			   = _user_code
		where 	pg_id				   = _pg_id
		and		session_id			   = _session_id
		and		pgmember_id			   = _pgmember_id
		and 	status_code            <> 'I';
	end if;
end 
$procedure$
"
