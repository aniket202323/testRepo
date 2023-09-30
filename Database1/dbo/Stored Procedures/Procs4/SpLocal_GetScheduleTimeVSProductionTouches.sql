


/*
--------------------------------------------------------------
Name: [SpLocal_GetScheduleTimeVSProductionTouches]
Purpose: Get Aggregated Data for NPT touches by Production Line as well as Raw data based on the input to the SP
--------------------------------------------------------------

Created BY : Akshay Kasurde
Date 26-Mar-2020

Change Log
--------------------------------------------------------------
Date: 26-Mar-2020		Initial Version
--------------------------------------------------------------
*/



CREATE PROCEDURE [SpLocal_GetScheduleTimeVSProductionTouches]
	 @Start		DATETIME
	,@End		DATETIME
	,@FetchRawData	BIT

AS
BEGIN

--Uncomment for Debugging Only
--SELECT
--	 @Start		= '1/1/2020'
--	,@End		= '2/1/2020'
--	,@FetchRawData =1

DECLARE
	@TableID	INT					--the table ID

--create temp table
CREATE TABLE #DTEquipmentAndPaths (
	 ID				INT IDENTITY
	,DeptID			INT
	,Department		VARCHAR(50)
	,PLID			INT
	,[Line]			VARCHAR(50)
	,[Unit]			VARCHAR(50)
	,UnitID			INT
	,PathID			INT
	,PathCode		VARCHAR(50)
	,[Status]		VARCHAR(50)
	,ModifiedOn		DATETIME
	,ScheduledUnitID	INT
	)
CREATE TABLE #DTEquipmentwithDowntimeNoPaths (
	 ID				INT IDENTITY
	,DeptID			INT
	,Department		VARCHAR(50)
	,PLID			INT
	,[Line]			VARCHAR(50)
	,[Unit]			VARCHAR(50)
	,UnitID			INT
	,[Status]		VARCHAR(50)
	,ModifiedOn		DATETIME
	)

CREATE TABLE #ProdPlan (
	 ID				INT IDENTITY
	,TableID		INT					--tables.tableid
	,TableKeyID		INT					--the key of the table in TableID
	,PathCode		VARCHAR(50)			--prdexec_paths.path_code
	,PathID			INT					--prdexec_paths.path_id
	,Unit			VARCHAR(50)			--prod_units_base.pu_desc
	,UnitID			INT					--prod_units_base.pu_id
	,StartTime		DATETIME			--the event start
	,EndTime		DATETIME			--the event end
	,ScheduledUnitID	INT
	,ProcessOrder	VARCHAR(50)			--produciton_paln.process_order
	,ProdID			INT					--products_base.prod_id
	,ProdCode		VARCHAR(50)			--products_base.prod_code
	,EventStatus	VARCHAR(50)			--the status of the event
	,UpdateType		VARCHAR(50)			--the type of operation
	)

CREATE TABLE #TimePlan (
	 ID				INT IDENTITY		--the idneity of the table
	,RecordType		VARCHAR(50)			--the type of record
	,TableKeyID		INT					--the key of the table in the RecordType
	,DeptID			INT					--department_base.dept_id
	,Department		VARCHAR(50)			--department_base.dept_desc
	,PLID			INT					--prod_lines_base.pl_id
	,Line			VARCHAR(50)			--prod_lines_base.pl_desc
	,UnitID			INT					--prod_units_base.pu_id
	,Unit			VARCHAR(50)			--prod_units_base.pu_desc
	,StartTime		DATETIME			--the event start
	,EndTime		DATETIME			--the event end
	,EventStatus	VARCHAR(50)			--the status of the event
	,ModifiedOn		DATETIME			--the time the record was modified
	,Username		VARCHAR(50)			--users_base.username of the user making the record change
	,UpdateType		VARCHAR(50)			--the type of operation
	,ProdPlanID		INT					--#prodPlan.ID for the time range of this record
	,ScheduledUnitID	INT
	)

CREATE TABLE #ProdPlanUnits (
	 ID			INT IDENTITY
	,UnitID		INT
	)
CREATE TABLE #TimePlanUnits (
	 ID				INT IDENTITY
	,TPUnitID		INT
	,PPUnitID		INT
	)

