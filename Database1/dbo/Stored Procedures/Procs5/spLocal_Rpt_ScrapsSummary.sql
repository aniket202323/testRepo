

----------------------------------------[Creation Of SP]-----------------------------------------

Create PROCEDURE dbo.spLocal_Rpt_ScrapsSummary
/*
Stored Procedure		:		spLocal_Rpt_ScrapsSummary
Author					:		Thiago Ribeiro (System Technologies for Industry Inc - Brazil)
Date Created			:		9-Jan-2009
SP Type					:		Report (called from excel)
Editor Tab Spacing	:		3

Description:
===========
This is a report stored procedure, that will return all the necessary information for the scraps report. It will be called
from the excel.

CALLED BY				:  	Excel


Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.0.0				9-Jan-2009		Thiago Ribeiro				Creation of SP
1.1.0				19-Mar-2009		Thiago Ribeiro				Report Changes <None for major and minor>; Also return production event with no 
																		scraps; changed the parameter of major and minor to varchar, so the field is 
																		passed.
1.2.0              	27-Apr-2017     Rakendra Lodhi              Added App Version and If Exists entry																	

Example:
exec [dbo].[spLocal_Rpt_ScrapsSummary] '2/19/2009 13:00:00','3/19/2009 15:00:00','2|3|4','','','','','pl_desc','pu_desc'

select * from events where pu_id = 8 and timestamp>='2/11/2009 13:00:00' and timestamp<='2/11/2009 15:00:00' order by timestamp desc
select wed_id, timestamp, amount from waste_event_details where pu_id = 8 and timestamp>='2/11/2009 13:00:00' and timestamp<='2/11/2009 15:00:00' order by timestamp desc
select * from waste_event_details where wed_id in (560,561,562,563,564,565,566,567,568,569,570,571)



*/
	--INPUTS
	@StartTime			datetime,
	@EndTime				datetime,
	@ParamLines			varchar(1000),
	@ParamProducts		varchar(300),
	@ParamShifts		varchar(100),
	@ParamTeams			varchar(100),
	@ParamReasons		varchar(500),
	@MajorGroupField	varchar(20),
	@MinorGroupField	varchar(20)
AS

SET NOCOUNT ON

--##################################################
--#### DECLARATIONS                             ####
--##################################################

--Tables declarations
DECLARE @Lines		TABLE
(
id_lines				integer IDENTITY(1,1),
pu_id					integer,
pu_desc				varchar(50),
pl_id 				integer,
pl_desc 				varchar(50),
dept_desc 			varchar(50)
)
DECLARE @Products	TABLE 
(
id_products			integer IDENTITY(1,1),
prod_id 				integer,
prod_desc 			varchar(50),
prod_code 			varchar(50),
batery_type			varchar(50),
sup_chem_type 		varchar(50),
chem_type			varchar(50)
)
DECLARE @Shifts	TABLE 
(
id_shifts 			integer IDENTITY(1,1),
cs_id 				integer,
shift_desc 			varchar(50),
team_desc 			varchar(50),
start_time			datetime,
end_time				datetime,
pu_id					integer
)
DECLARE @Reasons	TABLE 
(
id_reasons 			integer IDENTITY(1,1),
reason_id 			integer,
reason_desc 		varchar(50),
reason_code	 		varchar(50)
)
DECLARE @ProdEvents	TABLE 
(
id_prodevent		integer IDENTITY(1,1),
event_id				integer,
pu_id					integer,
start_time			datetime,
end_time				datetime,
event_num			varchar(50),
batch_num			varchar(50),
conv_factor			integer,
amount_good			decimal(20,2),
amount_total		decimal(20,2),
Unit1UOM				varchar(50),
Unit2UOM				varchar(50),
workcenter			varchar(50)
)
CREATE TABLE #Scraps
(
id_scraps 			integer IDENTITY(1,1),
[timestamp]			datetime,
workcenter 			varchar(50),
event_id				integer,
wasteevent_id		integer,
event_num	 		varchar(50),
shift_desc	 		varchar(50),
team_desc	 		varchar(50),
dept_desc	 		varchar(50),
pl_desc	 			varchar(50),
prod_code	 		varchar(50),
prod_desc	 		varchar(150),
battery_type 		varchar(50),
sup_chem_type 		varchar(50),
chem_type	 		varchar(50),
batch_num	 		varchar(50),
unit			 		varchar(50),
pu_desc		 		varchar(50),
reason_code	 		varchar(50),
reason_id	 		varchar(50),
amount		 		decimal(20,2),
conv_factor			integer,
amount_prdct 		decimal(20,2),
produced_amount	decimal(20,2),
total_produced		decimal(20,2),
user_desc			varchar(100),
resp_wc				varchar(50),
there_are_scraps	integer
)


