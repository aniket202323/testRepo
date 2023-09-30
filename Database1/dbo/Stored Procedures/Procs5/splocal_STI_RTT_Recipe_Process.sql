






CREATE    PROCEDURE dbo.splocal_STI_RTT_Recipe_Process
/*
---------------------------------------------------------------------------------
Version:	1.0.1
On:		10-Nov-2004
FRio:		Added header miscelaneous information for the report.
---------------------------------------------------------------------------------
Created by: 	Eric Perron, Solutions et Technologies Industrielles inc.
On:		15-jun-2004
Version: 	1.0.0
Purpose: 	This sp return all RTT variables with specs and values.
---------------------------------------------------------------------------------
*/
-- EP 28-jun-2004 change the output : add result_on and order by sheets.sheet_desc, sheet_variables.var_order


-- splocal_STI_RTT_Recipe_Process null,'dimp128',null
--declare
	@ParamTimestamp				datetime,
	@ParamPL_desc				varchar(50),
	@ParamGroup				varchar(50)
AS
-- Test statement
--set 	@ParamTimeStamp = NULL
--set 	@ParamPL_Desc 	= 'DIMP132'
--set 	@ParamGroup = NULL
--
declare
@PL_id  				int,
@TimeStamp				datetime,
@Site 					nvarchar(100)

-- Get the Site Name
select @site = value from site_parameters where parm_id = 12
--
create   table #Sti_LastEvent (
pu_id 			int, 
[timestamp] datetime,
prod_id 		int,
Prod_code 	varchar(25)
)

if @ParamPL_desc is null
	begin
		select @pl_id = null
	end
else
	begin
		select @pl_id = pl_id from prod_lines where pl_desc = @ParamPL_desc
	end


if @ParamTimestamp is null or ltrim(rtrim(@ParamTimestamp)) = ''
	select @Timestamp = getdate()
else
	select @Timestamp=@ParamTimestamp


insert into #Sti_LastEvent 
	select 
		pu.pu_id ,(select top 1 timestamp from events e 
           	where e.pu_id = pu.pu_id and timestamp <=@Timestamp 
		order by timestamp desc), ps.prod_id,p.prod_code
	from 
		prod_units pu , production_starts ps, products p
	where 
		pu.pu_desc Like '%RTT' and
		pu.pl_id = @pl_id  and
		ps.prod_id = p.prod_id and 
		ps.pu_id = pu.Pu_id and
		ps.start_time < @Timestamp and
		(ps.end_time >= @Timestamp or end_time is null)
 

Select @Site as Site, @TimeStamp as StartDate, (select top 1 prod_code from #Sti_LastEvent) as Prod_Code,@ParamPL_Desc as Line

Select pu.prod_code, 
	s.sheet_id, pg.pug_desc, s.sheet_desc,
	v.var_id,  v.var_desc [Variable Description], v.Eng_Units [Units],
	vs.L_Reject LSL, vs.L_Warning LCL,vs.L_User LWL,vs.Target Target,vs.U_User UWL,vs.U_Warning UCL,vs.U_Reject USL, vs.Test_Freq,
	(select result from tests t where result_on = pu.timestamp and t.var_id = v.var_id) Result, 
	pu.timestamp Result_on
	from pu_groups pg
	inner join #Sti_LastEvent pu on pg.pu_id = pu.pu_id and (pug_desc like 'RTT EA_ Recipe%' or pug_desc like 'RTT EA_ Auto%')
	inner join variables v on v.pug_id = pg.pug_id and isnumeric(substring(var_desc,1,1)) <> 0 and v.var_desc not like '%_RAW'
	inner join var_specs vs on vs.var_id = v.var_id and vs.prod_id = pu.prod_id and vs.expiration_date is null 
	inner join sheet_variables sv on sv.var_id = v.var_id
	inner join sheets s on s.sheet_id = sv.sheet_id and s.sheet_type = 2
	order by s.sheet_desc, sv.var_order

drop table #STI_LastEvent