CREATE TABLE #FinalData (
	 ID								INT IDENTITY
	,RecordType						VARCHAR(50)									--'Final Data'
	,[Planned Record Type]			VARCHAR(50)									--tp.RecordType
	,[Planned Record TableID]		INT											--tp.TableKeyID
	,[Department]					VARCHAR(50)									--tp.Department		
	,[Line]							VARCHAR(50)									--tp.Line			
	,[Planned Record]				VARCHAR(50)									--tp.Unit			
	,[Planned Record Start]			DATETIME									--tp.StartTime		
	,[Planned Record End]			DATETIME									--tp.EndTime		
	,[Planned Record Status]		VARCHAR(50)									--tp.EventStatus	
	,[Planned Record Modified On]	DATETIME									--tp.ModifiedOn		
	,[Planned Record Update Type]	VARCHAR(50)									--tp.UpdateType	
	,[Planned Record User Changed]	VARCHAR(50)									--tp.username		[User making the Record Change]
	,[Production Record Table]		VARCHAR(50)									--t.TableName		[Table of the Production Run]
	,[Production Record Path Code]	VARCHAR(25)									--pp.PathCode		
	,[Production Record Path ID]	INT											--pp.PathID			
	,[Production Record Unit]		VARCHAR(50)									--pp.Unit			
	,[Production Record Start]		DATETIME									--pp.StartTime		
	,[Production Record End]		DATETIME									--pp.EndTime		
	,[Production Record PO]			VARCHAR(25)									--pp.ProcessOrder	
	,[Production Record Prod Code]	VARCHAR(25)									--pp.ProdCode		
	,[Planned Start Status]			VARCHAR(20)
	,[Bad Start]					INT
	,[Planned End Status]			VARCHAR(20)
	,[Bad End]						INT
	,[Overall Status]				VARCHAR(20)
	,[Bad Record]					INT
	)


CREATE TABLE #Aggregates(
	ID								INT IDENTITY
	,[Production Line]				VARCHAR(50)
	,[Overall Record Count]			INT
	,[Number Of Overall Failed Records]	INT
	,[Number of Bad End Records]	INT
	,[Number Of Bad Start Records]	INT
	,[Overall Percent Failure]		FLOAT
	)

--Just get the units and the paths
INSERT INTO #DTEquipmentAndPaths(
	 DeptID			
	,Department		
	,PLID	
	,Line		
	,Unit
	,UnitID			
	,PathID
	,PathCode 
	,[Status]		

	)

SELECT
	 d.dept_id
	,d.dept_desc
	,pl.pl_id
	,pl.pl_desc
	,pu.pu_desc
	,pu.pu_id
	,paths.Path_Id
	,paths.Path_code
	,'Current'
FROM dbo.prdexec_paths paths WITH(NOLOCK) 
JOIN dbo.prdexec_path_units punits WITH(NOLOCK) ON punits.path_id = paths.path_id
JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = punits.pu_id
JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id = pu.pl_id
JOIN dbo.departments_base d WITH(NOLOCK) On d.dept_id = pl.dept_id
JOIN dbo.event_configuration ec WITH(NOLOCK) ON ec.pu_id = punits.pu_id
JOIN dbo.event_types et WITH(NOLOCK) ON et.et_id = ec.et_id
WHERE et.et_desc = 'Downtime' AND ec.is_active = 1

INSERT INTO #DTEquipmentAndPaths(
	 DeptID			
	,Department		
	,PLID	
	,Line		
	,Unit
	,UnitID	
	,PathID
	,PathCode 
	,ModifiedOn
	,[Status]		
	)
SELECT
	 d.dept_id
	,d.dept_desc
	,pl.pl_id
	,pl.pl_desc
	,pu.pu_desc
	,pu.pu_id
	,paths.Path_Id
	,paths.Path_code
	,ech.modified_on
	,dbtt.dbtt_desc
FROM dbo.event_configuration_history ech WITH(NOLOCK) 
JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = ech.pu_id
JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id = pu.pl_id
JOIN dbo.departments_base d WITH(NOLOCK) On d.dept_id = pl.dept_id
JOIN dbo.event_types et WITH(NOLOCK) ON et.et_id = ech.et_id
JOIN dbo.db_trans_types dbtt WITH(NOLOCK) ON dbtt.dbtt_id = ech.dbtt_id
JOIN dbo.prdexec_path_units punits WITH(NOLOCK) ON punits.pu_id = ech.pu_id
JOIN dbo.prdexec_paths paths WITH(NOLOCK) ON paths.path_id =  punits.path_id
WHERE et.et_desc = 'Downtime'
AND (ech.modified_on >= @Start AND ech.modified_on < @End)
--AND (dbtt.dbtt_desc in ('Insert','Delete'))
UPDATE d
	SET ScheduledUnitID		= punits.pu_id
