 
 
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS__DBUG_ClearBomfi_Dstation_ItemStatus]
	@ProcessOrder	VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
 
 
/*
	for plain select, uncomment --A-- and comment out --B-- and --C--
	to update (must exist) comment --A-- and --C--, uncomment --B--
	to insert (must not exist) comment --A-- and --B-- and uncomment --C--
*/
 
declare @a table
(
	ppid int,
	po varchar(50),
	postatus varchar(50),
	puid int,
	bomfi_id int,
	prod_id int,
	bomstatus varchar(50) default '*MISSING*',
	dstation varchar(50) default '*MISSING*',
	status varchar(50),
	prod_code varchar(50),
	bomqty float
)
 
insert @a (ppid,po,postatus,puid,prod_id,bomfi_id, bomqty)
	select
		pp.pp_id,
		pp.process_order,
		pps.PP_Status_Desc,
		bomfi.pu_id,
		bomfi.prod_id,
		bomfi.bom_formulation_item_id,
		bomfi.Quantity
	from dbo.Bill_Of_Material_Formulation_Item bomfi
		join dbo.production_plan pp on bomfi.bom_formulation_id = pp.bom_formulation_id
		join production_plan_statuses pps on pps.pp_status_id = pp.pp_status_id
	where pp.path_id in (83)
 
-- need these updates here so *missing* is for udp that doesn't exist and not just NULL since NULL is a valid value for dstation.
update a
	set bomstatus = bstatus.value
	from @a a
		cross apply dbo.fnLocal_MPWS_GetUDP(a.bomfi_id, 'BOMItemStatus',     'Bill_Of_Material_Formulation_Item') bstatus
 
update a
	set dstation = dstation.value
	from @a a
		cross apply dbo.fnLocal_MPWS_GetUDP(a.bomfi_id, 'DispenseStationId',     'Bill_Of_Material_Formulation_Item') dstation
 
update a
	set status = pps.PP_Status_Desc
	from @a a
	join Production_Plan_Statuses pps on  a.bomstatus = pps.PP_Status_Id
 
update a
	set prod_code = p.prod_code
	from @a a
	join products p on p.prod_id = a.prod_id
--A--
select * from @a
 
--B--
---- UPDATE UDP
--update dbo.table_fields_values
--	SET	Value					= null	
--	from dbo.Table_Fields_Values tfv
--		join @a a on a.bom_formulation_item_id = tfv.keyid
--	WHERE TableId = 28	
--		AND Table_Field_Id = 342	-- 342 disp station, 343 bomstatus
--		AND dstation <> '*MISSING*'		-- can't update a value that does not exist
 
--C--
---- CREATE NEW UDP
--INSERT	dbo.Table_Fields_Values 
--	select
--		a.bom_formulation_item_id, 342, 28, NULL	-- 342 disp station, 343 bomstatus
--	from @a a
--	where dstation = '*MISSING*'	-- can only insert when it does not exist, else you'll get a constraint error
 
 
 
--select value
--from dbo.table_fields_values
--where tableid = 28
--and table_field_id = 343
 
