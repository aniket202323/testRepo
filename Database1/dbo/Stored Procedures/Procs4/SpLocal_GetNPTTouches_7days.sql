


/*
--------------------------------------------------------------
Name: [SpLocal_GetNPTTouches_7days]
Purpose: Get Aggregated Data for NPT touches by Production Line as well as Raw data based on the input to the SP
--------------------------------------------------------------

Created BY : Akshay Kasurde
Date 26-Mar-2020

Change Log
--------------------------------------------------------------
Date: 26-Mar-2020		Initial Version
--------------------------------------------------------------
*/



CREATE PROCEDURE [SpLocal_GetNPTTouches_7days]
	 @Start		DATETIME
	,@End		DATETIME
	,@FetchRawData	BIT

AS

BEGIN
-- Uncomment For Debuggin Purpose only
--SELECT
--	 @Start		= '1/1/2020'
--	,@End		= '3/1/2020'
--  ,@FetchRawData = 0


--Declare
CREATE TABLE #FinalData (
	 ID								INT IDENTITY
	,RecordType						VARCHAR(50)									--'Final Data'
	,[Department]					VARCHAR(50)									--tp.Department		
	,[Line]							VARCHAR(50)									--tp.Line			
	,[Unit]							VARCHAR(50)									--tp.Unit			
	,[Status Start Time]			DATETIME									--npt.starttime
	,[Status End Time]				DATETIME									--npt.EndTime
	,[Modified Time]				DATETIME
	,[Update Type]					VARCHAR(50)
	,[Delay In Update(Days)]		INT											--
	,[Overall Status]				VARCHAR(20)									--Pass/Fail
	)


CREATE TABLE #TimePlan (
	 ID				INT IDENTITY		--the idneity of the table
	,RecordType		VARCHAR(50)			--the type of record
	,TableKeyID		INT					--the key of the table in the RecordType
	,NPDETID		INT					
	,DeptID			INT					--department_base.dept_id
	,Department		VARCHAR(50)			--department_base.dept_desc
	,PLID			INT					--prod_lines_base.pl_id
	,Line			VARCHAR(50)			--prod_lines_base.pl_desc
	,UnitID			INT					--prod_units_base.pu_id
	,Unit			VARCHAR(50)			--prod_units_base.pu_desc
	,StartTime		DATETIME			--the event start
	,EndTime		DATETIME			--the event end
	,EntryOn		DATETIME
	,EventStatus	VARCHAR(50)			--the status of the event
	,ModifiedOn		DATETIME			--the time the record was modified
	,Username		VARCHAR(50)			--users_base.username of the user making the record change
	,UpdateType		VARCHAR(50)			--the type of operation
	,UpdateDelay	INT
	,Failed			INT
	)


INSERT INTO #TimePlan (
	 RecordType		
	,TableKeyID	
	,NPDETID
	,DeptID			
	,Department		
	,PLID			
	,Line			
	,UnitID			
	,Unit			
	,StartTime		
	,EndTime
	,EntryOn
	,EventStatus	
	,ModifiedOn		
	,UpdateType	
	,Username
	)
SELECT 
	 'NPT History'					--recordtype
	,npt.NonProductive_Detail_History_Id	--tablekeyid
	,npt.npdet_id					  
	,d.dept_id						--deptid
	,d.dept_desc					--department
	,pl.pl_id						--plid
	,pl.pl_desc						--line
	,pu.pu_id						--unitid
	,pu.pu_desc						--unit
	,npt.start_time					--starttime
	,npt.end_time					--endtime
	,npt.Entry_on					--EntryOn
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
WHERE (npt.end_time >= @Start  AND npt.End_Time <= @End)
OR	(npt.Start_Time >= @Start	AND npt.Start_Time <= @End)
OR (npt.modified_on >= @Start AND npt.modified_on <= @End)



	UPDATE TP1
		SET		RecordType = 'FINAL'
		FROM	#TimePlan TP1		
				JOIN ( Select MAX(ModifiedON) as MM , NPDETID FROM #TimePlan  Group By NPDETID) TP2
				ON TP1.NPDETID = TP2.NPDETID
		WHERE TP1.MODIFIEDON = TP2.MM

		
	UPDATE TP
	SET TP.UpdateDelay = DATEDIFF(MI,starttime, ModifiedOn)
	FROM #TimePlan	TP
	WHERE  RecordType = 'Final' --AND EntryOn > StartTime

	UPDATE TP
	SET Failed = 1 
	FROM #TimePlan TP
	Where TP.UpdateDelay >=10080


	INSERT INTO #FinalData(
		RecordType						--'Final Data'
		,[Department]						--tp.Department		
		,[Line]								--tp.Line			
		,[Unit]								--tp.Unit			
		,[Status Start Time]				--npt.starttime
		,[Status End Time]					--npt.EndTime
		,[Modified Time]
		,[Update Type]
		,[Delay In Update(Days)]			--
		,[Overall Status]
		)
	SELECT TP.RecordType
			,TP.Department
			,TP.Line
			,TP.Unit
			,TP.StartTime
			,TP.EndTime
			,TP.ModifiedOn
			,TP.UpdateType
			,Convert(INT,TP.UpdateDelay/1440)
			,CASE	
				WHEN TP.UpdateDelay <= 0	THEN 'Good'
				WHEN (TP.UpdateDelay > 0 AND TP.UpdateDelay < 10080)	THEN	'Within 7 Days'
				ELSE	'Update > 7 days'
			END
	FROM #TimePlan TP
	WHERE TP.RecordType = 'Final'


	--Result Set 1: Aggregates
	SELECT	Line AS 'Production Line'
			,COALESCE(SUM(Failed),0) AS 'Updates After 7 Days'
	FROM	#TimePlan	Group By Line

	--Result Set 2: Raw Data
	IF @FetchRawData = 1
		Select * from #FinalData

	CLEANUP: 
		DROP TABLE #Timeplan
		DROP TABLE #FinalData

END