FROM #DTEquipmentAndPaths d 
JOIN dbo.PrdExec_Path_Units punits WITH(NOLOCK) ON punits.Path_Id = d.PathID
WHERE punits.Is_Schedule_Point = 1

--get equipment that have downtime events that are not on paths
	INSERT INTO #DTEquipmentwithDowntimeNoPaths(
		 DeptID			
		,Department		
		,PLID			
		,[Line]			
		,[Unit]			
		,UnitID			
		,[Status]		
		)
	SELECT
		 d.dept_id
		,d.dept_desc
		,pl.pl_id
		,pl.pl_desc
		,pu.pu_desc
		,pu.pu_id
		,'Current'
	FROM dbo.event_configuration ec WITH(NOLOCK) 
	JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = ec.pu_id
	JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id = pu.pl_id
	JOIN dbo.departments_base d WITH(NOLOCK) On d.dept_id = pl.dept_id
	JOIN dbo.event_types et WITH(NOLOCK) ON et.et_id = ec.et_id
	WHERE et.et_desc = 'Downtime' AND ec.is_active = 1

	INSERT INTO #DTEquipmentwithDowntimeNoPaths(
		 DeptID			
		,Department		
		,PLID			
		,[Line]			
		,[Unit]			
		,UnitID			
		,ModifiedOn
		,[Status]		
		)

	SELECT
		 d.dept_id
		,d.dept_desc
		,pl.pl_id
		,pl.pl_desc
		,pu.pu_desc
		,pu.pu_id
		,ech.modified_on
		,dbtt.dbtt_desc
	FROM dbo.event_configuration_history ech WITH(NOLOCK) 
	JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = ech.pu_id
	JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id = pu.pl_id
	JOIN dbo.departments_base d WITH(NOLOCK) On d.dept_id = pl.dept_id
	JOIN dbo.event_types et WITH(NOLOCK) ON et.et_id = ech.et_id
	JOIN dbo.db_trans_types dbtt WITH(NOLOCK) ON dbtt.dbtt_id = ech.dbtt_id
	WHERE et.et_desc = 'Downtime'
	AND (ech.modified_on >= @Start AND ech.modified_on < @End)
	--AND (dbtt.dbtt_desc in ('Insert','Delete'))
	--remove all the equipment that is in #DTEquipmentAndPaths
	DELETE DTENoPaths
	FROM #DTEquipmentwithDowntimeNoPaths DTENoPaths
	JOIN  #DTEquipmentAndPaths DTEPaths WITH(NOLOCK) ON DTEPaths.UnitID = DTENoPaths.UnitID

--get the active orders started or ended in the period
SELECT @Tableid = tableid FROM dbo.tables WITH(NOLOCK) WHERE Tablename = 'production_plan'
IF @TableID IS NULL 
	BEGIN
		SELECT 'No tableid for the production_plan table please contact Fran Osorno.'
		GOTO CleanUp
	END

INSERT INTO #ProdPlan( 	
	 TableID		
	,TableKeyID		
	,PathCode		
	,PathID
	,Prodid
	,Prodcode
	,StartTime		
	,EndTime		
	,ProcessOrder	
	,EventStatus
	,UpdateType
	)
SELECT 
	 @TableID												--tableid
	,pp.pp_id												--tablekeyid
	,paths.path_code										--pathcode
	,pp.path_id												--pathid
	,p.prod_id												--prodid
	,p.prod_code											--prodcode
	,pp.actual_start_time									--starttime
	,CASE													--endtime
		WHEN pp.actual_end_time IS NULL THEN @End
		ELSE pp.actual_end_time
	 END
	,pp.process_order										--processorder
	,pps.pp_status_desc										--EventStatus
	,'Final'												--UpdateStatus