--Simulating filters
-- SET @StartTime='2009-01-01 0:00:00'
-- SET @EndTime='2009-1-29 0:00:00'
-- SET @ParamLines='3'
-- SET @ParamProducts=''
-- SET @ParamShifts=''
-- SET @ParamTeams=''
-- SET @ParamReasons=''

--##################################################
--#### NOW WE WILL FILL THE FILTERS TEMP TABLES ####
--##################################################

--Verifying ST and ET
IF (@StartTime >= @EndTime)
	BEGIN
		--ERROR!!!!!!!!!!!!
		RETURN
	END

--Verifying lines that will be used
INSERT INTO @Lines(pl_id,pl_desc,dept_desc,pu_id,pu_desc) 
			(SELECT 
					pl.pl_id, 
					pl_desc, 
					dept_desc,
					pu_id,
					pu_desc
			FROM dbo.prod_lines pl 	WITH (NOLOCK)
			JOIN dbo.departments d 	WITH (NOLOCK)	ON 	pl.dept_id = d.dept_id 
			JOIN dbo.prod_units pu  WITH (NOLOCK)	ON 	pu.pl_id = pl.pl_id
			WHERE 
				(
					(
						pl.pl_id 			IN 	(SELECT [string] FROM dbo.fnLocal_STI_Cmn_SplitString (@ParamLines, '|')) 
						AND @ParamLines	>		'' 
						AND pl.pl_id		>		0
					)
					OR
					(
						pl.pl_id				>		0
						AND 					NOT	@ParamLines>''
					)
				)
				AND dbo.fnLocal_STI_Cmn_GetUDP(pu.pu_id, 'STLS_LS_MASTER_UNIT_ID', 'Prod_Units')=pu.pu_id
			)

--Verifying products that will be used
INSERT INTO @Products
			(
				prod_id,
				prod_desc,
				prod_code,
				batery_type
			)
			(
			SELECT DISTINCT
				p.prod_id, 
				p.prod_desc, 
				p.prod_code,
				pf.product_family_desc
			FROM dbo.products p  			WITH (NOLOCK)
			JOIN dbo.product_family pf  	WITH (NOLOCK)	ON	pf.product_family_id = p.product_family_id
			WHERE (
						p.prod_id 					IN (SELECT [string] FROM dbo.fnLocal_STI_Cmn_SplitString (@ParamProducts, '|')) 
						AND @ParamProducts 		>	''
					)
					OR
					(
						p.prod_id					>	0
						AND NOT @ParamProducts 	> 	''
					)
			)

--Now update superior chemical type
UPDATE @Products SET sup_chem_type =
			(
			SELECT 
				pg.product_grp_desc
			FROM dbo.product_group_data pgd 	WITH (NOLOCK)
			JOIN dbo.product_groups pg  		WITH (NOLOCK)	ON	pg.product_grp_id = pgd.product_grp_id 
																			AND pg.product_grp_desc like 'SCT-%'
			WHERE 
				pgd.prod_id = p.prod_id
			)
FROM @Products p

--Now update chemical type
UPDATE @Products SET chem_type =
			(
			SELECT 
				pg.product_grp_desc
			FROM dbo.product_group_data pgd  WITH (NOLOCK)
			JOIN dbo.product_groups pg  		WITH (NOLOCK)	ON	pg.product_grp_id = pgd.product_grp_id 
																			AND pg.product_grp_desc like 'CT-%'
			WHERE 
				pgd.prod_id = p.prod_id
			)
FROM @Products p



--Verifying shifts/team that will be used
INSERT INTO @Shifts(
						cs_id,
						shift_desc,
						team_desc,
						start_time,
						end_time,
						pu_id
						) 
						(
						SELECT
								cs_id,
								shift_desc,
								crew_desc,
								start_time,
								end_time,
								cs.pu_id
						FROM 	dbo.crew_schedule cs	WITH (NOLOCK)
						JOIN	@Lines l					ON l.pu_id = cs.pu_id
						WHERE 
								(
									(
										(
											crew_desc IN (SELECT [string] FROM dbo.fnLocal_STI_Cmn_SplitString (@ParamTeams, '|')) 
											AND @ParamTeams>''
										)
										OR (
												crew_desc				>	'' 
												AND NOT @ParamTeams	>	''
											)
									)
									AND 
									(
										(
											shift_desc IN (SELECT [string] FROM dbo.fnLocal_STI_Cmn_SplitString (@ParamShifts, '|')) 
											AND @ParamShifts>''
										)
										OR (
												shift_desc >'' 
												AND NOT @ParamShifts>''
											)
									)
								)
								AND NOT 
								(
									(
										start_time < @StartTime 
										AND end_time < @StartTime
									)
									OR 
									(
										start_time > @EndTime 
										AND end_time > @EndTime
									)
								)
						)


