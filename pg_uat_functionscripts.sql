"pg_get_functiondef"
"CREATE OR REPLACE FUNCTION public.aft_insupdt_pg_mst_tpgmember()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Mohan S
		Created Date : 10-02-2022
	*/
	v_count public.udd_int := 0;
	v_pgmember_min_count public.udd_int := 0;
	v_pgname public.udd_desc := '';
	v_sms_template udd_text := '';
	v_dlt_template_id udd_code := '';
	v_smstemplate_code udd_code := 'SMST_MEM_APPROVAL';
	v_status_code udd_code := '';
BEGIN
	
	select fn_get_pgname(new.pg_id) into v_pgname;

	-- Send sms for active member
	if new.status_code = 'A' then
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
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Member_Name#}',new.pgmember_name);
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#PG_Name#}',v_pgname);
			v_sms_template := replace(v_sms_template collate pg_catalog.""default"",'{#Member_ID#}',new.pgmember_id);

			-- Store procedure Call
			call pr_iud_smstran(new.pg_id,
								v_smstemplate_code,
								v_dlt_template_id,
								new.mobile_no_active,
								v_sms_template,
								new.created_by,
								'bo');

		end if;
	end if;
	
	select count(*) into v_count
	from pg_mst_tpgmember 
	where pg_id = new.pg_id
	and status_code = 'A';
	
	--pgmember mincount values
	select 	config_value into v_pgmember_min_count
	from 	core_mst_tconfig 
	where 	config_name = 'pgmember_min_count'
	and 	status_code = 'A';

if v_count >= v_pgmember_min_count then
	update  pg_mst_tproducergroup
	set 	status_code = 'A',
			updated_date = now(),
			row_timestamp = now()
	where 	pg_id = new.pg_id
	and 	status_code <> 'I';
end if;

	select status_code into v_status_code
		from  pg_mst_tpgmember
		where pg_id       = new.pg_id
		and   pgmember_id = new.pgmember_id;

		update pg_mst_tpgmembership 
		set   membership_status_code = v_status_code ,
			  updated_date           = now(),
			  updated_by             = 'Trigger'
		where pgmember_id        = old.pgmember_id;

RETURN NEW;

END;
$function$
"
"CREATE OR REPLACE FUNCTION public.dump(p_schema text, p_table text, p_where text)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
 DECLARE
     dumpquery_0 text;
     dumpquery_1 text;
     selquery text;
     selvalue text;
     valrec record;
     colrec record;
 BEGIN

     -- ------ --
     -- GLOBAL --
     --   build base INSERT
     --   build SELECT array[ ... ]
     dumpquery_0 := 'INSERT INTO ' ||  quote_ident(p_schema) || '.' || quote_ident(p_table) || '(';
     selquery    := 'SELECT array[';

     <<label0>>
     FOR colrec IN SELECT table_schema, table_name, column_name, data_type
                   FROM information_schema.columns
                   WHERE table_name = p_table and table_schema = p_schema
                   ORDER BY ordinal_position
     LOOP
         dumpquery_0 := dumpquery_0 || quote_ident(colrec.column_name) || ',';
         selquery    := selquery    || 'CAST(' || quote_ident(colrec.column_name) || ' AS TEXT),';
     END LOOP label0;

     dumpquery_0 := substring(dumpquery_0 ,1,length(dumpquery_0)-1) || ')';
     dumpquery_0 := dumpquery_0 || ' VALUES (';
     selquery    := substring(selquery    ,1,length(selquery)-1)    || '] AS MYARRAY';
     selquery    := selquery    || ' FROM ' ||quote_ident(p_schema)||'.'||quote_ident(p_table);
     selquery    := selquery    || ' WHERE '||p_where;
     -- GLOBAL --
     -- ------ --

     -- ----------- --
     -- SELECT LOOP --
     --   execute SELECT built and loop on each row
     <<label1>>
     FOR valrec IN  EXECUTE  selquery
     LOOP
         dumpquery_1 := '';
         IF not found THEN
             EXIT ;
         END IF;

         -- ----------- --
         -- LOOP ARRAY (EACH FIELDS) --
         <<label2>>
         FOREACH selvalue in ARRAY valrec.MYARRAY
         LOOP
             IF selvalue IS NULL
             THEN selvalue := 'NULL';
             ELSE selvalue := quote_literal(selvalue);
             END IF;
             dumpquery_1 := dumpquery_1 || selvalue || ',';
         END LOOP label2;
         dumpquery_1 := substring(dumpquery_1 ,1,length(dumpquery_1)-1) || ');';
         -- LOOP ARRAY (EACH FIELD) --
         -- ----------- --

         -- debug: RETURN NEXT dumpquery_0 || dumpquery_1 || ' --' || selquery;
         -- debug: RETURN NEXT selquery;
         RETURN NEXT dumpquery_0 || dumpquery_1;

     END LOOP label1 ;
     -- SELECT LOOP --
     -- ----------- --

 RETURN ;
 END
 
$function$
"
"CREATE OR REPLACE FUNCTION public.dump1(p_schema text, p_table text, p_where text, p_dest_table text, p_conflict text[], p_update_ignore text[])
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
 DECLARE
	 i	integer;
	 fld text[];
     dumpquery_0 text;
     dumpquery_1 text;
	 updatefields_1 text;
	 conflict_fields text;
	 
     selquery text;
     selvalue text;
     valrec record;
     colrec record;
	 colArray text[];
	 colArrayUpdFlag boolean[];
 BEGIN
 	 conflict_fields := '';
	 
	 -- get conflict fields
	 for i in 1 .. array_upper(p_conflict,1)
	 LOOP
	 	conflict_fields := conflict_fields || p_conflict[i] || ',';
	 END LOOP;
	 
	 if conflict_fields <> '' then
	 	conflict_fields := substring(conflict_fields,1,length(conflict_fields)-1);
	 end if;
	 
     -- ------ --
     -- GLOBAL --
     --   build base INSERT
     --   build SELECT array[ ... ]
	 dumpquery_0 := 'INSERT INTO ';
	 
	 if p_dest_table <> '' then
     	dumpquery_0 := dumpquery_0 ||  quote_ident(p_dest_table) || '(';
	 else
     	dumpquery_0 := dumpquery_0 ||  quote_ident(p_table) || '(';
	 end if;
	 
     selquery    := 'SELECT array[';

     <<label0>>
     FOR colrec IN SELECT table_schema, table_name, column_name, data_type
                   FROM information_schema.columns
                   WHERE table_name = p_table and table_schema = p_schema
                   ORDER BY ordinal_position
     LOOP
         dumpquery_0 := dumpquery_0 || quote_ident(colrec.column_name) || ',';
         selquery    := selquery    || 'CAST(' || quote_ident(colrec.column_name) || ' AS TEXT),';
		 
		 colArray := colArray || quote_ident(colrec.column_name);
		 
		 if quote_ident(colrec.column_name) = ANY(p_conflict) 
		    or quote_ident(colrec.column_name) = ANY(p_update_ignore) then
			colArrayUpdFlag := colArrayUpdFlag || false;
		 else
			colArrayUpdFlag := colArrayUpdFlag || true;
		 end if;
     END LOOP label0;

     dumpquery_0 := substring(dumpquery_0 ,1,length(dumpquery_0)-1) || ')';
     dumpquery_0 := dumpquery_0 || ' VALUES (';
     selquery    := substring(selquery    ,1,length(selquery)-1)    || '] AS MYARRAY';
     selquery    := selquery    || ' FROM ' ||quote_ident(p_schema)||'.'||quote_ident(p_table);
	 
	 if p_where <> '' then
     	selquery    := selquery    || ' WHERE '||p_where;
	 end if;
     -- GLOBAL --
     -- ------ --

     -- ----------- --
     -- SELECT LOOP --
     --   execute SELECT built and loop on each row
     <<label1>>
     FOR valrec IN  EXECUTE  selquery
     LOOP
         dumpquery_1 := '';
		 updatefields_1 := '';
		 i := 1;
		 
         IF not found THEN
             EXIT ;
         END IF;

         -- ----------- --
         -- LOOP ARRAY (EACH FIELDS) --
         <<label2>>
         FOREACH selvalue in ARRAY valrec.MYARRAY
         LOOP
             IF selvalue IS NULL THEN 
				selvalue := 'NULL';
             ELSE 
				selvalue := quote_literal(selvalue);
             END IF;

             dumpquery_1 := dumpquery_1 || selvalue || ',';
			 
			 if colArrayUpdFlag[i] = true then
				updatefields_1 := updatefields_1 || colArray[i] || ' = ' || selvalue || ',';
			 end if;
			 
			 i := i + 1;
         END LOOP label2;
		 
         dumpquery_1 := substring(dumpquery_1 ,1,length(dumpquery_1)-1) || ')'; 
		 updatefields_1 := substring(updatefields_1,1,length(updatefields_1)-1);
		 
		 if conflict_fields <> '' then
		 	dumpquery_1 := dumpquery_1 
			            || ' on CONFLICT (' || conflict_fields || ') do update set '
		 			 	|| updatefields_1;
		 end if;
		 
		 dumpquery_1 := dumpquery_1 || ';';
         -- LOOP ARRAY (EACH FIELD) --
         -- ----------- --

         -- debug: RETURN NEXT dumpquery_0 || dumpquery_1 || ' --' || selquery;
         -- debug: RETURN NEXT selquery;
         RETURN NEXT dumpquery_0 || dumpquery_1;

     END LOOP label1 ;
     -- SELECT LOOP --
     -- ----------- --

 RETURN ;
 END
 
$function$
"
"CREATE OR REPLACE FUNCTION public.execquery()
 RETURNS TABLE(result1 refcursor)
 LANGUAGE plpgsql
AS $function$ 
declare 
	exec_query udd_text = ''; 

BEGIN
		exec_query = format('CALL public.pr_get_blockid_pgid(2171,''result1'');FETCH ALL IN result1 ');
		RETURN QUERY EXECUTE exec_query;
end;
	  $function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tpgfundledger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 07-03-2022
	*/
BEGIN
	-- check it in pgmemberlegersumm table
	if NEW.status_code = 'A' then
		if exists(select '*' from pg_trn_tpgfundledgersumm
					  where pg_id 		= NEW.pg_id 
					  and 	pgfund_code = NEW.pgfund_code
					  and 	status_code	= 'A'
					 ) then
			update 		pg_trn_tpgfundledgersumm 
			set 		dr_amount 	= dr_amount + NEW.dr_amount,
						cr_amount 	= cr_amount + NEW.cr_amount,
						as_of_date	= (case when as_of_date < NEW.tran_date then NEW.tran_date 
											else as_of_date end),
						updated_date = now(),
						updated_by 	= 'system'
			where 		pg_id 		= NEW.pg_id 
			and 		pgfund_code = NEW.pgfund_code
			and 		status_code	= 'A';
		else
			insert into pg_trn_tpgfundledgersumm
						(
							pg_id,
							pgfund_code,
							dr_amount,
							cr_amount,
							as_of_date,
							status_code,
							created_date,
							created_by
						)
						select
							NEW.pg_id,
							NEW.pgfund_code,
							NEW.dr_amount,
							NEW.cr_amount,
							NEW.tran_date,
							'A',
							now(),
							'system';
		end if;
	end if;
	
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tpgmemberledger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 28-02-2022
	*/
BEGIN
	-- check it in pgmemberlegersumm table
	if (NEW.status_code = 'A') then
		if exists(select '*' from pg_trn_tpgmemberledgersumm
					  where pg_id 		= NEW.pg_id 
					  and 	pgmember_id = NEW.pgmember_id
					  and 	status_code	= 'A'
					 ) then
			update 		pg_trn_tpgmemberledgersumm 
			set 		dr_amount 	= dr_amount + NEW.dr_amount,
						cr_amount 	= cr_amount + NEW.cr_amount,
						as_of_date	= (case when as_of_date < NEW.tran_date then NEW.tran_date 
											else as_of_date end),
						updated_date = now(),
						updated_by 	= 'system'
			where 		pg_id 		= NEW.pg_id 
			and 		pgmember_id = NEW.pgmember_id
			and 		status_code	= 'A';
		else
			insert into pg_trn_tpgmemberledgersumm
						(
							pg_id,
							pgmember_id,
							dr_amount,
							cr_amount,
							as_of_date,
							status_code,
							created_date,
							created_by
						)
						select
							NEW.pg_id,
							NEW.pgmember_id,
							NEW.dr_amount,
							NEW.cr_amount,
							NEW.tran_date,
							'A',
							now(),
							'system';
		end if;
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tprocure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
	*/
	v_dr_amount udd_amount := 0;
	v_cr_amount udd_amount := 0;
	v_tran_narration udd_text := ''; 
	
	v_pgmemberledger_gid udd_int := 0;
	v_succ_msg udd_text := '';