FROM dbo.production_plan pp WITH(NOLOCK)
JOIN dbo.prdexec_paths paths WITH(NOLOCK) ON paths.path_id = pp.path_id
JOIN dbo.production_plan_statuses pps WITH(NOLOCK) ON pps.pp_status_id = pp.pp_status_id
JOIN dbo.products_base p WITH(NOLOCK) ON p.prod_id = pp.prod_id
WHERE ((pp.actual_end_time >= @Start OR pp.actual_end_time IS NULL)
	AND pp.actual_start_time <= @End) AND pps.PP_Status_Desc <> 'Pending'

UPDATE pp
	SET 
		 Unit				= pu.pu_desc
		,UnitID				= pu.pu_id
		,ScheduledUnitID	= ppu.pu_id
FROM #ProdPlan pp
	JOIN dbo.prdexec_path_units ppu WITH(NOLOCK) ON ppu.Path_Id = pp.PathID
		JOIN dbo.Prod_Units_Base pu WITH(NOLOCK) ON pu.pu_id = ppu.pu_id
WHERE ppu.Is_Schedule_Point = 1

--get production_starts records for the equipment not on paths for the period
SELECT @Tableid = tableid FROM dbo.tables WITH(NOLOCK) WHERE Tablename = 'production_starts'
IF @TableID IS NULL 
	BEGIN
		SELECT 'No tableid for the production_starts table please contact Fran Osorno.'
		GOTO CleanUp
	END

INSERT INTO #ProdPlan( 	
	 TableID		
	,TableKeyID		
	,Unit			
	,UnitID			
	,StartTime		
	,EndTime		
	,ProdID			
	,ProdCode		
	,UpdateType
	)

SELECT
	 @TableID										--tableid
	,ps.start_id									--talbkeyid
	,DTENoPaths.unit								--unit
	,DTENoPaths.UnitID								--unitid
	,ps.start_time									--starttime
	,CASE											--endtime
		WHEN ps.end_time IS NULL THEN @End
		ELSE ps.end_time
	END
	,p.prod_id										--prodid
	,p.prod_code									--prodcode	
	,'Final'										--UpdateType
FROM dbo.production_starts ps WITH(NOLOCK)
JOIN #DTEquipmentwithDowntimeNoPaths DTENoPaths WITH(NOLOCK) ON DTENoPaths.UnitID = ps.pu_id
JOIN dbo.products_base p WITH(NOLOCK) ON p.prod_id = ps.prod_id
WHERE ((ps.end_time >= @Start OR ps.end_time IS NULL) AND ps.start_time <=@End) AND ps.prod_id <> 1

--get line_statuses
INSERT INTO #TimePlan (
	 RecordType		
	,TableKeyID		
	,DeptID			
	,Department		
	,PLID			
	,Line			
	,UnitID			
	,Unit			
	,StartTime		
	,EndTime		
	,EventStatus	
	,UpdateType	
	)
SELECT 
	 'Line status'							--recodrtype 
	,ls.status_schedule_id					--tablekyeid
	,d.dept_id								--deptid
	,d.dept_desc							--department
	,pl.pl_id								--plid
	,pl.pl_desc								--line
	,pu.pu_id								--unitid
	,pu.pu_desc								--unit
	,ls.start_datetime						--startime
	,CASE									--endtime
		WHEN ls.end_datetime IS NULL THEN @End
		ELSE ls.end_datetime
	 END
	,p.phrase_value							--eventstatus
	,'Final'								--UpdateType
FROM dbo.Local_PG_Line_Status ls WITH(NOLOCK)
JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = ls.unit_ID
JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id =pu.pl_id
JOIN dbo.departments_base d WITH(NOLOCK) ON d.dept_id = pl.dept_id
JOIN dbo.phrase p WITH(NOLOCK) ON p.phrase_id = ls.line_status_id
WHERE ((ls.end_datetime >= @Start OR ls.end_datetime is NULL) AND ls.start_datetime <= @End)


INSERT INTO #TimePlan (
	 RecordType		
	,TableKeyID		
	,DeptID			
	,Department		
	,PLID			
	,Line			
	,UnitID			
	,Unit			
	,StartTime		
	,EndTime		
	,EventStatus	
	,UpdateType	
	,ModifiedOn		
	,Username
	)