--Verifying reasons that will be used
INSERT INTO @Reasons(
							reason_id,
							reason_desc,
							reason_code
							) 
							(
							SELECT 
								event_reason_id,
								event_reason_name,
								event_reason_code
							FROM dbo.event_reasons  WITH (NOLOCK)
							WHERE 
								(
									event_reason_id 	IN (SELECT [string] FROM dbo.fnLocal_STI_Cmn_SplitString (@ParamReasons, '|')) 
									AND @ParamReasons	>	''
								)
								OR (
										event_reason_id>0 
										AND NOT @ParamReasons>''
									)
							)



--##################################################
--#### Bulding the query                        ####
--##################################################


INSERT INTO @ProdEvents (
								event_id, 
								pu_id, 
								end_time,
								event_num,
								workcenter
								) 
							(
							SELECT 
								e.event_id, 
								e.pu_id, 
								e.[timestamp],
								e.event_num,
								dbo.fnLocal_STI_Cmn_GetUDP(e.pu_id, 'Work_Center', 'Prod_Units')
							FROM dbo.events e 					WITH (NOLOCK)
							WHERE 
								e.[timestamp] 				>		@StartTime 
								AND e.[timestamp]			<=		@EndTime 
								AND e.pu_id					IN		(SELECT pu_id FROM @lines)
							)


--Updating Batch Names
UPDATE @ProdEvents 
		SET
			batch_num = t.result
		FROM @ProdEvents pe
			JOIN dbo.variables v WITH (NOLOCK)	ON		v.pu_id				=		pe.pu_id
															AND	v.extended_info	like	'%RptHook=BatchName%'
			JOIN dbo.tests t 		WITH (NOLOCK)	ON		t.result_on			=		pe.end_time
															AND	t.var_id				=		v.var_id

--Get the conversion factor from the actual spec and Unit1

UPDATE @ProdEvents SET 
	conv_factor =( SELECT TOP 1	acs.target
						FROM 				dbo.active_specs acs 		WITH (NOLOCK)
						JOIN				dbo.production_starts ps 	WITH (NOLOCK)	ON		pe.pu_id				=		ps.pu_id 
						JOIN 				dbo.specifications s 		WITH (NOLOCK)	ON		s.spec_id			=		acs.spec_id
						WHERE				char_id IN (
															SELECT	Char_Id
															FROM		dbo.pu_characteristics WITH (NOLOCK)
															WHERE		pu_id = pe.pu_id 
																		AND prod_id = ps.prod_id
															)
						AND				effective_date 	< 		pe.End_Time
						AND 				(
												expiration_date > pe.End_Time
												OR expiration_date IS NULL
											)
						AND				s.extended_info	LIKE	'%/ConversionFactor/%'
						AND				ps.start_time		<=		pe.end_time
						AND				(
											end_time				>=		pe.end_time
											OR end_time 		IS 	NULL
											)
						ORDER BY			effective_date DESC )
	FROM @ProdEvents pe


--Updating Product Amount (Good Product) - Adjusted Cases
UPDATE @ProdEvents
		SET
			amount_good = t.result
		FROM @ProdEvents pe
			JOIN dbo.variables v	WITH (NOLOCK)	ON		v.pu_id				=		pe.pu_id
															AND	v.extended_info	like	'%RptHook=AdjustedCases%'
			JOIN dbo.tests t WITH (NOLOCK)		ON		t.result_on			=		pe.end_time
															AND	t.var_id				=		v.var_id
/*
select v.var_id,t.result_on, t.result , convert(numeric(20,2),t.result)
from tests t
	inner join variables v on v.var_id = t.var_id
where v.extended_info	like	'%RptHook=AdjustedCases%'
		and t.result_on > '2009-4-13 6:00:00' and t.result_on <= '2009-4-20 6:00:00'
--		and isnumeric(t.result)=0
		and t.result is not null
order by t.result

6600087000.00

*/

UPDATE @ProdEvents 
SET Start_Time = 	(
						SELECT 	TOP 1 [timestamp]
						FROM 		events e WITH (NOLOCK)
						WHERE 
									e.[timestamp] 	< 	pe.End_Time 
									AND e.pu_id 	= 	pe.pu_id 
						ORDER BY e.[TimeStamp] DESC
						) 
					FROM @ProdEvents pe