BEGIN
	-- don't update for invalid record
	if NEW.status_code <> 'A' or NEW.advance_amount = 0 then
		return NEW;
	end if;

	if (NEW.advance_amount > 0) then
		v_tran_narration 	:= 'PG Member Advance';
		v_cr_amount 		:= NEW.advance_amount;
	else
		v_tran_narration := 'PG Member Advance Reversal';
		v_dr_amount 		:= NEW.advance_amount;
	end if;

	-- insert in pgmember ledger table
	call pr_iud_pgmemberledger
		(
			v_pgmemberledger_gid,
			NEW.pg_id,
			NEW.pgmember_id,
			'QCD_MEM_ADVANCE',
			NEW.proc_date::udd_datetime,
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

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tprocureproduct()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 26-02-2022
	*/
BEGIN
	-- don't update perishable
	if NEW.prod_type_code = 'P' or NEW.status_code <> 'A' then
		return NEW;
	end if;
	
	-- check procurement status
	if not exists(select '*' from pg_trn_tprocure
				  where pg_id 		= NEW.pg_id 
				  and 	session_id 	= NEW.session_id 
				  and 	pgmember_id = NEW.pgmember_id
				  and 	proc_date	= NEW.proc_date 
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;
	
	-- update stock @pg level
	if exists(select '*' from pg_trn_tproductstock
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
				 ) then
		update 			pg_trn_tproductstock 
		set 			stock_qty 		= stock_qty + NEW.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tproductstock
					(
						pg_id,
						prod_type_code,
						prod_code,
						grade_code,
						uom_code,
						stock_qty,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						NEW.proc_qty,
						'A',
						now(),
						'system';
	end if;

	-- update stock @pgmember level
	if exists(select '*' from pg_trn_tpgmemberstock
				  where pg_id 		= NEW.pg_id
			  	  and	pgmember_id	= NEW.pgmember_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
			  	  and	status_code = 'A'
				 ) then
		update 			pg_trn_tpgmemberstock 
		set 			proc_qty 		= proc_qty + NEW.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id
		and 			pgmember_id 	= NEW.pgmember_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tpgmemberstock
					(
						pg_id,
						pgmember_id,
						prod_type_code,
						prod_code,
						grade_code,
						uom_code,
						proc_qty,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.pgmember_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						NEW.proc_qty,
						'A',
						now(),
						'system';
	end if;

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tprocurestockbydate()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 14-03-2022
	*/
BEGIN
	-- don't update perishable
	if NEW.status_code <> 'A' then
		return NEW;
	end if;
	
	-- check procurement status
	if not exists(select '*' from pg_trn_tprocure
				  where pg_id 		= NEW.pg_id 
				  and 	session_id 	= NEW.session_id 
				  and 	pgmember_id = NEW.pgmember_id
				  and 	proc_date	= NEW.proc_date 
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;
	
	-- update stock @pg level by date
	if exists(select '*' from pg_trn_tproductstockbydate 
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
			  	  and  	stock_date	= NEW.proc_date
				 ) then
		update 			pg_trn_tproductstockbydate  
		set 			proc_qty 		= proc_qty + NEW.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and				stock_date		= NEW.proc_date 
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tproductstockbydate
					(
						pg_id,
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
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						NEW.proc_date,
						fn_get_productopeningqty(NEW.pg_id,NEW.proc_date,NEW.prod_code,NEW.grade_code),
						NEW.proc_qty,
						'A',
						now(),
						'system';
	end if;

	-- update stock @pgmember level by date
	if exists(select '*' from pg_trn_tpgmemberstockbydate
				  where pg_id 		= NEW.pg_id
			  	  and	pgmember_id	= NEW.pgmember_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
			  	  and	stock_date  = NEW.proc_date 
			  	  and 	status_code = 'A'
				 ) then
		update 			pg_trn_tpgmemberstockbydate 
		set 			proc_qty 		= proc_qty + NEW.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id
		and 			pgmember_id 	= NEW.pgmember_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and				stock_date		= NEW.proc_date 
		and 			status_code 	= 'A';
	else
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
						NEW.pg_id,
						NEW.pgmember_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						NEW.proc_date,
						fn_get_pgmemberopeningqty(NEW.pg_id,NEW.pgmember_id,NEW.proc_date,NEW.prod_code,NEW.grade_code),
						NEW.proc_qty,
						'A',
						now(),
						'system';
	end if;

	if (NEW.prod_type_code = 'N') then
		update 	pg_trn_tproductstockbydate 
		set 	opening_qty 	= opening_qty + NEW.proc_qty,
				updated_date 	= now(),
				updated_by 		= 'system'
		where 	pg_id 		= NEW.pg_id 
		and 	prod_code 	= NEW.prod_code 
		and 	grade_code 	= NEW.grade_code
		and		stock_date	> NEW.proc_date 
		and 	status_code = 'A';
		
		update 	pg_trn_tpgmemberstockbydate 
		set 	opening_qty 	= opening_qty + NEW.proc_qty,
				updated_date 	= now(),
				updated_by 		= 'system'
		where 	pg_id 		= NEW.pg_id 
		and		pgmember_id	= NEW.pgmember_id 
		and 	prod_code 	= NEW.prod_code 
		and 	grade_code 	= NEW.grade_code
		and		stock_date	> NEW.proc_date 
		and 	status_code = 'A';
	end if;
	
	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tsaleproduct()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 26-02-2022
	*/
BEGIN
	-- don't update perishable
	if NEW.prod_type_code = 'P' 
		or NEW.status_code <> 'A' 
		or NEW.stock_adj_flag <> 'Y' then
		return NEW;
	end if;
	
	-- check sale status
	if not exists(select '*' from pg_trn_tsale
				  where pg_id 		= NEW.pg_id 
				  and 	inv_date 	= NEW.inv_date
				  and 	inv_no 		= NEW.inv_no
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;
	
	-- update stock @pg level
	if exists(select '*' from pg_trn_tproductstock
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
				 ) then
		update 			pg_trn_tproductstock 
		set 			stock_qty 		= stock_qty - NEW.sale_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tproductstock
					(
						pg_id,
						prod_type_code,
						prod_code,
						grade_code,
						stock_qty,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.sale_qty*(-1.0),
						'A',
						now(),
						'system';
	end if;

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tsalestockbydate()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 14-03-2022
		
		Updated By : Vijayavel J
		Updated Date : 12-04-2022
	*/
BEGIN
	if (NEW.status_code <> 'A' or NEW.stock_adj_flag <> 'Y') then
		return NEW;
	end if;
	
	-- check sale status
	if not exists(select '*' from pg_trn_tsale
				  where pg_id 		= NEW.pg_id 
				  and 	inv_date 	= NEW.inv_date
				  and 	inv_no 		= NEW.inv_no
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;
	
	-- update stock @pg level by date
	if exists(select '*' from pg_trn_tproductstockbydate
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
			  	  and 	stock_date	= NEW.inv_date
			  	  and	status_code = 'A'
				 ) then
		update 			pg_trn_tproductstockbydate  
		set 			sale_qty 		= sale_qty + NEW.sale_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and				stock_date		= NEW.inv_date
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tproductstockbydate
					(
						pg_id,
						prod_type_code,
						prod_code,
						grade_code,
						sale_qty,
						stock_date,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.sale_qty,
						NEW.inv_date,
						'A',
						now(),
						'system';
	end if;

	if (NEW.prod_type_code = 'N') then
		update 	pg_trn_tproductstockbydate 
		set 	opening_qty = opening_qty - NEW.sale_qty,
				updated_date= now(),
				updated_by 	= 'system'
		where 	pg_id 		= NEW.pg_id 
		and 	prod_code 	= NEW.prod_code 
		and 	grade_code 	= NEW.grade_code
		and		stock_date	> NEW.inv_date 
		and 	status_code = 'A';
	end if;
	
	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_cxx_pg_trn_tsession()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 19-03-2022
	*/
BEGIN
	if (NEW.latitude_code <> '' and NEW.longitude_code <> '') then
		update pg_mst_tcollectionpoint set 
			latitude_code	= NEW.latitude_code,
			longitude_code	= NEW.longitude_code,
			updated_by 		= NEW.created_by,
			updated_date 	= now()
		where 	pg_id 			=  NEW.pg_id 
		and 	collpoint_no 	=  NEW.collpoint_no 
		and (	latitude_code	<> NEW.latitude_code
		or		longitude_code	<> NEW.longitude_code);
	end if;
	
	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_dxx_pg_trn_tpgfundledger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 07-03-2022
	*/
BEGIN
	if (OLD.status_code = 'A') then
		update 	pg_trn_tpgfundledgersumm 
		set 	dr_amount 	= dr_amount - OLD.dr_amount,
				cr_amount 	= cr_amount - OLD.cr_amount,
				updated_date= now(),
				updated_by 	= 'system'
		where 	pg_id 		= OLD.pg_id 
		and 	pgfund_code = OLD.pgfund_code
		and 	status_code	= 'A';
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_dxx_pg_trn_tpgmemberledger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 28-02-2022
	*/
BEGIN
	if (OLD.status_code = 'A') then
		update 	pg_trn_tpgmemberledgersumm 
		set 	dr_amount 	= dr_amount - OLD.dr_amount,
				cr_amount 	= cr_amount - OLD.cr_amount,
				updated_date= now(),
				updated_by 	= 'system'
		where 	pg_id 		= OLD.pg_id 
		and 	pgmember_id = OLD.pgmember_id
		and 	status_code	= 'A';
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_dxx_pg_trn_tprocure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
	*/
	v_dr_amount udd_amount := 0;
	v_cr_amount udd_amount := 0;
	v_tran_narration udd_text := ''; 
	v_pgmemberledger_gid udd_int := 0;
	
	v_succ_msg udd_text := '';
BEGIN
	-- check and update old record
	if 	OLD.status_code = 'A' and OLD.advance_amount <> 0 then
			v_cr_amount := 0;
			v_dr_amount	:= 0;

			if (OLD.advance_amount < 0) then
				v_tran_narration 	:= 'PG Member Advance';
				v_cr_amount 		:= abs(OLD.advance_amount);
			else
				v_tran_narration := 'PG Member Advance Reversal';
				v_dr_amount 		:= OLD.advance_amount;
			end if;

			-- insert in pgmember ledger table
			call pr_iud_pgmemberledger
				(
					v_pgmemberledger_gid,
					OLD.pg_id,
					OLD.pgmember_id,
					'QCD_MEM_ADVANCE',
					now()::udd_datetime,
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
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_dxx_pg_trn_tprocureproduct()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 26-02-2022
	*/
BEGIN
	-- don't update perishable
	if OLD.prod_type_code = 'P' or OLD.status_code <> 'A' then
		return NEW;
	end if;

	-- check procurement status
	if not exists(select '*' from pg_trn_tprocure
				  where pg_id 		= OLD.pg_id 
				  and 	session_id 	= OLD.session_id 
				  and 	pgmember_id = OLD.pgmember_id
				  and 	proc_date	= OLD.proc_date 
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;
	
	-- update stock @pg level
	update 	pg_trn_tproductstock 
	set 	stock_qty 		= stock_qty - OLD.proc_qty
	where 	pg_id 			= OLD.pg_id 
	and 	prod_code 		= OLD.prod_code 
	and 	grade_code 		= OLD.grade_code
	and 	status_code 	= 'A';

	-- update stock @pgmember level
	update 	pg_trn_tpgmemberstock
	set 	proc_qty 		= proc_qty - OLD.proc_qty
	where 	pg_id 			= OLD.pg_id
	and 	pgmember_id 	= OLD.pgmember_id
	and 	prod_code 		= OLD.prod_code 
	and 	grade_code 		= OLD.grade_code
	and 	status_code 	= 	'A';

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_dxx_pg_trn_tprocurestockbydate()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 14-03-2022
	*/
BEGIN
	-- don't update perishable
	if OLD.status_code <> 'A' then
		return NEW;
	end if;

	-- check procurement status
	if not exists(select '*' from pg_trn_tprocure
				  where pg_id 		= OLD.pg_id 
				  and 	session_id 	= OLD.session_id 
				  and 	pgmember_id = OLD.pgmember_id
				  and 	proc_date	= OLD.proc_date 
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;
	
	-- update stock @pg level by date
	update 	pg_trn_tproductstockbydate 
	set 	proc_qty 		= proc_qty - OLD.proc_qty
	where 	pg_id 			= OLD.pg_id 
	and 	prod_code 		= OLD.prod_code 
	and 	grade_code 		= OLD.grade_code
	and		stock_date		= OLD.proc_date
	and 	status_code 	= 'A';
	
	update 	pg_trn_tpgmemberstockbydate 
	set 	proc_qty 		= proc_qty - OLD.proc_qty,
			updated_date 	= now(),
			updated_by 		= 'system'
	where 	pg_id 			= OLD.pg_id
	and 	pgmember_id 	= OLD.pgmember_id 
	and 	prod_code 		= OLD.prod_code 
	and 	grade_code 		= OLD.grade_code
	and		stock_date		= OLD.proc_date 
	and 	status_code 	= 'A';
	
	if (OLD.prod_type_code = 'N') then
		update 	pg_trn_tproductstockbydate 
		set 	opening_qty 	= opening_qty - OLD.proc_qty,
				updated_date 	= now(),
				updated_by 		= 'system'
		where 	pg_id 		= OLD.pg_id 
		and 	prod_code 	= OLD.prod_code 
		and 	grade_code 	= OLD.grade_code
		and		stock_date	> OLD.proc_date 
		and 	status_code = 'A';
		
		update 	pg_trn_tpgmemberstockbydate 
		set 	opening_qty 	= opening_qty - OLD.proc_qty,
				updated_date 	= now(),
				updated_by 		= 'system'
		where 	pg_id 			= OLD.pg_id
		and 	pgmember_id 	= OLD.pgmember_id 
		and 	prod_code 		= OLD.prod_code 
		and 	grade_code 		= OLD.grade_code
		and 	stock_date		> OLD.proc_date 
		and 	status_code 	= 'A';
	end if;
	
	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_dxx_pg_trn_tsaleproduct()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 26-02-2022
		
		Updated By : Vijayavel J
		Updated Date : 12-04-2022
	*/
BEGIN
	-- don't update perishable
	if OLD.prod_type_code = 'P' or OLD.status_code <> 'A' or OLD.stock_adj_flag <> 'Y' then
		return NEW;
	end if;

	update 	pg_trn_tproductstock 
	set 	stock_qty 	 = stock_qty + OLD.sale_qty,
			updated_date = now(),
			updated_by 	 = 'system'
	where 	pg_id 		 = OLD.pg_id 
	and 	prod_code 	 = OLD.prod_code 
	and 	grade_code 	 = OLD.grade_code
	and 	status_code  = 'A';

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_dxx_pg_trn_tsalestockbydate()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 14-03-2022
		
		Updated By : Vijayavel J
		Updated Date : 12-04-2022
	*/
BEGIN
	-- don't update perishable
	if OLD.status_code <> 'A' or OLD.stock_adj_flag <> 'Y' then
		return NEW;
	end if;

	update 	pg_trn_tproductstockbydate 
	set 	sale_qty 	 = sale_qty - OLD.sale_qty,
			updated_date = now(),
			updated_by 	 = 'system'
	where 	pg_id 		 = OLD.pg_id 
	and 	prod_code 	 = OLD.prod_code 
	and 	grade_code 	 = OLD.grade_code
	and		stock_date	 = OLD.inv_date
	and 	status_code  = 'A';

	if (OLD.prod_type_code = 'N') then
		update 	pg_trn_tproductstockbydate 
		set 	opening_qty 	= opening_qty + OLD.sale_qty,
				updated_date 	= now(),
				updated_by 		= 'system'
		where 	pg_id 			= OLD.pg_id 
		and 	prod_code 		= OLD.prod_code 
		and 	grade_code 		= OLD.grade_code
		and		stock_date		> OLD.inv_date 
		and 	status_code 	= 'A';
	end if;
	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_uxx_pg_trn_tpgfundledger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 07-03-2022
	*/
BEGIN
	-- check it in pgfundlegersumm table
	if exists(select '*' from pg_trn_tpgfundledgersumm
				  where pg_id 		= OLD.pg_id 
				  and 	pgfund_code = OLD.pgfund_code
			  	  and 	status_code = 'A'
				 ) and OLD.status_code = 'A' then
		update 		pg_trn_tpgfundledgersumm 
		set 		dr_amount 	= dr_amount - OLD.dr_amount,
					cr_amount 	= cr_amount - OLD.cr_amount,
					updated_date = now(),
					updated_by 	= 'system'
		where 		pg_id 		= OLD.pg_id 
		and 		pgfund_code = OLD.pgfund_code
		and 		status_code	= 'A';
	end if;
	
	if (NEW.status_code = 'A') then
		if exists(select '*' from pg_trn_tpgfundledgersumm
				  where pg_id 		= NEW.pg_id 
				  and 	pgfund_code = NEW.pgfund_code
			  	  and 	status_code = 'A'
				 ) then
				 
			update 		pg_trn_tpgfundledgersumm 
			set 		dr_amount 	= dr_amount + NEW.dr_amount,
						cr_amount 	= cr_amount + NEW.cr_amount,
						as_of_date	= (case when as_of_date < NEW.tran_date then NEW.tran_date 
											else as_of_date end),
						updated_date = now(),
						updated_by 	= 'system'
			where 		pg_id 		= NEW.pg_id 
			and 		pgfund_code = NEW.pgfund_code
			and 		status_code	= 'A';
		else
			insert into pg_trn_tpgfundledgersumm
						(
							pg_id,
							pgfund_code,
							dr_amount,
							cr_amount,
							as_of_date,
							status_code,
							created_date,
							created_by
						)
						select
							NEW.pg_id,
							NEW.pgfund_code,
							NEW.dr_amount,
							NEW.cr_amount,
							NEW.tran_date,
							'A',
							now(),
							'system';
		end if;
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_uxx_pg_trn_tpgmemberledger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 07-03-2022
	*/
BEGIN
	-- check it in pgmemberlegersumm table
	if exists(select '*' from pg_trn_tpgmemberledgersumm
				  where pg_id 		= OLD.pg_id 
				  and 	pgmember_id = OLD.pgmember_id
				  and 	status_code	= 'A'
				 ) and OLD.status_code = 'A' then
		update 		pg_trn_tpgmemberledgersumm 
		set 		dr_amount 	= dr_amount - OLD.dr_amount,
					cr_amount 	= cr_amount - OLD.cr_amount,
					updated_date = now(),
					updated_by 	= 'system'
		where 		pg_id 		= OLD.pg_id 
		and 		pgmember_id = OLD.pgmember_id
		and 		status_code	= 'A';
	end if;
	
	if (NEW.status_code = 'A') then
		if exists(select '*' from pg_trn_tpgmemberledgersumm
					  where pg_id 		= NEW.pg_id 
					  and 	pgmember_id = NEW.pgmember_id
					  and 	status_code	= 'A'
					 ) then
			update 		pg_trn_tpgmemberledgersumm 
			set 		dr_amount 	= dr_amount + NEW.dr_amount,
						cr_amount 	= cr_amount + NEW.cr_amount,
						as_of_date	= (case when as_of_date < NEW.tran_date then NEW.tran_date 
											else as_of_date end),
						updated_date = now(),
						updated_by 	= 'system'
			where 		pg_id 		= NEW.pg_id 
			and 		pgmember_id = NEW.pgmember_id
			and 		status_code	= 'A';
		else
			insert into pg_trn_tpgmemberledgersumm
						(
							pg_id,
							pgmember_id,
							dr_amount,
							cr_amount,
							as_of_date,
							status_code,
							created_date,
							created_by
						)
						select
							NEW.pg_id,
							NEW.pgmember_id,
							NEW.dr_amount,
							NEW.cr_amount,
							NEW.tran_date,
							'A',
							now(),
							'system';
		end if;
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_uxx_pg_trn_tprocure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 12-03-2022
	*/
	v_dr_amount udd_amount := 0;
	v_cr_amount udd_amount := 0;
	v_tran_narration udd_text := ''; 
	v_pgmemberledger_gid udd_int := 0;
	v_succ_msg udd_text := '';
BEGIN
	-- check and update old record
	if 	OLD.status_code = 'A' 
		and OLD.advance_amount <> 0 
		and 
		( 	OLD.pg_id <> New.pg_id
		or	OLD.pgmember_id <> NEW.pgmember_id
		or	OLD.advance_amount <> NEW.advance_amount
		or	NEW.status_code <> 'A'
		) then
		v_cr_amount := 0;
		v_dr_amount	:= 0;

		if (OLD.advance_amount < 0) then
			v_tran_narration 	:= 'PG Member Advance';
			v_cr_amount 		:= abs(OLD.advance_amount);
		else
			v_tran_narration := 'PG Member Advance Reversal';
			v_dr_amount 		:= OLD.advance_amount;
		end if;

		-- insert in pgmember ledger table
		call pr_iud_pgmemberledger
			(
				v_pgmemberledger_gid::udd_int,
				OLD.pg_id::udd_code,
				OLD.pgmember_id::udd_code,
				'QCD_MEM_ADVANCE'::udd_code,
				now()::udd_datetime,
				v_dr_amount::udd_amount,
				v_cr_amount::udd_amount,
				v_tran_narration::udd_text,
				''::udd_text,
				''::udd_text,
				'A'::udd_code,
				''::udd_code,
				'en_US'::udd_code,
				'admin'::udd_code,
				'I'::udd_flag,
				v_succ_msg::udd_text
			);
	elseif OLD.status_code = NEW.status_code then
		return NEW;
	end if;
	
	-- don't update for invalid record
	if NEW.status_code <> 'A' then
		return NEW;
	end if;

	if (NEW.advance_amount <> 0) then
		v_cr_amount := 0;
		v_dr_amount	:= 0;
		
		if (NEW.advance_amount > 0) then
			v_tran_narration 	:= 'PG Member Advance';
			v_cr_amount 		:= NEW.advance_amount;
		else
			v_tran_narration := 'PG Member Advance Reversal';
			v_dr_amount 		:= abs(NEW.advance_amount);
		end if;

		-- insert in pgmember ledger table
		call pr_iud_pgmemberledger
			(
				v_pgmemberledger_gid,
				NEW.pg_id,
				NEW.pgmember_id,
				'QCD_MEM_ADVANCE',
				NEW.proc_date::udd_datetime,
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
	end if;

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_uxx_pg_trn_tprocureproduct()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 26-02-2022
	*/
BEGIN
	if OLD.prod_type_code = 'N' and OLD.status_code = 'A' then
		if exists(select '*' from pg_trn_tprocure
					  where pg_id 		= OLD.pg_id 
					  and 	session_id 	= OLD.session_id 
					  and 	pgmember_id = OLD.pgmember_id
					  and 	proc_date	= OLD.proc_date 
					  and 	status_code = 'A'
					 ) then
			update 		pg_trn_tproductstock 
			set 		stock_qty 	= stock_qty - OLD.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
			where 		pg_id 		= OLD.pg_id 
			and 		prod_code 	= OLD.prod_code 
			and 		grade_code 	= OLD.grade_code
			and 		status_code = 'A';

			update 		pg_trn_tpgmemberstock 
			set 		proc_qty 		= proc_qty - OLD.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
			where 		pg_id 			= OLD.pg_id
			and 		pgmember_id 	= OLD.pgmember_id 
			and 		prod_code 		= OLD.prod_code 
			and 		grade_code 		= OLD.grade_code
			and 		status_code 	= 'A';
		end if;
	end if;

	-- don't update perishable
	if NEW.prod_type_code = 'P' or NEW.status_code <> 'A' then
		return NEW;
	end if;

	-- check procurement status
	if not exists(select '*' from pg_trn_tprocure
				  where pg_id 		= NEW.pg_id 
				  and 	session_id 	= NEW.session_id 
				  and 	pgmember_id = NEW.pgmember_id
				  and 	proc_date	= NEW.proc_date 
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;

	-- update stock @pg level
	if exists(select '*' from pg_trn_tproductstock
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
				 ) then
		update 			pg_trn_tproductstock 
		set 			stock_qty 	= stock_qty + NEW.proc_qty
		where 			pg_id 		= NEW.pg_id 
		and 			prod_code 	= NEW.prod_code 
		and 			grade_code 	= NEW.grade_code
		and 			status_code = 'A';
	else
		insert into pg_trn_tproductstock
					(
						pg_id,
						prod_type_code,
						prod_code,
						grade_code,
						uom_code,
						stock_qty,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						NEW.proc_qty,
						'A',
						now(),
						'system';
	end if;
	
	-- update stock @pgmember level
	if exists(select '*' from pg_trn_tpgmemberstock
				  where pg_id 		= NEW.pg_id
			  	  and	pgmember_id	= NEW.pgmember_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
				 ) then
		update 			pg_trn_tpgmemberstock 
		set 			proc_qty 		= proc_qty + NEW.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id
		and 			pgmember_id 	= NEW.pgmember_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tpgmemberstock
					(
						pg_id,
						pgmember_id,
						prod_type_code,
						prod_code,
						grade_code,
						uom_code,
						proc_qty,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.pgmember_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						NEW.proc_qty,
						'A',
						now(),
						'system';
	end if;

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_uxx_pg_trn_tprocurestockbydate()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 14-03-2022
	*/
BEGIN
	if OLD.status_code = 'A' then
		if exists(select '*' from pg_trn_tprocure
					  where pg_id 		= OLD.pg_id 
					  and 	session_id 	= OLD.session_id 
					  and 	pgmember_id = OLD.pgmember_id
					  and 	proc_date	= OLD.proc_date 
					  and 	status_code = 'A'
					 ) then
					 
			update 		pg_trn_tproductstockbydate 
			set 		proc_qty 		= proc_qty - OLD.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
			where 		pg_id 		= OLD.pg_id 
			and 		prod_code 	= OLD.prod_code 
			and 		grade_code 	= OLD.grade_code
			and			stock_date	= OLD.proc_date 
			and 		status_code = 'A';

			update 		pg_trn_tpgmemberstockbydate 
			set 		proc_qty 		= proc_qty - OLD.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
			where 		pg_id 			= OLD.pg_id
			and 		pgmember_id 	= OLD.pgmember_id 
			and 		prod_code 		= OLD.prod_code 
			and 		grade_code 		= OLD.grade_code
			and			stock_date		= OLD.proc_date 
			and 		status_code 	= 'A';

			if (OLD.prod_type_code = 'N') then
				update 		pg_trn_tproductstockbydate 
				set 		opening_qty 	= opening_qty - OLD.proc_qty,
							updated_date 	= now(),
							updated_by 		= 'system'
				where 		pg_id 		= OLD.pg_id 
				and 		prod_code 	= OLD.prod_code 
				and 		grade_code 	= OLD.grade_code
				and			stock_date	> OLD.proc_date 
				and 		status_code = 'A';
				
				update 		pg_trn_tpgmemberstockbydate 
				set 		opening_qty 	= opening_qty - OLD.proc_qty,
							updated_date 	= now(),
							updated_by 		= 'system'
				where 		pg_id 			= OLD.pg_id
				and 		pgmember_id 	= OLD.pgmember_id 
				and 		prod_code 		= OLD.prod_code 
				and 		grade_code 		= OLD.grade_code
				and 		stock_date		> OLD.proc_date 
				and 		status_code 	= 'A';
			end if;
		end if;
	end if;

	-- don't update perishable
	if NEW.status_code <> 'A' then
		return NEW;
	end if;

	-- check procurement status
	if not exists(select '*' from pg_trn_tprocure
				  where pg_id 		= NEW.pg_id 
				  and 	session_id 	= NEW.session_id 
				  and 	pgmember_id = NEW.pgmember_id
				  and 	proc_date	= NEW.proc_date 
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;

	-- update stock @pg level by date
	if exists(select '*' from pg_trn_tproductstockbydate
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
			  	  and 	stock_date	= NEW.proc_date	
			  	  and	status_code	= 'A'
				 ) then
		update 			pg_trn_tproductstockbydate 
		set 			proc_qty 	= proc_qty + NEW.proc_qty
		where 			pg_id 		= NEW.pg_id 
		and 			prod_code 	= NEW.prod_code 
		and 			grade_code 	= NEW.grade_code
		and				stock_date	= NEW.proc_date
		and 			status_code = 'A';
	else
		insert into pg_trn_tproductstockbydate
					(
						pg_id,
						prod_type_code,
						prod_code,
						grade_code,
						uom_code,
						opening_qty,
						proc_qty,
						stock_date,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						fn_get_productopeningqty(NEW.pg_id,NEW.proc_date,NEW.prod_code,NEW.grade_code),
						NEW.proc_qty,
						NEW.proc_date,
						'A',
						now(),
						'system';
	end if;
	
	-- update stock @pgmember level by date
	if exists(select '*' from pg_trn_tpgmemberstockbydate
				  where pg_id 		= NEW.pg_id
			  	  and	pgmember_id	= NEW.pgmember_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
			  	  and	stock_date  = NEW.proc_date 
			  	  and 	status_code = 'A'
				 ) then
		update 			pg_trn_tpgmemberstockbydate 
		set 			proc_qty 		= proc_qty + NEW.proc_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
		where 			pg_id 			= NEW.pg_id
		and 			pgmember_id 	= NEW.pgmember_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and				stock_date		= NEW.proc_date 
		and 			status_code 	= 'A';
	else
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
						NEW.pg_id,
						NEW.pgmember_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.uom_code,
						NEW.proc_date,
						fn_get_pgmemberopeningqty(NEW.pg_id,NEW.pgmember_id,NEW.proc_date,NEW.prod_code,NEW.grade_code),
						NEW.proc_qty,
						'A',
						now(),
						'system';
	end if;

	if (NEW.prod_type_code = 'N') then
		update 		pg_trn_tproductstockbydate 
		set 		opening_qty 	= opening_qty + NEW.proc_qty,
					updated_date 	= now(),
					updated_by 		= 'system'
		where 		pg_id 		= NEW.pg_id 
		and 		prod_code 	= NEW.prod_code 
		and 		grade_code 	= NEW.grade_code
		and			stock_date	> NEW.proc_date 
		and 		status_code = 'A';
		
		update 	pg_trn_tpgmemberstockbydate 
		set 	opening_qty 	= opening_qty + NEW.proc_qty,
				updated_date 	= now(),
				updated_by 		= 'system'
		where 	pg_id 		= NEW.pg_id 
		and		pgmember_id	= NEW.pgmember_id 
		and 	prod_code 	= NEW.prod_code 
		and 	grade_code 	= NEW.grade_code
		and		stock_date	> NEW.proc_date 
		and 	status_code = 'A';
	end if;
	
	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_uxx_pg_trn_tsaleproduct()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 26-02-2022
		
		Updated By : Vijayavel J
		Updated Date : 12-04-2022
	*/
BEGIN
	if OLD.prod_type_code = 'N' and OLD.status_code = 'A' 
		and OLD.stock_adj_flag = 'Y'  then
		if exists(select '*' from pg_trn_tsale
					  where pg_id 		= OLD.pg_id 
					  and 	inv_date 	= OLD.inv_date
					  and 	inv_no 		= OLD.inv_no
					  and 	status_code = 'A'
					 ) then
			update 	pg_trn_tproductstock 
			set 	stock_qty 		= stock_qty + OLD.sale_qty,
					updated_date	= now(),
					updated_by		= 'system'
			where 	pg_id 			= OLD.pg_id 
			and 	prod_code 		= OLD.prod_code 
			and 	grade_code 		= OLD.grade_code
			and 	status_code 	= 'A';
					 
		end if;
	end if;

	-- don't update perishable
	if NEW.prod_type_code = 'P' or NEW.status_code <> 'A' or NEW.stock_adj_flag <> 'Y' then
		return NEW;
	end if;

	-- check sale status
	if not exists(select '*' from pg_trn_tsale
				  where pg_id 		= NEW.pg_id 
				  and 	inv_date 	= NEW.inv_date
				  and 	inv_no 		= NEW.inv_no
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;

	-- update stock @pg level
	if exists(select '*' from pg_trn_tproductstock
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
				 ) then
		update 			pg_trn_tproductstock 
		set 			stock_qty 		= stock_qty - NEW.sale_qty,
						updated_date	= now(),
						updated_by		= 'system'
		where 			pg_id 			= NEW.pg_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tproductstock
					(
						pg_id,
						prod_type_code,
						prod_code,
						grade_code,
						stock_qty,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.sale_qty*(-1.0),
						'A',
						now(),
						'system';
	end if;

	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_aft_uxx_pg_trn_tsalestockbydate()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 14-03-2022

		Updated By : Vijayavel J
		Updated Date : 12-04-2022
	*/
BEGIN
	if OLD.status_code = 'A' and OLD.stock_adj_flag = 'Y' then
		if exists(select '*' from pg_trn_tsale
					  where pg_id 		= OLD.pg_id 
					  and 	inv_date 	= OLD.inv_date
					  and 	inv_no 		= OLD.inv_no
					  and 	status_code = 'A'
					 ) then
			update 	pg_trn_tproductstockbydate 
			set 	sale_qty 		= sale_qty - OLD.sale_qty,
					updated_date	= now(),
					updated_by		= 'system'
			where 	pg_id 			= OLD.pg_id 
			and 	prod_code 		= OLD.prod_code 
			and 	grade_code 		= OLD.grade_code
			and		stock_date		= OLD.inv_date
			and 	status_code 	= 'A';
			
			if (OLD.prod_type_code = 'N') then
				update 	pg_trn_tproductstockbydate 
				set 	opening_qty 	= opening_qty + OLD.sale_qty,
						updated_date 	= now(),
						updated_by 		= 'system'
				where 	pg_id 			= OLD.pg_id 
				and 	prod_code 		= OLD.prod_code 
				and 	grade_code 		= OLD.grade_code
				and		stock_date		> OLD.inv_date 
				and 	status_code 	= 'A';
			end if;
		end if;
	end if;
	
	if (NEW.status_code <> 'A' or NEW.stock_adj_flag <> 'Y') then
		return NEW;
	end if;

	-- check sale status
	if not exists(select '*' from pg_trn_tsale
				  where pg_id 		= NEW.pg_id 
				  and 	inv_date 	= NEW.inv_date
				  and 	inv_no 		= NEW.inv_no
				  and 	status_code = 'A'
				 ) then
		return NEW;
	end if;

	-- update stock @pg level date level
	if exists(select '*' from pg_trn_tproductstockbydate
				  where pg_id 		= NEW.pg_id 
				  and 	prod_code 	= NEW.prod_code 
				  and 	grade_code 	= NEW.grade_code
			  	  and	stock_date	= NEW.inv_date
			  	  and	status_code = 'A'
				 ) then
		update 			pg_trn_tproductstockbydate 
		set 			sale_qty 		= sale_qty + NEW.sale_qty,
						updated_date	= now(),
						updated_by		= 'system'
		where 			pg_id 			= NEW.pg_id 
		and 			prod_code 		= NEW.prod_code 
		and 			grade_code 		= NEW.grade_code
		and				stock_date		= NEW.inv_date
		and 			status_code 	= 'A';
	else
		insert into pg_trn_tproductstockbydate
					(
						pg_id,
						prod_type_code,
						prod_code,
						grade_code,
						sale_qty,
						stock_date,
						status_code,
						created_date,
						created_by
					)
					select
						NEW.pg_id,
						NEW.prod_type_code,
						NEW.prod_code,
						NEW.grade_code,
						NEW.sale_qty,
						NEW.inv_date,
						'A',
						now(),
						'system';
	end if;

	if (NEW.prod_type_code = 'N') then
		update 	pg_trn_tproductstockbydate 
		set 	opening_qty = opening_qty - NEW.sale_qty,
				updated_date= now(),
				updated_by 	= 'system'
		where 	pg_id 		= NEW.pg_id 
		and 	prod_code 	= NEW.prod_code 
		and 	grade_code 	= NEW.grade_code
		and		stock_date	> NEW.inv_date 
		and 	status_code = 'A';
	end if;
	
	RETURN NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_bef_cxx_pg_mst_tpgmember()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 19-03-2022
	*/
BEGIN
	-- PG Member Duplicate Validation
	if (NEW.dbo_available_flag = 'Y') then
		if exists(	select '*' from pg_mst_tpgmember 
					where	pgmember_gid 	<> NEW.pgmember_gid
				  	and 	pg_id = NEW.pg_id
				  	and 	pgmember_id = NEW.pgmember_id
					and		pgmember_name = NEW.pgmember_name 
					and		fatherhusband_name	= NEW.fatherhusband_name
					and		dob_date			= NEW.dob_date
					and		gender_code			= NEW.gender_code
					and		dbo_available_flag	= NEW.dbo_available_flag
				  	and		mobile_no_active	= NEW.mobile_no_active
				 ) then
			RAISE EXCEPTION 'Duplicate PG Member By Name,Father/Husband Name,Gender and DOB';
		end if;
	else
		if exists(	select '*' from pg_mst_tpgmember 
					where	pgmember_gid 	<> NEW.pgmember_gid
				  	and 	pg_id = NEW.pg_id
					and		pgmember_name 		= NEW.pgmember_name 
					and		fatherhusband_name	= NEW.fatherhusband_name
					and		gender_code			= NEW.gender_code
					and		age					= NEW.age
					and		age_ason_date		= NEW.age_ason_date
					and		dbo_available_flag	= NEW.dbo_available_flag
				  	and		mobile_no_active	= NEW.mobile_no_active
				 ) then
			RAISE EXCEPTION '%','Member : ' ||
								NEW.pgmember_id ||
								
								' - Duplicate By Name,Father/Husband Name,' ||
								'Gender,DOB and Mobile No';
		end if;
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_bef_uxx_pg_trn_tpgfundledger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 19-03-2022
		
		Updated By : Vijayavel J
		Updated Date : 12-04-2022
	*/
BEGIN
	-- recovered flag
	if (OLD.recovered_flag = 'Y') then
		-- not allow the edit recovered flag record
		RAISE EXCEPTION '%','VB05FDLCUD_012-' || fn_get_msg('VB05FDLCUD_012', 'en_US');
		return OLD;
	end if;
	
	return NEW;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_activitycount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_actcount public.udd_int := 0;
BEGIN
	
	select count(distinct act.pg_id)  into v_actcount
	from 			pg_mst_tproducergroup as pg
	inner join    	pg_mst_tactivity as act
	on            	pg.pg_id        = act.pg_id
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and 			pg.status_code  = 'A';
	
	v_actcount = coalesce(v_actcount,0);
	
	return v_actcount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_bankacclength(_bank_code udd_code, _bankacc_no udd_code)
 RETURNS udd_boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_bool udd_boolean := false;
	v_bank_account_len udd_code := '';
	v_bankacc_no_leng udd_code := '';
	v_pgbankaccno_max_count udd_int := 0;
	v_bankacc_no udd_int := 0;
BEGIN
	-- bank accno less than 20 validation
	select 	config_value  into v_pgbankaccno_max_count
	from 	core_mst_tconfig 
	where 	config_name = 'pgbankaccno_max_count'
	and 	status_code = 'A';
	
	select  bank_account_len into v_bank_account_len
	from 	bank_master
	where 	bank_code = _bank_code
	and 	is_active = 1;
	
	if v_bank_account_len = 'NULL' then
		v_bank_account_len := null;
	end if ;
	
	v_bank_account_len = coalesce(v_bank_account_len,'');
	v_bank_account_len = '{' || v_bank_account_len || '}';
	
	select length(_bankacc_no)::udd_code into v_bankacc_no_leng;
	select length(_bankacc_no) into v_bankacc_no;
	
	if v_bank_account_len <> '0' and v_bank_account_len <> '{}' then
			return (select v_bankacc_no_leng::text=ANY(v_bank_account_len::text[]));
		else if v_bankacc_no >= v_pgbankaccno_max_count then
			v_bool := true;
		else
			v_bool := false;
		end if;
	end if;
	
	return v_bool;
	
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_blockcode(_block_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_code public.udd_text := '';
BEGIN
	select  block_code into v_block_code 
	from 	block_master 
	where 	block_id =  _block_id
	and 	is_active = true ;
	
	v_block_code = coalesce(v_block_code,'');
	
	return v_block_code;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_blockdesc(_block_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_desc public.udd_text := '';
BEGIN
	select block_name_en into v_block_desc 
	from 		block_master
	where 	block_id = _block_id
	and 	is_active = true;
	
	v_block_desc = coalesce(v_block_desc,'');
	return v_block_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_blockid(_block_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
BEGIN
	select  block_id into v_block_id 
	from 	block_master 
	where 	block_code =  _block_code
	and 	is_active = true ;
	
	v_block_id = coalesce(v_block_id,0);
	
	return v_block_id;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_blockvalidation(_pg_id udd_code, _user_code udd_code)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
Declare 
	v_block_id public.udd_int := 0;
	v_block_code public.udd_code := '';
BEGIN
	select	 block_code into v_block_code
	from 	core_mst_tuserblock 
	where 	user_code = _user_code ;
	
	v_block_id := (select fn_get_blockid(v_block_code));
	-- CR NO : CR0001 / Resource - EMP20019 / 24-jan-2023 / CS-001
--    if exists (	select * from pg_mst_tpanchayatmapping
-- 			   	where 	 pg_id = _pg_id 
-- 			   	and 	 block_id = v_block_id) then
-- 				return TRUE;
	if exists (	select * from pg_mst_tpanchayatmapping
			   	where 	 pg_id = _pg_id 
			   	and 	 block_id = v_block_id) then
				return TRUE;
	else
		return FALSE;
   end if;
   -- CR NO : CR0001 / Resource - EMP20019 / 24-jan-2023 / CE-001	
END
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_bpapprovedcount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_bpapprovedcount public.udd_int := 0;
BEGIN
	
	 select count(distinct bp.bussplan_id)  into v_bpapprovedcount
	 from          pg_mst_tproducergroup as pg 
	 inner join    pg_trn_tbussplan as bp
	 on            bp.pg_id       = pg.pg_id
	 where 		   pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	 and		   pg.status_code = 'A'
	 and           bp.status_code = 'A';
	 
	v_bpapprovedcount = coalesce(v_bpapprovedcount,0);
	
	return v_bpapprovedcount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_bpprodharvestqty(_pg_id udd_code, _finyear_id udd_code, _prod_code udd_code)
 RETURNS udd_qty
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_tot_qty public.udd_qty := 0;
BEGIN
	 select COALESCE(sum(harvesting_qty),0) into v_tot_qty 
	 from 	pg_trn_tbussplanproduce 
	 where 	pg_id 		= _pg_id
	 and 	finyear_id 	= _finyear_id
	 and 	prod_code 	= _prod_code;
 
	return v_tot_qty;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_bpsubmitedcount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_bpsubmitedcount public.udd_int := 0;
BEGIN

	 select count(distinct pg.pg_id)  into v_bpsubmitedcount
	 from          pg_mst_tproducergroup as pg 
	 inner join    pg_trn_tbussplan as bp
	 on            bp.pg_id       = pg.pg_id
	 where 		   pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	 and		   pg.status_code = 'A';
-- 	 and           bp.status_code = 'S';
	 
	v_bpsubmitedcount = coalesce(v_bpsubmitedcount,0);
	
	return v_bpsubmitedcount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_collpoint_name(_pg_id udd_code, _collpoint_no udd_int, _collpoint_lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_collpoint_name public.udd_text := '';
BEGIN

		select  collpoint_ll_name into v_collpoint_name 
		from 	pg_mst_tcollectionpoint
		where 	pg_id =  _pg_id
		and 	collpoint_no = _collpoint_no
		and 	collpoint_lang_code = _collpoint_lang_code;
		
		if v_collpoint_name = '' or  v_collpoint_name isnull then
			select  collpoint_name into v_collpoint_name 
			from 	pg_mst_tcollectionpoint
			where 	pg_id =  _pg_id
			and 	collpoint_no = _collpoint_no
			and 	collpoint_lang_code = _collpoint_lang_code;
		end if;

	v_collpoint_name = coalesce(v_collpoint_name,'');
	
	return v_collpoint_name;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_concatvillage(_pg_id udd_desc, _panchayat_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By		: Mohan S
		Created Date	: 21-01-2023
		Function Code 	: 
	*/
	
	v_village_desc udd_text;
BEGIN
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
	 select c.village_desc into v_village_desc from (select 
				 pg_id,
				 panchayat_id,
				 STRING_AGG((select fn_get_villagedesc(village_id)::udd_text),',') as village_desc
	  from 		 pg_mst_tvillagemapping
	  where 	 pg_id = _pg_id
	  and 		 panchayat_id = _panchayat_id
	  group by pg_id,panchayat_id) as c;
	
	v_village_desc = coalesce(v_village_desc,'');
	
	RETURN v_village_desc;
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_concatvillage_id(_pg_id udd_desc, _panchayat_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By		: Mohan S
		Created Date	: 21-01-2023
		Function Code 	: 
	*/
	
	v_village_id udd_text;
BEGIN
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
	 select c.village_id into v_village_id from (select 
				 pg_id,
				 panchayat_id,
				 STRING_AGG(village_id::udd_text,',') as village_id
	  from 		 pg_mst_tvillagemapping
	  where 	 pg_id = _pg_id
	  and 		 panchayat_id = _panchayat_id
	  group by pg_id,panchayat_id) as c;
	
	v_village_id = coalesce(v_village_id,'');
	
	RETURN v_village_id;
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_concatvillage_jsonb(_pg_id udd_desc, _panchayat_id udd_int, _village_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By		: Mohan S
		Created Date	: 21-01-2023
		Function Code 	: 
	*/
	
	v_village_desc_jsonb udd_text;
BEGIN
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CS-001
	DROP TABLE if exists temp_village_jsonb;
	create temporary table temp_village_jsonb as
	select 
				 pg_id,
				 panchayat_id,
				'['||
				 	string_agg('{""village_id"":'||village_id||',""village_name_en"":""'||
					fn_get_villagedesc(village_id)||'""}',',')||
				']' as village_desc_jsonb
	  from 		 pg_mst_tvillagemapping
	  where 	 pg_id = _pg_id
	  and 		 panchayat_id = _panchayat_id
	  group by pg_id,panchayat_id;
	  
	  select village_desc_jsonb into v_village_desc_jsonb from temp_village_jsonb
	  where  pg_id = _pg_id
	  and 		 panchayat_id = _panchayat_id;
	
	v_village_desc_jsonb = coalesce(v_village_desc_jsonb,'');
	
	RETURN v_village_desc_jsonb;
-- CR NO : CR0001 / Resource - Emp10138 / 20-jan-2023 / CE-001
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_configvalue(_config_name udd_desc)
 RETURNS udd_desc
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By		: Vijayavel J
		Created Date	: 16-03-2022
		Function Code 	: 
	*/
	
	v_config_value udd_desc;
BEGIN
	SELECT 
   		config_value into v_config_value  
	FROM core_mst_tconfig
	where config_name = _config_name  
	and status_code = 'A';
	
	v_config_value = coalesce(v_config_value,'');
	
	RETURN v_config_value;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_districtcode(_district_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_district_code public.udd_text := '';
BEGIN
	select  district_code into v_district_code 
	from 	district_master 
	where 	district_id =  _district_id
	and 	is_active = true ;
	
	v_district_code = coalesce(v_district_code,'');
	
	return v_district_code;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_districtdesc(_district_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_district_desc public.udd_text := '';
BEGIN
	select district_name_en into v_district_desc 
	from 		district_master
	where 	district_id = _district_id
	and 	is_active = true;
	
	v_district_desc = coalesce(v_district_desc,'');
	return v_district_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_districtid(_district_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_district_id public.udd_int := 0;
BEGIN
	select  district_id into v_district_id 
	from 	district_master 
	where 	district_code =  _district_code
	and 	is_active = true ;
	
	v_district_id = coalesce(v_district_id,0);
	
	return v_district_id;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_docseqno(_activity_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
declare
	v_seq_no udd_int;
BEGIN
	SELECT 
   		docnum_seq_no into v_seq_no 
	FROM core_mst_tdocnum
	where activity_code = _activity_code 
	and status_code = 'A';
	
	update core_mst_tdocnum set 
		docnum_seq_no = docnum_seq_no + 1
	where activity_code = _activity_code 
	and status_code = 'A';
	
	RETURN v_seq_no;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_dueamount(_pg_id udd_code, _pgmember_id udd_code, _tran_date udd_date)
 RETURNS udd_amount
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created by 	 : Mohan S
		Created Date : 2022-03-30
	*/
	v_dueamount udd_amount := 0;
BEGIN
	
	SELECT 
		coalesce(sum(dr_amount+(case when tran_date >= _tran_date 
								     and acchead_code = 'QCD_MEM_PAYMENT' 
								then 0 else cr_amount*-1 end
							   )),0) into v_dueamount
	from pg_trn_tpgmemberledger
	where 	pg_id 		 = _pg_id
	and 	pgmember_id  = _pgmember_id
	and		tran_date 	 < _tran_date + INTERVAL '1 DAY'
	-- and 	acchead_code <> 'QCD_MEM_PAYMENT'
	and 	status_code  = 'A';
	
	v_dueamount := coalesce(v_dueamount,0);
	return v_dueamount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_finyear_procprodqty(_pg_id udd_code, _finyear_id udd_code, _prod_code udd_code)
 RETURNS udd_qty
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_tot_qty public.udd_qty := 0;
BEGIN
	 select COALESCE(sum(p.proc_qty),0) into v_tot_qty 
	 from 		core_mst_tfinyear as f 
	 inner join pg_trn_tprocureproduct as p 
	 on 	p.proc_date between f.finyear_start_date and f.finyear_end_date 
	 where 	f.finyear_id 	= _finyear_id
	 and 	p.pg_id 		= _pg_id
	 and 	p.prod_code 	= _prod_code
	 and 	f.status_code	= 'A';
 
	return v_tot_qty;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_fundrequamount(_pg_id udd_code, _fundreq_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_fundreq_amount public.udd_amount := 0;
BEGIN
	select  	coalesce(sum(coalesce(fdd.sanctioned_amount,0) - coalesce(fdtran.tranche_amount,0)),0) into v_fundreq_amount 
	from 		pg_trn_tfundrequisitiondtl as frdtl
	left join   pg_trn_tfunddisbursement as fdd on frdtl.pg_id = fdd.pg_id 
	and 		frdtl.fundreq_id = fdd.fundreq_id 
	and 		fdd.status_code = 'A'
	left join   pg_trn_tfunddisbtranche as fdtran on fdd.pg_id = fdtran.pg_id
	and 		fdd.funddisb_id = fdtran.funddisb_id
	where 		frdtl.pg_id =  _pg_id
	and			frdtl.fundreq_id = _fundreq_id;
	
	v_fundreq_amount = coalesce(v_fundreq_amount,0);
	
	return v_fundreq_amount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_fundrequesttotamt(_pg_id udd_code, _fundreq_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_fundreq_amount public.udd_amount := 0;
BEGIN 
	select  	coalesce(sum(fundreq_amount),0) into v_fundreq_amount 
	from 		pg_trn_tfundrequisitiondtl
	where 		pg_id =  _pg_id
	and			fundreq_id = _fundreq_id;
	
	v_fundreq_amount = coalesce(v_fundreq_amount,0);
	
	return v_fundreq_amount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_fundrequtotamount(_pg_id udd_code, _fundreq_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_fundreq_amount public.udd_amount := 0;
BEGIN 
	select  	coalesce(sum(frdtl.fundreq_amount),0) into v_fundreq_amount 
	from 		pg_trn_tfundrequisitiondtl as frdtl
	left join   pg_trn_tfunddisbursement as fdd on frdtl.pg_id = fdd.pg_id 
	and 		frdtl.fundreq_id = fdd.fundreq_id 
	and 		fdd.status_code = 'A'
	where 		frdtl.pg_id =  _pg_id
	and			frdtl.fundreq_id = _fundreq_id;
	
	v_fundreq_amount = coalesce(v_fundreq_amount,0);
	
	return v_fundreq_amount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_fundsantionedamount(_pg_id udd_code, _fundreq_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_fundsantioned_amount public.udd_amount := 0;
BEGIN 
	select  	coalesce(sum(sanctioned_amount),0)  into v_fundsantioned_amount 
	from   		pg_trn_tfunddisbursement 
	where 		pg_id =  _pg_id
	and			fundreq_id = _fundreq_id
	and			status_code = 'A';
	
	v_fundsantioned_amount = coalesce(v_fundsantioned_amount,0);
	
	return v_fundsantioned_amount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_grampanchayatid(_panchayat_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_panchayat_id public.udd_int := 0;
BEGIN
	select  panchayat_id into v_panchayat_id 
	from 	panchayat_master 
	where 	panchayat_code =  _panchayat_code
	and 	is_active = true ;
	
	v_panchayat_id = coalesce(v_panchayat_id,0);
	
	return v_panchayat_id;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_grantreceivedcount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_grantcount public.udd_int := 0;
BEGIN 
	
	select sum(dis.sanctioned_amount)  into v_grantcount
	from 			pg_mst_tproducergroup as pg
	inner join    	pg_trn_tfunddisbursement as dis
	on            	pg.pg_id       = dis.pg_id
	and 			dis.funddisb_type_code = 'GRANT'
	and				dis.status_code = 'A'
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and             pg.status_code = 'A';
	
	v_grantcount = coalesce(v_grantcount,0);
	
	return v_grantcount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_infrastructure(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_infrastructure public.udd_int := 0;
BEGIN
	
	--select fn_get_blockid(_block_code) into v_block_id;
	
	select 
			    coalesce (sum(fureqdtl.fundreq_amount),0) into v_infrastructure
	from        pg_mst_tproducergroup as pg
	inner join  pg_trn_tfundrequisition as fureq
	on          fureq.pg_id       = pg.pg_id
	and         fureq.status_code <> 'I'
	inner join  pg_trn_tfundrequisitiondtl as fureqdtl
	on          fureqdtl.fundreq_id        = fureq.fundreq_id
	and         fureqdtl.fundreq_head_code = 'QCD_INFRA'
	where       pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and			pg.status_code <> 'I';
	
	v_infrastructure = coalesce(v_infrastructure,0);
	
	return v_infrastructure;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_insertquery(_db_name text, _schema_name text, _table_name text, _prefix_tab_count integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
	v_table_field record;
	v_field text = '';
	v_param_field text = '';
	v_insert_qry text = '';
	v_prefix_tab text = '';
begin
	v_prefix_tab := repeat(chr(9),_prefix_tab_count);

	v_insert_qry := v_prefix_tab||'insert into '||_schema_name||'.'||_table_name||chr(13)||chr(10)
				  ||v_prefix_tab||'('||chr(13)||chr(10);
	
	for v_table_field in select column_name from information_schema.columns 
						where table_catalog = _db_name 
						and table_schema = _schema_name
						and table_name = _table_name
						and (column_default not like 'nextval%' or column_default is null)
		loop
			v_field := v_field||v_prefix_tab||chr(9)||v_table_field.column_name||','||chr(13)||chr(10);
			v_param_field := v_param_field||v_prefix_tab||chr(9)||'_'||v_table_field.column_name||','||chr(13)||chr(10);
		end loop;
	
	v_field := substring(v_field,1,length(v_field)-3);
	v_param_field := substring(v_param_field,1,length(v_param_field)-3);
	
	v_insert_qry := v_insert_qry
				  ||v_field||chr(13)||chr(10)
				  ||v_prefix_tab||')'||chr(13)||chr(10)
				  ||v_prefix_tab||'values'||chr(13)||chr(10)
				  ||v_prefix_tab||'('||chr(13)||chr(10)
				  ||v_param_field||chr(13)||chr(10)
				  ||v_prefix_tab||');';
	
	return v_insert_qry;
end
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_landdtl(_pgmember_id udd_code, _pgmemberland_id udd_code, _lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_land_dtl public.udd_text := '';
BEGIN
	select 		concat(fn_get_masterdesc('QCD_LAND_TYPE',land_type_code,_lang_code),
						'-',
						fn_get_masterdesc('QCD_OWNERSHIP_TYPE',ownership_type_code,_lang_code),
						'-',
						land_size::real,
					    '-',
					    cropping_area::real)  into v_land_dtl 
	from 		pg_mst_tpgmemberland
	where 		pgmember_id = _pgmember_id
	and 	    pgmemberland_id = _pgmemberland_id;
	
	v_land_dtl = coalesce(v_land_dtl,'');
	return v_land_dtl;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_languagedesc(_lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		created by : Mohan
		Created date : 27-07-2022
	*/
	v_lang_desc public.udd_text := '';
BEGIN
	select 	lang_name into v_lang_desc
	from 	core_mst_tlanguage
	where 	lang_code 	= _lang_code
	and 	status_code = 'A';
	
	v_lang_desc = coalesce(v_lang_desc,'');
	return v_lang_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_lldate(_date udd_date, _lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By 		: Mohan S
		Created Date 	: 12-04-2022
		Function Code 	:
	*/
	v_date udd_desc   := '';
	v_month udd_code  := '';
	v_year udd_desc   := '';
begin

	select 'QCD_' || upper(to_char(_date,'Mon')) into v_month;
	
	select to_char(_date::udd_date,'YY') into v_year;
	
	select 
		fn_get_masterdesc('QCD_MONTH',v_month,_lang_code) || '-' || v_year
	into v_date;
	
	return v_date;
end;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_loanamntapplied(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	loanamntapplied public.udd_int := 0;
BEGIN
	-- Pending : Fin year
	select sum(fdrqdtl.fundreq_amount)  into loanamntapplied
	from 			pg_mst_tproducergroup as pg
	inner join      pg_trn_tfundrequisition as fureq
	on              fureq.pg_id = pg.pg_id 
	and             fureq.status_code not in ('R','I')
	inner join		pg_trn_tfundrequisitiondtl as fdrqdtl
	on  			fureq.fundreq_id = fdrqdtl.fundreq_id
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and				pg.status_code  = 'A';
	
	loanamntapplied = coalesce(loanamntapplied,0);
 	
 return loanamntapplied;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_loanamntapproved(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	loanamntapproved public.udd_int := 0;
BEGIN
	
	select sum(fdrqdtl.fundreq_amount)  into loanamntapproved
	from 			pg_mst_tproducergroup as pg
	inner join      pg_trn_tfundrequisition as fureq
	on              fureq.pg_id = pg.pg_id 
	and             fureq.status_code = 'A'
	inner join		pg_trn_tfundrequisitiondtl as fdrqdtl
	on  			fureq.fundreq_id = fdrqdtl.fundreq_id
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and				pg.status_code  = 'A';
		
	loanamntapproved = coalesce(loanamntapproved,0);
	
	return loanamntapproved;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_loanborrowed(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	loanborrowed public.udd_int := 0;
BEGIN

	select sum(fudisb.sanctioned_amount)  into loanborrowed
	from 			pg_mst_tproducergroup as pg
	inner join      pg_trn_tfundrequisition as fureq
	on              pg.pg_id          = fureq.pg_id 
	and             fureq.status_code = 'A'
	inner join      pg_trn_tfunddisbursement as fudisb
	on              fureq.pg_id               = fudisb.pg_id
	and             fureq.fundreq_id          = fudisb.fundreq_id
	and             fudisb.funddisb_type_code = 'CREDIT'
	and             fudisb.status_code        = 'A'
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and             pg.status_code  = 'A';
		
	loanborrowed = coalesce(loanborrowed,0);
	
	return loanborrowed;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_lokoscaste(_pg_id udd_code, _caste_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_count public.udd_int := 0;
BEGIN
	select  count(pgmember_name) into v_count 
	from 	pg_mst_tpgmember 
	where 	pg_id =  _pg_id
	and 	caste_code = _caste_code
	and 	status_code <> 'R' ;
	
	v_count = coalesce(v_count,0);
	return v_count;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_lokoscaste_sc(_pg_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_count public.udd_int := 0;
BEGIN
	select  count(pgmember_name) into v_count 
	from 	pg_mst_tpgmember 
	where 	pg_id =  _pg_id
	and 	caste_code = '2'
	and 	status_code = 'A' ;
	
	v_count = coalesce(v_count,0);
	return v_count;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_lokoscaste_st(_pg_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_count public.udd_int := 0;
BEGIN
	select  count(pgmember_name) into v_count 
	from 	pg_mst_tpgmember 
	where 	pg_id =  _pg_id
	and 	caste_code = 2
	and 	status_code = 'A' ;
	
	v_count = coalesce(v_count,0);
	
	return v_count;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_lokosshgmemphone(_state_id integer, _member_id bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_phone_no character varying(10);
BEGIN
	select 	phone_no::character varying(10) into v_phone_no 
	from 	member_phone_details
	where 	member_code = _member_id
	limit 1;
	
	v_phone_no = coalesce(v_phone_no,'');
	return v_phone_no;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_lokosshgmemphone(_state_id integer, _member_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_phone_no character varying(10);
BEGIN
	select 	phone_no::udd_code into v_phone_no 
	from 	member_phone_details
	where 	member_code = _member_id
	limit 1;
	
	v_phone_no = coalesce(v_phone_no,'');
	return v_phone_no;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_mahilakisancount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	mahilakisancount public.udd_int := 0;
BEGIN
	
	select count(pgmem.pg_id)  into mahilakisancount
	from 			pg_mst_tproducergroup as pg
	inner join      pg_mst_tpgmember as pgmem
	on              pgmem.pg_id = pg.pg_id 
	and             pgmem.gender_code = '2'
	and             pgmem.status_code = 'A'
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and				pg.status_code  = 'A';

	mahilakisancount = coalesce(mahilakisancount,0);
	
	return mahilakisancount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_masterdesc(_parent_code udd_code, _master_code udd_code, _lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_master_desc public.udd_text := '';
BEGIN
	if _lang_code <> 'en_US' then
		select b.master_desc into v_master_desc 
		from 		core_mst_tmaster as a 
		inner join 	core_mst_tmastertranslate as b 
		on 		a.parent_code = b.parent_code 
		and 	a.master_code = b.master_code 
		where 	a.parent_code = _parent_code 
		and 	a.master_code = _master_code 
		and 	b.lang_code = _lang_code
		and 	a.status_code = 'A';

		v_master_desc = coalesce(v_master_desc,'');
		
		if v_master_desc <> '' then 
			return v_master_desc;
		else 
			return fn_get_masterdesc(_parent_code,_master_code,'en_US');
		end if;
	end if;
	
	select b.master_desc into v_master_desc 
	from 		core_mst_tmaster as a 
	inner join 	core_mst_tmastertranslate as b 
	on 		a.parent_code = b.parent_code 
	and 	a.master_code = b.master_code 
	where 	a.parent_code = _parent_code 
	and 	a.master_code = _master_code 
	and 	b.lang_code = 'en_US'
	and 	a.status_code = 'A';
	
	v_master_desc = coalesce(v_master_desc,'');
	
	return v_master_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_membercount_pgid(_pg_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_count public.udd_int := 0;
BEGIN
	select count(*) into v_count 
	from 		pg_mst_tpgmember as mem
	inner join 	pg_mst_tproducergroup as pg
	on 			mem.pg_id = pg.pg_id
	and 		pg.status_code <> 'I'
	where 		mem.pg_id = _pg_id
	and 		mem.status_code <> 'R';
	
	v_count = coalesce(v_count,0);
	return v_count;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_menudesc(_menu_code udd_code, _lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_menu_desc public.udd_text := '';
BEGIN
		select b.menu_desc into v_menu_desc 
		from 		core_mst_tmenu as a 
		inner join 	core_mst_tmenutranslate as b 
		on 		a.menu_code = b.menu_code
		where   a.menu_code = _menu_code
		and 	b.lang_code = _lang_code
		and 	a.status_code = 'A';
		
		v_menu_desc = coalesce(v_menu_desc,'');
		
		if v_menu_desc = '' then
			select b.menu_desc into v_menu_desc 
			from 		core_mst_tmenu as a 
			inner join 	core_mst_tmenutranslate as b 
			on 		a.menu_code = b.menu_code
			where   a.menu_code = _menu_code
			and 	b.lang_code = 'en_US'
			and 	a.status_code = 'A';
		end if;
		
		v_menu_desc = coalesce(v_menu_desc,'');
		
	return v_menu_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_msg(_msg_code udd_code, _lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_msg public.udd_text := '';
BEGIN
	select b.msg_desc into v_msg 
	from 		core_mst_tmessage as a 
	inner join 	core_mst_tmessagetranslate as b 
	on 		a.msg_code = b.msg_code 
	where 	a.msg_code = _msg_code 
	and 	b.lang_code = _lang_code
	and 	a.status_code = 'A';
	
	v_msg = coalesce(v_msg,'');
	
	if v_msg = '' then
		select b.msg_desc into v_msg 
		from 		core_mst_tmessage as a 
		inner join 	core_mst_tmessagetranslate as b 
		on 		a.msg_code = b.msg_code 
		where 	a.msg_code = _msg_code 
		and 	b.lang_code = 'en_US'
		and 	a.status_code = 'A';
	end if;
	
	v_msg = coalesce(v_msg,'');
	
	
	return v_msg;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_paidamount(_pg_id udd_code, _pgmember_id udd_code, _tran_date udd_date)
 RETURNS udd_amount
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created by 	 : Mohan S
		Created Date : 2022-03-30
	*/
	v_paidamount udd_amount := 0;
BEGIN
	
	SELECT 
		coalesce(sum(cr_amount),0) into v_paidamount
	from pg_trn_tpgmemberledger
	where 	pg_id 		 = _pg_id
	and 	pgmember_id  = _pgmember_id
	and		tran_date 	 >= _tran_date 
	and		tran_date 	 < _tran_date + INTERVAL '1 DAY'
	and 	acchead_code = 'QCD_MEM_PAYMENT'
	and 	status_code  = 'A';
	
	v_paidamount := coalesce(v_paidamount,0);
	return v_paidamount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_panchayatcode(_panchayat_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_panchayat_code public.udd_text := '';
BEGIN
	select  panchayat_code into v_panchayat_code 
	from 	panchayat_master 
	where 	panchayat_id =  _panchayat_id
	and 	is_active = true ;
	
	v_panchayat_code = coalesce(v_panchayat_code,'');
	
	return v_panchayat_code;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_panchayatdesc(_panchayat_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_panchayat_desc public.udd_text := '';
BEGIN
	select panchayat_name_en into v_panchayat_desc 
	from 		panchayat_master
	where 	panchayat_id = _panchayat_id
	and 	is_active = true;
	
	v_panchayat_desc = coalesce(v_panchayat_desc,'');
	return v_panchayat_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_panchayatid(_pg_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_panchayat_id public.udd_int := 0;
BEGIN
	select 		panchayat_id into v_panchayat_id 
	from 		pg_mst_taddress
	where 		pg_id = _pg_id 
	Limit 1;
	
	v_panchayat_id = coalesce(v_panchayat_id,0);
	return v_panchayat_id;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgcount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_pgcount public.udd_int := 0;
BEGIN
	
	select count(distinct pg.pg_id)  into v_pgcount
	from 			pg_mst_tproducergroup as pg
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and				pg.status_code = 'A';
	
	v_pgcount = coalesce(v_pgcount,0);
	
	return v_pgcount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgid(_block_id udd_int)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
DECLARE _id pg_mst_tpanchayatmapping.pg_id%TYPE;
BEGIN
   FOR _id IN SELECT 
   					distinct pg_id 
  			 FROM 	pg_mst_tpanchayatmapping
			 where  block_id = _block_id
   LOOP
     RETURN NEXT _id;
   END LOOP;
   RETURN;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgid(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
DECLARE _id pg_mst_tproducergroup.pg_id%TYPE;
BEGIN
	if _role_code = 'udyogmitra' then
					FOR _id IN	select 	  Distinct
										  pg.pg_id,
										  pg.pg_name
					  		from 		  pg_mst_tproducergroup as pg
							inner join 	  pg_mst_tudyogmitra as um on pg.pg_id = um.pg_id
				  			where 		  um.udyogmitra_id = _user_code
				 		    and 		  um.tran_status_code <> 'I'
							and 		  pg.status_code <> 'I'
	 LOOP
				RETURN NEXT _id;
	 END LOOP;
	 
	else 
		FOR _id IN SELECT Distinct	
						  pg.pg_id
			from 		  block_master as b
			inner join 	  pg_mst_tpanchayatmapping as pm on b.block_id = pm.block_id 
			inner join 	  pg_mst_tproducergroup as pg on pm.pg_id = pg.pg_id
			where 		  b.block_code = _block_code::udd_code 
			and 		  b.is_active = true 
			and 		  pg.status_code <> 'I'
		LOOP
					RETURN NEXT _id;
		END LOOP;
	
	end if;
	
	/*if _role_code = 'bo' or _role_code = 'bomanager' or _role_code = 'clfofficer'
	   or _role_code = 'clfmanager' or _role_code = 'Block Office Finance Manager' then
			FOR _id IN SELECT Distinct	
							  pg.pg_id
				from 		  block_master as b
				inner join 	  pg_mst_tpanchayatmapping as pm on b.block_id = pm.block_id 
				inner join 	  pg_mst_tproducergroup as pg on pm.pg_id = pg.pg_id
				where 		  b.block_code = _block_code::udd_code 
				and 		  b.is_active = true 
				and 		  pg.status_code <> 'I'
			 LOOP
				RETURN NEXT _id;
			 END LOOP;
	end if;*/

   RETURN;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgid(_block_code udd_code, _role_code udd_code)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
DECLARE _id pg_mst_tproducergroup.pg_id%TYPE;
BEGIN
--    FOR _id IN SELECT 
--    					distinct pg_id 
--   			 FROM 	pg_mst_tpanchayatmapping
-- 			 where  block_id = _block_id
--    LOOP
--      RETURN NEXT _id;
--    END LOOP;

	if _role_code = 'bo' then
			FOR _id IN SELECT Distinct	
							  pg.pg_id
				from 		  block_master as b
				inner join 	  pg_mst_tpanchayatmapping as pm on b.block_id = pm.block_id 
				inner join 	  pg_mst_tproducergroup as pg on pm.pg_id = pg.pg_id
				where 		  b.block_code = _block_code::udd_code 
				and 		  b.is_active = true 
				and 		  pg.status_code <> 'I'
			 LOOP
				RETURN NEXT _id;
			 END LOOP;
	end if;

   RETURN;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgmahilakisancount(_pg_id udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_mahilakisancount public.udd_int := 0;
BEGIN
	
	select count(pgmem.pg_id)  into v_mahilakisancount
	from 			pg_mst_tproducergroup as pg
	inner join      pg_mst_tpgmember as pgmem
	on              pgmem.pg_id = pg.pg_id 
	and             pgmem.gender_code = '2'
	and             pgmem.status_code = 'A'
	where 			pg.pg_id = _pg_id
	and				pg.status_code  = 'A';

	v_mahilakisancount = coalesce(v_mahilakisancount,0);
	
	return v_mahilakisancount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgmemberid(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_pgmemberid public.udd_int := 0;
BEGIN

	select count(pm.pgmember_id)  into v_pgmemberid
	from 			pg_mst_tproducergroup as pg
	inner join      pg_mst_tpgmember as pm
    on              pm.pg_id = pg.pg_id 	
	and				pm.status_code = 'A'
	and				pm.pgmember_clas_code = 'PG'
	where  			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and 			pg.status_code = 'A';
			
	v_pgmemberid = coalesce(v_pgmemberid,0);
	
	return v_pgmemberid;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgmemberinfo(_pg_id udd_code, _pgmember_id udd_code)
 RETURNS udd_json
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 02-03-2022
		Function Code :
	*/
	
	v_json udd_json;
BEGIN
	select  	json_build_object
				(
					'pgmember_name',	p.pgmember_name,
					'village_name',	max(v.village_name_en) 
				) into v_json 
	from 		pg_mst_tpgmember as p
	left join 	pg_mst_tpgmemberaddress a on p.pgmember_id = a.pgmember_id 
	left join 	village_master as v on a.village_id = v.village_id
	where 		p.pg_id =  _pg_id
	and 		p.pgmember_id = _pgmember_id
	group by p.pgmember_name;
	
	return v_json;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgmembermobileno(_pg_id udd_code, _pgmember_id udd_code)
 RETURNS udd_mobile
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By    : Mangai
		Created Date  : 29-03-2022
		Function Code :
	*/

	v_mobile_number public.udd_mobile := '';
BEGIN
	select  case when mobile_no_active = '' then
				mobile_no_alternative
			else
				mobile_no_active
			end
			into v_mobile_number 
	from 	pg_mst_tpgmember
	where 	pg_id =  _pg_id
	and 	pgmember_id = _pgmember_id; 
	
	v_mobile_number = coalesce(v_mobile_number,'');
	
	return v_mobile_number;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgmembername(_pg_id udd_code, _pgmember_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 02-03-2022
		Function Code :
	*/

	v_pgmember_name public.udd_text := '';
BEGIN
	select  pgmember_name into v_pgmember_name 
	from 	pg_mst_tpgmember
	where 	pg_id =  _pg_id
	and 	pgmember_id = _pgmember_id; 
	
	v_pgmember_name = coalesce(v_pgmember_name,'');
	
	return v_pgmember_name;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgmemberopeningqty(_pg_id udd_code, _pgmember_id udd_code, _stock_date udd_date, _prod_code udd_code, _grade_code udd_code)
 RETURNS udd_qty
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_opening_qty udd_qty := 0;
BEGIN
	/* get the opening for non-perishable product */
	
	if exists(	select  
			  		(opening_qty+proc_qty-sale_qty)
				from 	pg_trn_tpgmemberstockbydate 
				where 	pg_id 		=  _pg_id
			  	and		pgmember_id	= _pgmember_id
				and 	prod_code	= _prod_code
				and 	grade_code	= _grade_code
				and		stock_date 	< _stock_date
			  	and		prod_type_code = 'N' 
				and 	status_code	= 'A'
				order by stock_date desc 
				limit 1
			) then
		select  (opening_qty+proc_qty-sale_qty) into v_opening_qty 
		from 	pg_trn_tpgmemberstockbydate 
		where 	pg_id 		=  _pg_id
		and		pgmember_id	= _pgmember_id
		and 	prod_code	= _prod_code
		and 	grade_code	= _grade_code
		and		stock_date 	< _stock_date
		and 	status_code	= 'A'
		order by stock_date desc 
		limit 1;
	end if;
	
	return v_opening_qty;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgmembervillage(_pg_id udd_code, _pgmember_id udd_code, _lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created By : Vijayavel J
		Created Date : 02-03-2022
		Function Code :
	*/

	v_village_name public.udd_text := '';
BEGIN
	select  	max(v.village_name_en) into v_village_name 
	from 		pg_mst_tpgmember as p
	inner join 	pg_mst_tpgmemberaddress a on p.pgmember_id = a.pgmember_id 
	inner join 	village_master as v on a.village_id = v.village_id
	where 		p.pg_id =  _pg_id
	and 		p.pgmember_id = _pgmember_id;
	
	
	v_village_name = coalesce(v_village_name,'');
	
	return v_village_name;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pgname(_pg_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_pg_name public.udd_text := '';
BEGIN
	select  pg_name into v_pg_name 
	from 	pg_mst_tproducergroup 
	where 	pg_id =  _pg_id
	and 	status_code <> 'I';
	
	v_pg_name = coalesce(v_pg_name,'');
	
	return v_pg_name;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_productdesc(_prod_code udd_code, _lang_code udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_product_desc public.udd_text := '';
BEGIN
	select prod_desc into v_product_desc 
	from 	core_mst_tproducttranslate 
	where 	prod_code =  _prod_code
	and 	lang_code = _lang_code;
	
	v_product_desc = coalesce(v_product_desc,'');
	
	if v_product_desc = '' and _lang_code <> 'en_US' then
		select prod_desc into v_product_desc 
		from 	core_mst_tproducttranslate 
		where 	prod_code =  _prod_code
		and 	lang_code = 'en_US';

		v_product_desc = coalesce(v_product_desc,'');
	end if;
	
	return v_product_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_productopeningqty(_pg_id udd_code, _stock_date udd_date, _prod_code udd_code, _grade_code udd_code)
 RETURNS udd_qty
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_opening_qty udd_qty := 0;
BEGIN
	/* get the opening for non-perishable product */
	
	if exists(	select  
			  		(opening_qty+proc_qty-sale_qty)
				from 	pg_trn_tproductstockbydate 
				where 	pg_id =  _pg_id
				and 	prod_code	= _prod_code
				and 	grade_code	= _grade_code
				and		stock_date 	< _stock_date
			  	and		prod_type_code = 'N' 
				and 	status_code	= 'A'
				order by stock_date desc 
				limit 1
			) then
		select  (opening_qty+proc_qty-sale_qty) into v_opening_qty 
		from 	pg_trn_tproductstockbydate 
		where 	pg_id =  _pg_id
		and 	prod_code	= _prod_code
		and 	grade_code	= _grade_code
		and		stock_date 	< _stock_date
		and 	status_code	= 'A'
		order by stock_date desc 
		limit 1;
	end if;
	
	return v_opening_qty;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_pymtosamount(_pg_id udd_code, _pgmember_id udd_code, _tran_date udd_date)
 RETURNS udd_amount
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created by 	 : Mohan S
		Created Date : 2022-03-30
	*/
	v_osamount udd_amount := 0;
BEGIN
	
	SELECT 
		coalesce(sum(dr_amount+cr_amount*-1),0) into v_osamount
	from pg_trn_tpgmemberledger
	where 	pg_id 		 = _pg_id
	and 	pgmember_id  = _pgmember_id
	and		tran_date 	 < _tran_date + INTERVAL '1 DAY'
	and 	status_code  = 'A';
	
	v_osamount := coalesce(v_osamount,0);
	return v_osamount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_sanctionedamount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_sancamount public.udd_int := 0;
BEGIN

	select coalesce(sum(fd.sanctioned_amount),0) into v_sancamount
	from 			pg_mst_tproducergroup as pg
	inner join      pg_trn_tfunddisbursement as fd
	on              fd.pg_id       = pg.pg_id
	and             fd.status_code = 'A'
   	where 		    pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and 			pg.status_code = 'A';
		
	v_sancamount = coalesce(v_sancamount,0);
	
	return v_sancamount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_shgcodename(_shg_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_shgcode_name public.udd_text := '';
BEGIN
	If _shg_id = '' then 
		_shg_id = '0';
	end if;
	
	select  concat(shg_code,'-',shg_name) into v_shgcode_name 
	from 	shg_profile 
	where 	shg_id =  _shg_id::udd_int
	and 	is_active = true;
	
	v_shgcode_name = coalesce(v_shgcode_name,'');
	
	return v_shgcode_name;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_shgmemberpanchayat(_pg_id udd_code, _shg_member_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_panchayat_desc public.udd_text := '';
BEGIN
	select  panchayat_id::udd_code into v_panchayat_desc 
	from 	shgmember_profile_view 
	where 	pg_id =  _pg_id
	and 	shg_member_id::udd_code = _shg_member_id ;
	
	v_panchayat_desc = coalesce(v_panchayat_desc,'');
	
	return v_panchayat_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_shgmemberpanchayatdesc(_pg_id udd_code, _shg_member_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_panchayat_desc public.udd_text := '';
BEGIN
	select  panchayat_id into v_panchayat_desc 
	from 	shgmember_profile_view 
	where 	pg_id =  _pg_id
	and 	shg_member_id::udd_code = _shg_member_id ;
	
	select fn_get_panchayatdesc(v_panchayat_desc::udd_int)
	into v_panchayat_desc;
	
	v_panchayat_desc = coalesce(v_panchayat_desc,'');
	
	return v_panchayat_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_shgmembervillage(_pg_id udd_code, _shg_member_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_village_desc public.udd_text := '';
BEGIN
	select  village_id::udd_code into  v_village_desc
	from 	shgmember_profile_view 
	where 	pg_id =  _pg_id
	and 	shg_member_id::udd_code = _shg_member_id ;
	
	v_village_desc = coalesce(v_village_desc,'');
	
	return v_village_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_shgmembervillagedesc(_pg_id udd_code, _shg_member_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_village_desc public.udd_text := '';
BEGIN
	select  village_id into  v_village_desc
	from 	shgmember_profile_view 
	where 	pg_id =  _pg_id
	and 	shg_member_id::udd_code = _shg_member_id ;
	
	select fn_get_villagedesc(v_village_desc::udd_int)
	into v_village_desc;
	
	v_village_desc = coalesce(v_village_desc,'');
	
	return v_village_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_smstemplate(_smstemplate_code udd_code, _lang_code udd_code, INOUT _sms_template udd_text, INOUT _dlt_template_id udd_code)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By		: Mohan s
		Created Date	: 17-03-2022
		Function Code 	: 
	*/

BEGIN
	SELECT 
   		sms_template,dlt_template_id into _sms_template,_dlt_template_id
	FROM 	core_mst_tsmstemplate
	where 	smstemplate_code = _smstemplate_code
	and		lang_code = _lang_code
	and 	status_code = 'A';

END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_statecode(_state_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_state_code public.udd_text := '';
BEGIN
	select  state_code into v_state_code 
	from 	state_master 
	where 	state_id =  _state_id
	and 	is_active = true ;
	
	v_state_code = coalesce(v_state_code,'');
	
	return v_state_code;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_statedesc(_state_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_state_desc public.udd_text := '';
BEGIN
	select state_name_en into v_state_desc 
	from 		state_master
	where 	state_id = _state_id
	and 	is_active = true;
	
	v_state_desc = coalesce(v_state_desc,'');
	return v_state_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_stateid(_state_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_state_id public.udd_int := 0;
BEGIN
	select  state_id into v_state_id 
	from 	state_master 
	where 	state_code =  _state_code
	and 	is_active = true ;
	
	v_state_id = coalesce(v_state_id,0);
	
	return v_state_id;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_tablefield(_db_name text, _schema_name text, _table_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
	v_field_col record;
	v_field text = '';
begin
	for v_field_col in select column_name from information_schema.columns 
						where table_catalog = _db_name 
						and table_schema = _schema_name
						and table_name = _table_name
		loop
			v_field := v_field||v_field_col.column_name||','||chr(13)||chr(10);
		end loop;
	
	return v_field;
end
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_tranamount(_pg_id udd_code, _pgmember_id udd_code, _tran_date udd_date, _acchead_code udd_code)
 RETURNS udd_amount
 LANGUAGE plpgsql
AS $function$
DECLARE
	/*
		Created by 	 : Mohan S
		Created Date : 2022-03-29
	*/
	v_amount udd_amount := 0;
BEGIN
	
	if _acchead_code = 'QCD_SALES' then
		select 	coalesce(sum(dr_amount),0) into v_amount
		from 	pg_trn_tpgmemberledger
		where  	pg_id 			= _pg_id
		and	 	pgmember_id 	= _pgmember_id
		and		tran_date		>= _tran_date::udd_date
		and		tran_date		< _tran_date::udd_date  + INTERVAL '1 DAY'
		and		acchead_code	= _acchead_code
		and		status_code 	= 'A';
	else
		select 	coalesce(sum(cr_amount),0) into v_amount
		from 	pg_trn_tpgmemberledger
		where  	pg_id 			= _pg_id
		and	 	pgmember_id 	= _pgmember_id
		and		tran_date		>= _tran_date::udd_date
		and		tran_date		< _tran_date::udd_date  + INTERVAL '1 DAY'
		and		acchead_code	= _acchead_code
		and		status_code 	= 'A';
	end if;
	
	v_amount := coalesce(v_amount,0);
	return v_amount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_trancheamount(_pg_id udd_code, _funddisb_id udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_trancheamount public.udd_amount := 0;
BEGIN 
	select  	coalesce(sum(tranche_amount),0) into v_trancheamount 
	from 		pg_trn_tfunddisbursement as fdd
	inner join  pg_trn_tfunddisbtranche as fdt 
	on 			fdd.pg_id = fdt.pg_id 
	and 		fdd.funddisb_id = fdt.funddisb_id
	and 		tranche_status_code = 'QCD_RCVD'
	where 		fdt.pg_id =  _pg_id
	and			fdt.funddisb_id = _funddisb_id
	and			fdd.status_code = 'A';
	
	v_trancheamount = coalesce(v_trancheamount,0);
	
	return v_trancheamount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_umdeployedcount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_umdeploycount public.udd_int := 0;
BEGIN

	select count(distinct um.pg_id)  into v_umdeploycount
	from 			pg_mst_tproducergroup as pg
	inner join    	pg_mst_tudyogmitra as um
	on            	pg.pg_id        = um.pg_id
	and				um.tran_status_code <> 'I'
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and				pg.status_code  = 'A';

	
	v_umdeploycount = coalesce(v_umdeploycount,0);
	
	return v_umdeploycount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_uomconv(_uom_code_from udd_code, _uom_code_to udd_code, _qty udd_qty)
 RETURNS udd_qty
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_conv_rate public.udd_rate := 1;
BEGIN
	if exists( select conv_rate from core_mst_tuomconv
		where 	uom_code_from = _uom_code_from 
		and 	uom_code_to		= _uom_code_to 
		and 	status_code 	= 'A') then
		select 	conv_rate into v_conv_rate 
		from 	core_mst_tuomconv
		where 	uom_code_from = _uom_code_from 
		and 	uom_code_to		= _uom_code_to 
		and 	status_code 	= 'A';
	end if;

	return _qty*v_conv_rate;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_updatequery(_db_name text, _schema_name text, _table_name text, _prefix_tab_count integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
	v_table_field record;
	v_field text = '';
	v_update_qry text = '';
	v_prefix_tab text = '';
begin
	v_prefix_tab := repeat(chr(9),_prefix_tab_count);

	v_update_qry := v_prefix_tab||'update '||_schema_name||'.'||_table_name||' set '||chr(13)||chr(10);
	
	for v_table_field in select column_name from information_schema.columns 
						where table_catalog = _db_name 
						and table_schema = _schema_name
						and table_name = _table_name
						and (column_default not like 'nextval%' or column_default is null)
		loop
			v_field := v_field||v_prefix_tab||chr(9)||v_table_field.column_name
					 ||' = _'||v_table_field.column_name
					 ||','||chr(13)||chr(10);
		end loop;
	
	v_field := substring(v_field,1,length(v_field)-3);
	
	v_update_qry := v_update_qry
				  ||v_field||chr(13)||chr(10)
				  ||v_prefix_tab||'where 1 = 2;'||chr(13)||chr(10);
	
	return v_update_qry;
end
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_villagecode(_village_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_village_code public.udd_text := '';
BEGIN
	select  village_code into v_village_code 
	from 	village_master 
	where 	village_id =  _village_id
	and 	is_active = true ;
	
	v_village_code = coalesce(v_village_code,'');
	
	return v_village_code;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_villagecount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_villagecount public.udd_int := 0;
BEGIN
	
	select count(distinct vm.village_id)  into v_villagecount
	from 			pg_mst_tproducergroup as pg
	-- CR NO : CR0001 / Resource - Emp10138 / 23-jan-2023 / CS-001
	inner join	  	pg_mst_tvillagemapping as pm
	on           	pg.pg_id = pm.pg_id
	inner join 	    village_master as vm 
	on 				pm.village_id = vm.village_id
	-- CR NO : CR0001 / Resource - Emp10138 / 23-jan-2023 / CS-001
	and 			vm.is_active = true
	where 			pm.pg_id  in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and				pg.status_code = 'A';
	
	v_villagecount = coalesce(v_villagecount,0);
	
	return v_villagecount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_villagecount_pgid(_pg_id udd_code)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_count public.udd_int := 0;
BEGIN
	-- CR NO : CR0001 / Resource - Emp10138 / 23-jan-2023 / CS-001
		/*select count(village_id) into v_count 
		from 	pg_location_view	
		where 	pg_id = _pg_id;*/
		select count(village_id) into v_count 
		from 	pg_mst_tvillagemapping	
		where 	pg_id = _pg_id;
	-- CR NO : CR0001 / Resource - Emp10138 / 23-jan-2023 / CE-001
	v_count = coalesce(v_count,0);
	return v_count;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_villagedesc(_village_id udd_int)
 RETURNS udd_text
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_village_desc public.udd_text := '';
BEGIN
	select village_name_en into v_village_desc 
	from 		village_master
	where 	village_id = _village_id
	and 	is_active = true;
	
	v_village_desc = coalesce(v_village_desc,'');
	return v_village_desc;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_villageid(_village_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_village_id public.udd_int := 0;
BEGIN
	select  village_id into v_village_id 
	from 	village_master 
	where 	village_code =  _village_code
	and 	is_active = true ;
	
	v_village_id = coalesce(v_village_id,0);
	
	return v_village_id;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_withbankcount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_withbankcount public.udd_int := 0;
BEGIN
	
	select count(distinct bank.pg_id)  into v_withbankcount
	from 			pg_mst_tproducergroup as pg
	inner join    	pg_mst_tbank as bank
	on            	pg.pg_id       = bank.pg_id
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and				pg.status_code = 'A';
	
	v_withbankcount = coalesce(v_withbankcount,0);
	
	return v_withbankcount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_withoutbankcount(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_withoutbankcount public.udd_int := 0;
BEGIN
	
	--select fn_get_blockid(_block_code) into v_block_id;
	
	select count(distinct pg.pg_id)  into v_withoutbankcount
	from 			pg_mst_tproducergroup as pg
	inner join	  	pg_mst_tbank as bank
	on           	bank.pg_id    <> pg.pg_id
	where 			pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and             pg.status_code = 'A';
		
	v_withoutbankcount = coalesce(v_withoutbankcount,0);
	
	return v_withoutbankcount;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_withoutcapitaldisb(_block_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_withoutcapitaldisb public.udd_int := 0;
BEGIN
	
	select fn_get_blockid(_block_code) into v_block_id;
	
	select 
			    coalesce (sum(fd.sanctioned_amount),0) into v_withoutcapitaldisb
	from        pg_mst_tproducergroup as pg
	inner join	pg_mst_taddress as pgadd
	on          pgadd.pg_id          = pg.pg_id
	and 		pgadd.block_id       = v_block_id
	and         pgadd.addr_type_code = 'QCD_ADDRTYPE_REG'
	inner join  pg_trn_tfunddisbursement as fd
	on          fd.pg_id <> pg.pg_id
	where       pg.status_code <> 'I'
	and         fd.status_code = 'A';	
	
	v_withoutcapitaldisb = coalesce(v_withoutcapitaldisb,0);
	
	return v_withoutcapitaldisb;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_get_workingcapital(_block_code udd_code, _role_code udd_code, _user_code udd_code)
 RETURNS udd_int
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_block_id public.udd_int := 0;
	v_workingcapital public.udd_int := 0;
BEGIN
	
	--select fn_get_blockid(_block_code) into v_block_id;
	
	select 
			    coalesce (sum(fureqdtl.fundreq_amount),0) into v_workingcapital
	from        pg_mst_tproducergroup as pg
	inner join  pg_trn_tfundrequisition as fureq
	on          fureq.pg_id       = pg.pg_id
	and         fureq.status_code <> 'I'
	inner join  pg_trn_tfundrequisitiondtl as fureqdtl
	on          fureqdtl.fundreq_id        = fureq.fundreq_id
	and         fureqdtl.fundreq_head_code = 'QCD_WORK_CAP'
	where       pg.pg_id in (select fn_get_pgid(_block_code,_role_code,_user_code))
	and			pg.status_code <> 'I';
	
	v_workingcapital = coalesce(v_workingcapital,0);
	
	return v_workingcapital;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_text_todate(_date udd_text)
 RETURNS udd_date
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By 		: Vijayavel J
		Created Date 	: 09-03-2022
		Function Code 	:
	*/
begin
  perform _date::udd_date;
  return _date;
exception when others then
  return null;
end;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_text_todatetime(_datetime udd_text)
 RETURNS udd_datetime
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By 		: Vijayavel J
		Created Date 	: 09-03-2022
		Function Code 	:
	*/
begin
  perform _datetime::udd_datetime;
  return _datetime;
exception when others then
  return null;
end;
$function$
"
"CREATE OR REPLACE FUNCTION public.fn_text_torate(_rate udd_text)
 RETURNS udd_rate
 LANGUAGE plpgsql
AS $function$
declare
	/*
		Created By 		: Vijayavel J
		Created Date 	: 18-03-2022
		Function Code 	:
	*/
begin
  perform _rate::udd_rate;
  return _rate;
exception when others then
  return 0;
end;
$function$
"
"CREATE OR REPLACE FUNCTION public.generate_mobilesync_script(p_schema text, p_table text, p_where text, p_dest_table text, p_field_ignore text[])
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
 DECLARE
	 i	integer;
	 fld text[];
     dumpquery_0 text;
     dumpquery_1 text;
	 
     selquery text;
     selvalue text;
     valrec record;
     colrec record;
	 
	 colArray text[];
 BEGIN
     -- ------ --
     -- GLOBAL --
     --   build base INSERT
     --   build SELECT array[ ... ]
	 dumpquery_0 := 'INSERT or REPLACE INTO ';
	 
	 if p_dest_table <> '' then
     	dumpquery_0 := dumpquery_0 ||  quote_ident(p_dest_table) || '(';
	 else
     	dumpquery_0 := dumpquery_0 ||  quote_ident(p_table) || '(';
	 end if;
	 
     selquery    := 'SELECT array[';

     <<label0>>
     FOR colrec IN SELECT table_schema, table_name, column_name, data_type
                   FROM information_schema.columns
                   WHERE table_name = p_table and table_schema = p_schema
                   ORDER BY ordinal_position
     LOOP
	 	 if not (quote_ident(colrec.column_name) = ANY(p_field_ignore)) then
			 dumpquery_0 := dumpquery_0 || quote_ident(colrec.column_name) || ',';
			 selquery    := selquery    || 'CAST(' || quote_ident(colrec.column_name) || ' AS TEXT),';

			 colArray := colArray || quote_ident(colrec.column_name);
		 end if;
     END LOOP label0;

     dumpquery_0 := substring(dumpquery_0 ,1,length(dumpquery_0)-1) || ')';
     dumpquery_0 := dumpquery_0 || ' VALUES (';
     selquery    := substring(selquery    ,1,length(selquery)-1)    || '] AS MYARRAY';
     selquery    := selquery    || ' FROM ' ||quote_ident(p_schema)||'.'||quote_ident(p_table);
	 
	 if p_where <> '' then
     	selquery    := selquery    || ' WHERE '||p_where;
	 end if;
     -- GLOBAL --
     -- ------ --

     -- ----------- --
     -- SELECT LOOP --
     --   execute SELECT built and loop on each row
     <<label1>>
     FOR valrec IN  EXECUTE  selquery
     LOOP
         dumpquery_1 := '';
		 i := 1;
		 
         IF not found THEN
             EXIT ;
         END IF;

         -- ----------- --
         -- LOOP ARRAY (EACH FIELDS) --
         <<label2>>
         FOREACH selvalue in ARRAY valrec.MYARRAY
         LOOP
             IF selvalue IS NULL THEN 
				selvalue := 'NULL';
             ELSE 
				selvalue := quote_literal(selvalue);
             END IF;

             dumpquery_1 := dumpquery_1 || selvalue || ',';
			 
			 i := i + 1;
         END LOOP label2;
		 
         dumpquery_1 := substring(dumpquery_1 ,1,length(dumpquery_1)-1) || ')' || ';'; 
         -- LOOP ARRAY (EACH FIELD) --
         -- ----------- --

         -- debug: RETURN NEXT dumpquery_0 || dumpquery_1 || ' --' || selquery;
         -- debug: RETURN NEXT selquery;
         RETURN NEXT dumpquery_0 || dumpquery_1;

     END LOOP label1 ;
     -- SELECT LOOP --
     -- ----------- --

 RETURN ;
 END
 
$function$
"
"CREATE OR REPLACE FUNCTION public.generate_sync_script(p_schema text, p_table text, p_where text, p_dest_table text, p_conflict text[], p_update_ignore text[], p_field_ignore text[])
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
 DECLARE
	 i	integer;
	 fld text[];
     dumpquery_0 text;
     dumpquery_1 text;
	 updatefields_1 text;
	 conflict_fields text;
	 
     selquery text;
     selvalue text;
     valrec record;
     colrec record;
	 colArray text[];
	 colArrayUpdFlag boolean[];
 BEGIN
 	 conflict_fields := '';
	 
	 -- get conflict fields
	 for i in 1 .. array_upper(p_conflict,1)
	 LOOP
	 	conflict_fields := conflict_fields || p_conflict[i] || ',';
	 END LOOP;
	 
	 if conflict_fields <> '' then
	 	conflict_fields := substring(conflict_fields,1,length(conflict_fields)-1);
	 end if;
	 
     -- ------ --
     -- GLOBAL --
     --   build base INSERT
     --   build SELECT array[ ... ]
	 dumpquery_0 := 'INSERT INTO ';
	 
	 if p_dest_table <> '' then
     	dumpquery_0 := dumpquery_0 ||  quote_ident(p_dest_table) || '(';
	 else
     	dumpquery_0 := dumpquery_0 ||  quote_ident(p_table) || '(';
	 end if;
	 
     selquery    := 'SELECT array[';

     <<label0>>
     FOR colrec IN SELECT table_schema, table_name, column_name, data_type
                   FROM information_schema.columns
                   WHERE table_name = p_table and table_schema = p_schema
                   ORDER BY ordinal_position
     LOOP
	 	 if not (quote_ident(colrec.column_name) = ANY(p_field_ignore)) then
			 dumpquery_0 := dumpquery_0 || quote_ident(colrec.column_name) || ',';
			 selquery    := selquery    || 'CAST(' || quote_ident(colrec.column_name) || ' AS TEXT),';

			 colArray := colArray || quote_ident(colrec.column_name);

			 if quote_ident(colrec.column_name) = ANY(p_conflict) 
				or quote_ident(colrec.column_name) = ANY(p_update_ignore) then
				colArrayUpdFlag := colArrayUpdFlag || false;
			 else
				colArrayUpdFlag := colArrayUpdFlag || true;
			 end if;
		 end if;
     END LOOP label0;

     dumpquery_0 := substring(dumpquery_0 ,1,length(dumpquery_0)-1) || ')';
     dumpquery_0 := dumpquery_0 || ' VALUES (';
     selquery    := substring(selquery    ,1,length(selquery)-1)    || '] AS MYARRAY';
     selquery    := selquery    || ' FROM ' ||quote_ident(p_schema)||'.'||quote_ident(p_table);
	 
	 if p_where <> '' then
     	selquery    := selquery    || ' WHERE '||p_where;
	 end if;
     -- GLOBAL --
     -- ------ --

     -- ----------- --
     -- SELECT LOOP --
     --   execute SELECT built and loop on each row
     <<label1>>
     FOR valrec IN  EXECUTE  selquery
     LOOP
         dumpquery_1 := '';
		 updatefields_1 := '';
		 i := 1;
		 
         IF not found THEN
             EXIT ;
         END IF;

         -- ----------- --
         -- LOOP ARRAY (EACH FIELDS) --
         <<label2>>
         FOREACH selvalue in ARRAY valrec.MYARRAY
         LOOP
             IF selvalue IS NULL THEN 
				selvalue := 'NULL';
             ELSE 
				selvalue := quote_literal(selvalue);
             END IF;

             dumpquery_1 := dumpquery_1 || selvalue || ',';
			 
			 if colArrayUpdFlag[i] = true then
				updatefields_1 := updatefields_1 || colArray[i] || ' = ' || selvalue || ',';
			 end if;
			 
			 i := i + 1;
         END LOOP label2;
		 
         dumpquery_1 := substring(dumpquery_1 ,1,length(dumpquery_1)-1) || ')'; 
		 updatefields_1 := substring(updatefields_1,1,length(updatefields_1)-1);
		 
		 if conflict_fields <> '' then
		 	dumpquery_1 := dumpquery_1 
			            || ' on CONFLICT (' || conflict_fields || ') do update set '
		 			 	|| updatefields_1;
		 end if;
		 
		 dumpquery_1 := dumpquery_1 || ';';
         -- LOOP ARRAY (EACH FIELD) --
         -- ----------- --

         -- debug: RETURN NEXT dumpquery_0 || dumpquery_1 || ' --' || selquery;
         -- debug: RETURN NEXT selquery;
         RETURN NEXT dumpquery_0 || dumpquery_1;

     END LOOP label1 ;
     -- SELECT LOOP --
     -- ----------- --

 RETURN ;
 END
 
$function$
"
"CREATE OR REPLACE FUNCTION public.get_months(startdate date, enddate date)
 RETURNS TABLE(mon text, year integer)
 LANGUAGE plpgsql
AS $function$
declare d date;
begin
    d:= date_trunc('month', startdate);
    while d <= enddate loop
        mon:= to_char(d, 'Mon');
        year:= to_char(d, 'YYYY');
        /*days:= case 
            when d+ '1month'::interval > enddate then enddate- d+ 1
            when d < startdate then (d+ '1month'::interval)::date- startdate
            else (d+ '1month'::interval)::date- d
        end;*/
        return next;
        d:= d+ '1month'::interval;
		
    end loop;
end
$function$
"
"CREATE OR REPLACE FUNCTION public.jsoninsert(relname text, reljson text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$DECLARE
 ret RECORD;
 inputstring text;
BEGIN
  SELECT string_agg(quote_ident(key),',') INTO inputstring
    FROM json_object_keys(reljson::json) AS X (key);
  EXECUTE 'INSERT INTO '|| quote_ident(relname) 
    || '(' || inputstring || ') SELECT ' ||  inputstring 
    || ' FROM json_populate_record( NULL::' || quote_ident(relname) || ' , json_in($1)) RETURNING *'
    INTO ret USING reljson::cstring;
  RETURN ret;
END;
$function$
"
"CREATE OR REPLACE FUNCTION public.pivotcode1(tablename character varying, prefixc character varying, prefixct character varying, rowc character varying, colc character varying, cellc character varying, celldatatype character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare
	-- tablename: name of source table you want to pivot
	-- rowc: the name of the column in source table you want to be the rows
	-- colc: the name of the column in source table you want to be the columns
	-- cellc: an aggregate expression determining how the cell values will be created
	-- celldatatype: desired data type for the cells
	
    dynsql1 varchar;
    dynsql2 varchar;
    columnlist varchar;
begin
    -- 1. retrieve list of column names.
    dynsql1 = 'select string_agg(distinct ''''||'||colc||'||'' '||celldatatype||''','','' order by ''''||'||colc||'||'' '||celldatatype||''') from '||tablename||';';
    execute dynsql1 into columnlist;
    -- 2. set up the crosstab query
    dynsql2 = 'select * from crosstab (
 ''select '||prefixc||rowc||','||colc||','||cellc||' from '||tablename||' group by 1,2 order by 1,2'',
 ''select distinct '||colc||' from '||tablename||' order by 1''
 )
 as newtable (
 '||prefixct||rowc||' varchar,'||columnlist||'
 );';
    return dynsql2;
end
$function$
"