SELECT
	 'line status history'							--recordtype
	,ls.status_schedule_id							--tablekeyid
	,d.dept_id										--deptid
	,d.dept_desc									--department
	,pl.pl_id										--plid
	,pl.pl_desc										--line
	,pu.pu_id										--unitid
	,pu.pu_desc										--unit
	,ls.start_datetime								--starttime
	,CASE											--endtime
		WHEN ls.end_datetime IS NULL THEN @End
		ELSE ls.end_datetime
	 END											
	,p.phrase_value									--EventStatus
	,ls.update_status								--UpdateType
	,ls.Modified_DateTime							--modifiedon
	,u.username										--username
FROM dbo.Local_PG_Line_Status_history ls WITH(NOLOCK)
JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = ls.unit_ID
JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id =pu.pl_id
JOIN dbo.departments_base d WITH(NOLOCK) ON d.dept_id = pl.dept_id
JOIN dbo.phrase p WITH(NOLOCK) ON p.phrase_id = ls.line_status_id
JOIN dbo.users_base u WITH(NOLOCK) ON u.user_id = ls.user_id
WHERE (ls.modified_datetime >= @Start  AND ls.modified_datetime <= @End)
/*
--testing
SELECT
	 'line status history'							--recordtype
	,ls.status_schedule_id							--tablekeyid
	,d.dept_id										--deptid
	,d.dept_desc									--department
	,pl.pl_id										--plid
	,pl.pl_desc										--line
	,pu.pu_id										--unitid
	,pu.pu_desc										--unit
	,ls.start_datetime								--starttime
	,CASE											--endtime
		WHEN ls.end_datetime IS NULL THEN @End
		ELSE ls.end_datetime
	 END											
	,p.phrase_value									--EventStatus
	,ls.update_status								--UpdateType
	,ls.Modified_DateTime							--modifiedon
	,u.username										--username
FROM dbo.Local_PG_Line_Status_history ls WITH(NOLOCK)
JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = ls.unit_ID
JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id =pu.pl_id
JOIN dbo.departments_base d WITH(NOLOCK) ON d.dept_id = pl.dept_id
JOIN dbo.phrase p WITH(NOLOCK) ON p.phrase_id = ls.line_status_id
JOIN dbo.users_base u WITH(NOLOCK) ON u.user_id = ls.user_id
WHERE (ls.modified_datetime >= @Start  AND ls.modified_datetime <= @End)
*/

--get npt
INSERT INTO #TimePlan (
	 RecordType		
	,TableKeyID		
	,DeptID			
	,Department		
	,PLID			
	,Line			
	,UnitID			
	,Unit			
	,StartTime		
	,EndTime		
	,EventStatus	
	,UpdateType	
	)
SELECT 
	 'NPT Records'							--recordtype
	,npt.npdet_id							--tablekeyid
	,d.dept_id								--deptid
	,d.dept_desc							--department
	,pl.pl_id								--plid
	,pl.pl_desc								--line
	,pu.pu_id								--Unitid
	,pu.pu_desc								--unit
	,npt.start_time							--starttime
	,npt.end_time							--endtime
	,er.event_reason_name					--eventstatus
	,'Final'								--updatetype
FROM dbo.nonproductive_detail npt WITH(NOLOCK)
JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = npt.pu_id
JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id =pu.pl_id
JOIN dbo.departments_base d WITH(NOLOCK) ON d.dept_id = pl.dept_id
join dbo.event_reasons er WITH(NOLOCK) ON er.event_reason_id = npt.reason_level1
WHERE (npt.end_time >= @Start  AND npt.start_time <= @End)

INSERT INTO #TimePlan (
	 RecordType		
	,TableKeyID		
	,DeptID			
	,Department		
	,PLID			
	,Line			
	,UnitID			
	,Unit			
	,StartTime		
	,EndTime		
	,EventStatus	
	,ModifiedOn		
	,UpdateType	
	,Username
	)
SELECT 
	 'NPT History'					--recordtype
	,npt.npdet_id					--tablekeyid
	,d.dept_id						--deptid
	,d.dept_desc					--department
	,pl.pl_id						--plid
	,pl.pl_desc						--line
	,pu.pu_id						--unitid
	,pu.pu_desc						--unit
	,npt.start_time					--starttime
	,npt.end_time					--endtime
	,er.event_reason_name			--eventstatus
	,npt.modified_on				--modifiedon
	,dbtt.dbtt_desc					--updatetype
	,u.username						--username
