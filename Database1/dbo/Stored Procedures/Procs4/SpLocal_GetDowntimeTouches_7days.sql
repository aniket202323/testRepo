


/*
--------------------------------------------------------------
Name: SpLocal_GetDowntimeTouches_7days
Purpose: Get Aggregated Data for Downtime touches by Production Line
--------------------------------------------------------------

Created BY : Akshay Kasurde
Date 25-Mar-2020

Change Log
--------------------------------------------------------------
Date: 25-Mar-2020		Initial Version
--------------------------------------------------------------
*/



CREATE PROCEDURE [SpLocal_GetDowntimeTouches_7days]
	 @Start			DATETIME
	,@End			DATETIME
	,@FetchRawData	BIT

AS

BEGIN
-- Uncomment For Debuggin Purpose only
--SELECT
--	 @Start		= '1/1/2020'
--	,@End		= '3/1/2020'
--  ,@FetchRawData = 0



CREATE TABLE #DowntimeChanges	
	(
		ID		INT IDENTITY
		,RecordType		VARCHAR(20)
		,DeptID			INT
		,[Department]		VARCHAR(50)
		,LineID			INT
		,[Line]			VARCHAR(50)
		,UnitID			INT
		,[Unit]			VARCHAR(50)
		,TEDETID		INT
		,StartTime		DATETIME
		,ENDTime		DATETIME
		,Duration		DECIMAL
		,Uptime			DECIMAL
		,MODIFIEDON		DATETIME
		,USERID			INT
		,UpdateType		VARCHAR(10)
		,EventReasonTreeDataID	INT
		,InitialUserID	INT
		,DeleteOutside7Day	INT
		,EditOutside7Day	INT
	)


CREATE TABLE #Aggregates
	(
		ID INT IDENTITY
		,[Production Line]  VARCHAR(50)
		,[Edits Outside 7 Days] INT
		,[Deletes Outside 7 Days] INT
	)


		INSERT INTO #DowntimeChanges
		(	
			RecordType		
			,UnitID
			,TEDETID				
			,StartTime		
			,ENDTime		
			,Duration		
			,Uptime			
			,MODIFIEDON		
			,USERID			
			,UpdateType		
			,EventReasonTreeDataID	
			,InitialUserID	)
		SELECT 
			'HISTORY'
			,TEDH.pu_id
			,TEDET_ID
			,TEDH.Start_Time
			,TEDH.END_Time
			,TEDH.Duration
			,TEDH.Uptime
			,TEDH.Modified_On
			,TEDH.User_Id
			,CASE	When TEDH.DBTT_ID= 2 THEN 'INSERT'
					WHEN TEDH.DBTT_ID = 3 THEN 'UPDATE'
					WHEN TEDH.DBTT_ID = 4 THEN  'DELETE'
			END
			,TEDH.Event_Reason_Tree_Data_Id
			,TEDH.Initial_User_Id
			FROM dbo.Timed_Event_Detail_History TEDH
			WHERE (TEDH.Start_Time >= @Start and TEDH.Start_Time <= @End)
			OR (TEDH.Modified_On >= @Start AND TEDH.Modified_On <= @End)

			UPDATE DC
			SET DeptID = D.dept_id
				,[Department] = D.dept_desc
				,LineID = PL.pl_id
				,[Line] = PL.pl_desc
				,UnitID = PU.pu_id
				,[Unit] = PU.pu_desc
			FROM #DowntimeChanges DC
			JOIN dbo.Prod_Units_Base PU on DC.UnitID = PU.pu_id
			JOIN dbo.Prod_lines_Base PL on PU.pl_id = PL.pl_id
			JOIN dbo.Departments_Base D on PL.dept_id= D.dept_id



			UPDATE DC1
			SET		RecordType = 'FINAL'
			FROM	#DowntimeChanges DC1
			JOIN ( Select MAX(ModifiedON) as MM , TEDETID FROM #DowntimeChanges  Group By TEDETID) DC2
					ON DC1.TEDETID = DC2.TEDETID
			WHERE DC1.MODIFIEDON = DC2.MM
	
	
			Update DC
			SET		DeleteOutside7Day =  CASE 
											WHEN DATEDIFF(MI,StartTime, ModifiedOn) > 10080 THEN 1
											ELSE 0
										END
			FROM	#DowntimeChanges DC
			Where	DC.UpdateType  = 'DELETE' 
					AND RecordType = 'FINAL'
		
			Update	DC
			SET		EditOutside7Day =  CASE 
											WHEN DATEDIFF(MI,StartTime, ModifiedOn) > 10080 THEN 1
											ELSE 0
										END
			FROM	#DowntimeChanges DC
			Where	RecordType= 'FINAL' 
					AND	(DC.UpdateType  = 'UPDATE' or DC.UpdateType = 'INSERT')


			Delete FROM #DowntimeChanges where RecordType = 'HISTORY'

	
			INSERT INTO #Aggregates
				(	[Production Line],[Edits Outside 7 Days], [Deletes Outside 7 Days])
			Select	LINE 
					,Coalesce(Sum(EditOutside7Day),0)
					,Coalesce( Sum(DeleteOutside7Day),0)
			From	#DowntimeChanges Group By Line


			--OUTPUTS Below this line

			-- Result Set 1: Aggredated Output
			SELECT	[Production Line]
					,[Edits Outside 7 Days]
					,[Deletes Outside 7 Days]
			FROM	#Aggregates

			IF @FetchRawData =1
			BEGIN
			-- Result Set 2:Records for Delete Outside 7 days
				SELECT Department
						,Line
						,Unit
						,TEDETID
						,StartTime
						,ENDTime
						,MODIFIEDON
						,UpdateType		
				FROM	#DowntimeChanges 
				WHERE	DeleteOutside7Day = 1

				-- Result Set 3: Records for Edit Outside 7 days
				SELECT	 Department
						,Line
						,Unit
						,TEDETID
						,StartTime
						,ENDTime
						,MODIFIEDON
						,UpdateType
				FROM	#DowntimeChanges 
				WHERE	EditOutside7Day = 1
			END

	CLEANUP:
		DROP TABLE #DowntimeChanges
		DROP TABLE #Aggregates
END