UPDATE @ProdEvents
		SET 
			amount_total = amount_good + 
				(
				SELECT sum(wed.amount / CASE 
													WHEN (charindex('/ScrapUnit=1/',pu.extended_info)>0) THEN 
														pe.conv_factor 
													ELSE 
														1
												END)
				FROM @ProdEvents pe
					JOIN dbo.waste_event_details wed WITH (NOLOCK)	ON		wed.pu_id	=	pe.pu_id
					JOIN dbo.prod_units pu WITH (NOLOCK)				ON		pu.pu_id		=	wed.source_pu_id
				WHERE
							wed.[timestamp]	>		pe.start_time
					AND	wed.[timestamp]	<=		pe.end_time
					AND	fpe.event_id		=		pe.event_id
				)
		FROM @ProdEvents fpe



--Get the unit1uom for all the scraps from location = Unit1
UPDATE @ProdEvents SET 
	Unit1UOM =	(  SELECT TOP 1	acs.target
						FROM 				dbo.active_specs acs WITH (NOLOCK)
						JOIN				dbo.production_starts ps WITH (NOLOCK)	ON		pe.pu_id				=		ps.pu_id 
						JOIN 				dbo.specifications s WITH (NOLOCK)		ON		s.spec_id			=		acs.spec_id
						WHERE				char_id IN (
															SELECT	Char_Id
															FROM		dbo.pu_characteristics WITH (NOLOCK)
															WHERE		(
																		pu_id = pe.pu_id 
																		AND prod_id = ps.prod_id
																		)
															)
						AND				effective_date 	< 		pe.End_Time
						AND 				(
												expiration_date 		> 	pe.End_Time
												OR expiration_date 	IS NULL
											)
						AND				s.extended_info	LIKE	'%/Unit1UOM/%'
						AND				ps.start_time		<=		pe.end_time
						AND				(
											end_time				>=		pe.end_time
											OR end_time 		IS 	NULL
											)
						ORDER BY			effective_date DESC )
	FROM @ProdEvents pe


--Get the Unit2Uom for all the scraps from location = unit2
UPDATE @ProdEvents SET 
	Unit2UOM =	(  SELECT TOP 1	acs.target
						FROM 				dbo.active_specs acs WITH (NOLOCK)
						JOIN				dbo.production_starts ps WITH (NOLOCK)	ON		pe.pu_id				=		ps.pu_id 
						JOIN 				dbo.specifications s WITH (NOLOCK)		ON		s.spec_id			=		acs.spec_id
						WHERE				char_id IN (SELECT	Char_Id
															FROM		dbo.pu_characteristics WITH (NOLOCK)
															WHERE		(pu_id = pe.pu_id AND prod_id = ps.prod_id))
						AND				effective_date 	< 		pe.End_Time
						AND 				(
												expiration_date 		> 		pe.End_Time
												OR expiration_date 	IS 	NULL
											)
						AND				s.extended_info	LIKE	'%/Unit2UOM/%'
						AND				ps.start_time		<=		pe.end_time
						AND				(
											end_time				>=		pe.end_time
											OR end_time 		IS 	NULL
											)
						ORDER BY			effective_date DESC )
	FROM @ProdEvents pe