FROM dbo.nonproductive_detail_history npt WITH(NOLOCK)
JOIN dbo.prod_units_base pu WITH(NOLOCK) ON pu.pu_id = npt.pu_id
JOIN dbo.prod_lines_base pl WITH(NOLOCK) ON pl.pl_id =pu.pl_id
JOIN dbo.departments_base d WITH(NOLOCK) ON d.dept_id = pl.dept_id
JOIN dbo.event_reasons er WITH(NOLOCK) ON er.event_reason_id = npt.reason_level1
JOIN dbo.db_trans_types dbtt WITH(NOLOCK) ON dbtt.dbtt_id = npt.dbtt_id
JOIN dbo.users_base u WITH(NOLOCK) ON u.user_id = npt.user_id
WHERE npt.modified_on >= @Start AND npt.modified_on <= @End


--Cleanup the #TimePlan Table
--get all the #prodPlan units
INSERT INTO #ProdPlanUnits(UnitID)
SELECT UnitID FROM #ProdPlan WITH(NOLOCK)
GROUP BY UnitID
--get all the #TimePlan units
INSERT INTO #TimePlanUnits(TPUnitID)
SELECT UnitID FROM #TimePlan WITH(NOLOCK)
GROUP BY UnitID
--update #TimePlanUnits for ProdPlanUnits
UPDATE tpu
	SET PPUnitID = UnitID
FROM #TimePlanUnits tpu
JOIN #ProdPlanUnits ppu WITH(NOLOCK) ON ppu.UnitID = tpu.TPUnitID


--remove all #timePlan records with no #ProdPlan record
/*
DELETE tp
FROM #TimePlan tp
JOIN #TimePlanUnits tpu WITH(NOLOCK) ON tpu.TPUnitID = tp.UnitID
WHERE tpu.PPUnitID IS NULL
*/
--update #TimePlan with ProdPlanID
UPDATE tp
	SET ProdPlanID = pp.id
FROM #TimePlan tp
JOIN #ProdPlan pp WITH(NOLOCK) ON pp.UnitID = tp.UnitID
WHERE tp.EndTime >= pp.StartTime AND tp.StartTime <= pp.EndTime
/*
--this is testing
--need to review this and get a usable query
select tp.id,tp.starttime,tp.endtime,pp.id,pp.starttime,pp.endtime
FROM #TimePlan tp
JOIN #ProdPlan pp WITH(NOLOCK) ON pp.UnitID = tp.UnitID
WHERE tp.EndTime >= pp.StartTime AND tp.StartTime <= pp.EndTime
order by tp.id
*/
--build the final data set with status
INSERT INTO #FinalData(
	 RecordType						
	,[Planned Record Type]			
	,[Planned Record TableID]		
	,[Department]					
	,[Line]							
	,[Planned Record]				
	,[Planned Record Start]			
	,[Planned Record End]			
	,[Planned Record Status]		
	,[Planned Record Modified On]	
	,[Planned Record Update Type]	
	,[Planned Record User Changed]	
	,[Production Record Table]		
	,[Production Record Path Code]	
	,[Production Record Path ID]	
	,[Production Record Unit]		
	,[Production Record Start]		
	,[Production Record End]		
	,[Production Record PO]			
	,[Production Record Prod Code]	
	)
SELECT
	 'Final Data'
	,tp.RecordType
	,tp.TableKeyID
	,tp.Department		
	,tp.Line			
	,tp.Unit			
	,tp.StartTime		
	,tp.EndTime		
	,tp.EventStatus	
	,tp.ModifiedOn		
	,tp.UpdateType	
	,tp.username
	,t.TableName		
	,pp.PathCode		
	,pp.PathID			
	,pp.Unit			
	,pp.StartTime		
	,pp.EndTime		
	,pp.ProcessOrder	
	,pp.ProdCode		
FROM #TimePlan tp WITH(NOLOCK) 
LEFT JOIN #ProdPlan pp WITH(NOLOCK) ON pp.UnitID = tp.UnitID
LEFT JOIN dbo.tables t WITH(NOLOCK) ON t.tableid = pp.TableID
WHERE (tp.EndTime >= pp.StartTime AND tp.StartTime <= pp.EndTime)
order by tp.id
--update #FinalData.[Planned Start Status]
UPDATE #FinalData
	SET [Planned Start Status] =
		CASE
			WHEN [Planned Record Start] <= [Production Record Start] THEN 'Good'
			ELSE 'Bad'
		END