INSERT INTO #Scraps	(
							workcenter,
							[timestamp],
							event_id,
							wasteevent_id,
							event_num,
							shift_desc,
							team_desc,
							dept_desc,
							pl_desc,
							prod_code,
							prod_desc,
							battery_type,
							sup_chem_type,
							chem_type,
							batch_num,
							unit,
							pu_desc,
							reason_code,
							amount,
							amount_prdct,
							produced_amount,
							total_produced,
							user_desc,
							conv_factor,
							resp_wc,
							there_are_scraps
							)
				(
				SELECT
							pe.workcenter,
							CASE 
								WHEN (wed.[timestamp] IS NULL) THEN
									pe.end_time
								ELSE
									wed.[timestamp]
							END, --There is no Scrap event, so replace by the prod event timestamp
							pe.event_id,
							wed.wed_id,
							pe.event_num,
							cs.shift_desc,
							cs.team_desc,
							l.dept_desc,
							l.pl_desc,
							p.prod_code, 			--prod code
							p.prod_desc, 			--prod desc
							p.batery_type,			--batery type (product family)
							p.sup_chem_type,		--superior chemical type (prod group)
							p.chem_type,			--chemical type (prod group)
							pe.batch_num, 			--batch num
							CASE 
								WHEN (charindex('/ScrapUnit=1/',pu.extended_info)>0) THEN
									pe.unit1uom
								ELSE
									pe.unit2uom
							END, 					--engeniering unit (especificacao UOM)
							pu.pu_desc,				--production unit description
							r.reason_desc,			--reason_code
							CASE
								WHEN(wed.[timestamp] IS NULL) THEN
									0
								ELSE
									wed.amount
							END, 	--amount (scrap), if there is no Scrap Event, replace by zero
							CONVERT(decimal(20,2),wed.amount / 	CASE
																			 	WHEN (CHARINDEX('/ScrapUnit=1/',pu.extended_info)>0) THEN
																					pe.conv_factor
																				ELSE
																					1
																			END),	--amount product (amount convertido)
							pe.amount_good, 		--produced amount (good product) = adjusted cases
							pe.amount_total, 		--total produced (total product) = good+scrap
							u.username, 			--user
							CASE
								WHEN (CHARINDEX('/ScrapUnit=1/',pu.extended_info)>0) THEN
									pe.conv_factor
								ELSE
									1
							END,		--Conversion Factor
							CASE
								WHEN (r2.event_reason_name IS NULL) THEN
									pe.workcenter
								ELSE
									r2.event_reason_name
							END,	--Responsible Work Center (if responsible is blank, set it to workcenter)
							CASE
								WHEN(wed.[timestamp] IS NULL) THEN
									0
								ELSE
									1
							END
				FROM @ProdEvents pe
				LEFT JOIN dbo.waste_event_details wed WITH (NOLOCK) 	ON		wed.pu_id					=		pe.pu_id
																								AND	wed.[timestamp]	>		pe.start_time
																								AND	wed.[timestamp]	<=		pe.end_time
				LEFT JOIN @Shifts cs 											ON		cs.pu_id						=		pe.pu_id
																								AND	cs.start_time		<		pe.end_time
																								AND	cs.end_time			>=		pe.end_time
				JOIN @Lines l														ON		l.pu_id						=		pe.pu_id
				JOIN dbo.production_starts ps	WITH (NOLOCK) 				ON		ps.pu_id						=		pe.pu_id
				JOIN @Products p 													ON		p.prod_id 					=		ps.prod_id
				LEFT JOIN dbo.users u WITH (NOLOCK)							ON		u.[user_id]					=		wed.[user_id]
				LEFT JOIN @reasons r												ON		r.reason_id					=		wed.reason_level1
				LEFT JOIN dbo.event_reasons r2 WITH (NOLOCK)				ON		r2.event_reason_id		=		wed.action_level1
				LEFT JOIN dbo.prod_units pu WITH (NOLOCK)					ON		pu.pu_id						=		wed.source_pu_id
				WHERE
						ps.start_time		<=		pe.end_time
				AND	(
							ps.end_time		>=		pe.end_time
							OR ps.end_time	IS 	NULL
						)
				AND	(
							@ParamReasons	=		''
							OR (
								@ParamReasons	>	''
								AND
								r.reason_id		=	wed.reason_level1
								)
						)
				)


DECLARE @SQL	varchar(900)

SET @SQL = 'SELECT
					id_scraps,
					[timestamp],
					workcenter,
					event_id,
					wasteevent_id,
					event_num,
					shift_desc,
					team_desc,
					dept_desc,
					pl_desc,
					prod_code,
					prod_desc,
					battery_type,
					sup_chem_type,
					chem_type,
					batch_num,
					unit,
					pu_desc,
					reason_code,
					amount,
					conv_factor,
					amount_prdct,
					produced_amount,
					total_produced,
					user_desc,
					resp_wc,
					there_are_scraps
				FROM #Scraps
				ORDER BY '



--Define the order for major group
IF (@MajorGroupField > '')
	BEGIN
		SET @SQL = @SQL + @MajorGroupField
	END

--Define the order for minor group
IF (@MinorGroupField > '')
	BEGIN
		IF (@MajorGroupField IS NOT NULL)
		BEGIN
			SET @SQL = @SQL + ', '
		END
		SET @SQL = @SQL + @MinorGroupField
	END

IF (@MajorGroupField > '' OR @MinorGroupField > '') --If we have no order by from the minor group, there is no need of the comma
BEGIN
	SET @SQL = @SQL + ', '
END
SET @SQL = @SQL + 'there_are_scraps'

--If filters are not already ordered by timestamp, after the two first orders, order by timestamp
IF (CHARINDEX('timestamp',@MajorGroupField,1)=0 AND CHARINDEX('timestamp',@MinorGroupField,1)=0) --Time isn't already on the order by
	BEGIN
		SET @SQL = @SQL + ', [timestamp]'
	END



--Execute the procedure
EXEC (@SQL)

--Drop the temp table created only for this report built
DROP TABLE #Scraps

SET NOCOUNT OFF