--update #FinalData.[Planned End Status]
UPDATE #FinalData
	SET [Planned End Status] =
		CASE
			WHEN [Planned Record End] >= [Production Record End]  THEN 'Good'
			ELSE 'Bad'
		END
UPDATE #FinalData
	SET [Planned End Status] =
		CASE
			WHEN [Planned Start Status] = 'Bad' THEN 'Bad Planned Start'
			ELSE [Planned End Status] 
		END

--update #FinalData.[Overall Status]
UPDATE #FinalData
	SET [Overall Status] =
		CASE
			WHEN [Planned Start Status] = 'Good' AND [Planned End Status] = 'Good' THEN 'Pass'
			ELSE 'Fail'
		END


UPDATE FD
	SET FD.[Bad Record]=
		CASE
			WHEN [Overall Status] = 'Fail' THEN 1
			ELSE 0
		END
	,FD.[Bad End]=
		CASE
			WHEN [Planned END Status] = 'BAD'	THEN	1
			ELSE 0
		END
	,FD.[Bad Start] =
		CASE
			WHEN [Planned Start Status] = 'BAD'	THEN	1
			ELSE 0
		END
FROM #FinalData FD



INSERT INTO #Aggregates 
		(
			[Production Line]
			,[Overall Record Count]			
			,[Number Of Overall Failed Records]	
			,[Number of Bad End Records]	
			,[Number Of Bad Start Records]	
			)
SELECT 	FD.Line
				,Count(FD.Line) 	
				,SUM(FD.[Bad Record])
				,SUM(FD.[Bad End])
				,SUM(FD.[Bad Start])
FROM #FinalData	FD Group By LINE

UPDATE	#Aggregates
	SET [Overall Percent Failure] = Round((Convert(Float,[Number Of Overall Failed Records],0)/Convert(Float,[Overall Record Count],0))*100,2)


	
ReturnData:
/*
--this is testing
SELECT 'Equipment and Paths',* FROM #DTEquipmentAndPaths WITH(NOLOCK)
SELECT 'equipment with no Paths',* FROM #DTEquipmentwithDowntimeNoPaths WITH(NOLOCK)
SELECT 'ProdPlan', * FROM #ProdPlan WITH(NOLOCK)
SELECT 'TimePlan', * FROM #TimePlan WITH(NOLOCK) 
SELECT 'NoPlan',* FROM #TimePlanUnits WITH(NOLOCK) WHERE PPUnitID IS NULL

SELECT 'TimePlan', * FROM #TimePlan WITH(NOLOCK)   where RecordType = 'line status history' AND unitid in (55,54)
SELECT 'TimePlan', * FROM #TimePlan WITH(NOLOCK)   where  unitid in (55,54)
SELECT 'ProdPlan', * FROM #ProdPlan WITH(NOLOCK) WHERE Unitid in (55,54)

SELECT 'NoPlan',* FROM #TimePlanUnits WITH(NOLOCK) WHERE  TPUnitID in (54,55
)
*/


--Result Set 1 : Aggregates
Select * from #Aggregates

--Result Set 2 : Raw Data
IF @FetchRawData = 1
BEGIN
	SELECT
		 RecordType						
		,[Planned Record Type]			
		,[Planned Record TableID]		
		,[Department]					
		,[Line]							
		,[Planned Record]				
		,[Planned Record Start]			
		,[Planned Record End]			
		,[Planned Record Status]		
		,[Planned Record Modified On]	
		,[Planned Record Update Type]	
		,[Planned Record User Changed]	
		,[Production Record Table]		
		,[Production Record Path Code]	
		,[Production Record Path ID]	
		,[Production Record Unit]		
		,[Production Record Start]		
		,[Production Record End]		
		,[Production Record PO]			
		,[Production Record Prod Code]	
		,[Planned Start Status]			
		,[Planned End Status]			
		,[Overall Status]	
	FROM #FinalData WITH(NOLOCK) 
END


CleanUp:
DROP TABLE #DTEquipmentAndPaths
DROP TABLE #DTEquipmentwithDowntimeNoPaths
DROP TABLE #ProdPlan
DROP TABLE #TimePlan
DROP TABLE #ProdPlanUnits
DROP TABLE #TimePlanUnits
DROP TABLE #FinalData
DROP TABLE #Aggregates


END