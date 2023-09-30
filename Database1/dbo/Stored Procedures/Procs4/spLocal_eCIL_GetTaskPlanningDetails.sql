CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTaskPlanningDetails]
/*  
-------------------------------------------------------------------------------------------------  
Stored Procedure    :  spLocal_eCIL_GetTaskPlanningDetails 
Author			    :  Madan G.Deshpande , Tata Consulatancy Services Limited 
Date Created        :  17th March 2011  
SP Type             :                                      
Editor Tab Spacing  :  3  
Description         :  To get the task information
  
=========  
CALLED BY:   eCIL Web Application
            
Revision	Date			Who                 What  
========	=====			====                =====  
1.0.0		2011-March-17   Madan Deshpande		Creation of the Store Procedure  
1.0.1		03-Aug-2015		Santosh Shanbhag	Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2		09-Apr-2019		Facundo Sosa		Added Default for @HSEOnly to be able to filter only HSE tasks in the function fnLocal_eCIL_GetSubTasksList   
1.0.3		21-Oct-2020		Megha Lohana		eCIL 4.1 SP Standardized , Added no locks and base tables
1.0.4		24-Jan-2023		Megha Lohana		Updated to grant permissions to role instead of local user
1.0.5 		03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.6		03-Aug-2023		Payal Gadhvi		Updated SP with version management and to meet coding standard
TEST CODE :  
EXEC spLocal_eCIL_GetTaskPlanningDetails @Granularity = 3,  
            @TopLevelID = 0,  
            @SubLevel = 0,  
            @StartTime = '04-1-2011  00:00:00:000',  
            @EndTime = '04-30-2011  23:59:59:000',  
            @UserId = 59,  
            @RouteIds = NULL,  
            @TeamIDs = NULL,  
            @TeamDetail = 1,  
            @VarID=7  
-------------------------------------------------------------------------------------------------  
*/
@VarId			INT,  
@Granularity	INT,					/*-- 1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks*/  
@TopLevelID		INT,					/*-- The Id of the level we want to display Compliance  */
@SubLevel		INT,					/*-- Indicates that we want the level under @TopLevelId  */
@StartTime		DATETIME,				/*-- Start Time of the report  */
@EndTime		DATETIME,				/*-- End Time of the report  */
@UserId			INT,					/*-- User asking for the report */ 
@RouteIds		VARCHAR(8000) = NULL,	/*-- List of Route_Id(s)  */
@TeamIDs		VARCHAR(8000) = NULL,	/*-- List of Team_Id(s) */ 
@TeamDetail		INT = NULL     

AS  
SET NOCOUNT ON ; 
  
DECLARE @TaskFreq VARCHAR(10)  ,
 @CurrentEntryOn DATETIME ; 
  
DECLARE @Variables TABLE  
(  
	Var_Id				INT,  
	Var_Desc			VARCHAR(50),  
	PU_Id				INT,  
	TopLevelId			INT,  
	TopLevelDesc		VARCHAR(50),  
	CurrentVSId			INT,				/*-- VS_Id of the Active_Spec that was effective or next effective for the current task  */
	CurrentTestFreq		VARCHAR(7),			/*-- Test Frequency (1=Active, 234=Frequency of Task, 567=Test Window)  */
	CurrentEntryOn		DATETIME,  
	CurrentDueTime		DATETIME,			/*-- The time the task is due in the current period  */
	CurrentResult		VARCHAR(25),		/*-- The last result entered for the task in the current period  */
	StartDate			DATETIME,  
	TaskFreq			VARCHAR(10)         /*-- Task Frequency (Daily, Shiftly, MultiDay)  */
)  ;
  
DECLARE @Units TABLE   
(  
	SlavePUId				INT,			/*-- PU_Id associated to the variables retrieved  */
	SlaveUnitDesc			VARCHAR(50),  
	MasterPUId				INT,			/*-- Master unit of the SlavePUId, if necessary  */
	MasterUnitDesc			VARCHAR(50),  
	STLSShiftTeamId			INT,			/*-- Unit where STLS Shift-Team information is configured for this unit */ 
	CurrentProdId			INT,			/*-- Current product id loaded on the unit  */
	CurrentProdStartTime	DATETIME,		/*-- Timestamp when the product was loaded  */
	STLSId					INT            /* --To store STLS Id       */                                               
)  ;

/*--Insert the data of variables in @Variables */
INSERT @Variables (Var_Id, Var_Desc, PU_Id, TopLevelId, TopLevelDesc)  
 SELECT Var_Id, Var_Desc, PU_Id, TopLevelId, TopLevelDesc  
 FROM  dbo.fnLocal_eCIL_GetSubTasksList(@Granularity, @TopLevelID, @SubLevel, @UserId, @RouteIds, @TeamIDs, @TeamDetail, DEFAULT, DEFAULT)  ;
  
/*-- Insert all the PUIds in the variable table  */
INSERT INTO @Units(SlavePUId, SlaveUnitDesc, MasterPUId)  
 SELECT DISTINCT v.Pu_Id,pu.PU_Desc,pu.Master_Unit  
 FROM     @Variables v  
 JOIN     dbo.Prod_Units_Base pu WITH (NOLOCK) ON v.PU_Id = pu.PU_Id ; 
  
/*-- If a unit is a slave unit, retrieve the master unit  
-- If not, copy the PU_Id itself in the masterPUId  */
UPDATE u  
SET  MasterUnitDesc = pu.PU_Desc  
FROM  @Units u  
JOIN  dbo.Prod_Units_Base pu WITH(NOLOCK) ON (pu.PU_Id = u.MasterPUId) ; 
UPDATE u  
SET  MasterUnitDesc = pu.PU_Desc  
FROM  @Units u  
JOIN  dbo.Prod_Units_Base pu WITH(NOLOCK) ON (pu.PU_Id = u.MasterPUId) ;  
    
/*-- Get the Test Frequency if it is stored in a UDP  
-- Verify if there are some tasks having Test Frequency information stored in UDP instead of specs  */
UPDATE @Variables  
SET  CurrentTestFreq = dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_TaskFrequency', 'Variables')  ;
    
/*-- Retrieve current product for each unit having tasks with Test Frequency not set in the UDP (Using Specs)  
-- Those product are taken at report start time and will be assumed unchanged until report end time. */ 
UPDATE u  
SET  u.CurrentProdId = ps.Prod_Id,  
   u.CurrentProdStartTime = ps.Start_Time  
FROM  @Units u  
JOIN  @Variables v ON v.PU_Id = u.SlavePUId  
JOIN  dbo.Production_Starts ps WITH(NOLOCK) ON (ps.Pu_Id = u.MasterPUId)  
WHERE  ps.Start_Time <= @StartTime  
AND  (  
    (ps.End_Time >= @StartTime)  
    OR  
    (ps.End_Time IS NULL)  
   )  
AND  v.CurrentTestFreq IS NULL ;  
  
/*-- Get the VS_Id that is effective at the time of the report start  
-- If there is no spec available at that time, we retrieve the first one available after that time  
-- Only for tasks not having a UDP for their test frequency (CurrentTestFreq NULL)  */
UPDATE v  
SET  CurrentVSId =  
    (  
    SELECT TOP 1 VS_Id  
    FROM  dbo.Var_Specs vs WITH (NOLOCK)  
    WHERE  Var_Id = v.Var_Id  
    AND  Prod_Id = u.CurrentProdId  
    AND  (  
        (Expiration_Date IS NULL)  
        OR  
        (Expiration_Date > @StartTime)  
       )  
    ORDER BY Effective_Date ASC  
    )  
FROM  @Variables v  
JOIN  @Units u ON u.SlavePUId = v.Pu_Id  
WHERE  v.CurrentTestFreq IS NULL  ;
  
/*-- Once we have the VS_Id, retrieve the test frequency  
-- Only for tasks not having a UDP for their test frequency (CurrentTestFreq NULL)  */
UPDATE v  
SET  CurrentTestFreq = vs.Test_Freq  
FROM  @Variables v  
JOIN  dbo.Var_Specs vs WITH(NOLOCK) ON vs.VS_Id = v.CurrentVSId  
WHERE  CurrentTestFreq IS NULL;  
  
/*-- Remove disabled tasks  */
DELETE FROM @Variables   
WHERE   LEN(CurrentTestFreq) <> 7  
OR    CurrentTestFreq IS NULL;  
  
/*-- Get the last Result_On for variables  */
UPDATE v  
SET  CurrentDueTime =  
    (  
    SELECT MAX(Result_On)  
    FROM  dbo.Tests WITH(NOLOCK)  
    WHERE  Var_Id = v.Var_Id  
    AND  Result_On IS NOT NULL  
    )        
FROM  @Variables v ; 
  
/*-- Get the last Entry_On and Result for the variables  
-- We have to get the last result for the remaining tasks (Should be Missed, Defect, OK)  */
UPDATE v  
SET  CurrentEntryOn = CONVERT(VARCHAR(19), t.Entry_On, 120),  
   CurrentResult = t.Result  
FROM  @Variables v  
JOIN  dbo.Tests t WITH(NOLOCK) ON  (t.Var_Id = v.Var_Id) AND (t.Result_On = v.CurrentDueTime) ; 
  
/*-- For tasks that have never been scheduled, we immediately set the NextDueTime to StartTime, if set in UDP  */
UPDATE @Variables  
SET  StartDate = CONVERT(DATETIME, dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_StartDate', 'Variables') + ' 00:00:00.000')  
WHERE  CurrentDueTime IS NULL ; 
  
/*-- Get the TaskFreq Properties for each variable  */
UPDATE @Variables  
SET  TaskFreq = dbo.fnLocal_eCIL_GetTaskFreqCode (CurrentTestFreq) ;
  
SET @TaskFreq =(SELECT TaskFreq FROM @Variables WHERE Var_ID=@VarID);  
SET @CurrentEntryOn = (SELECT CurrentEntryOn FROM @Variables WHERE Var_ID=@VarID);  
  
/*-- Returning the information to display  */
SELECT      VarID		= @VarID,  
			TaskName	= Var_Desc,  
			LongTaskName= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_LongTaskName', 'Variables'),  
			TaskAction  = dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_TaskAction', 'Variables'),  
			FL1			= dbo.fnLocal_eCIL_GetFL1(Var_Id),  
			FL2			= dbo.fnLocal_eCIL_GetFL2(Var_Id),  
			FL3			= dbo.fnLocal_eCIL_GetFL3(Var_Id),  
			FL4			= dbo.fnLocal_eCIL_GetFL4(Var_Id),  
			TaskId		= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_TaskId', 'Variables'),  
			TaskFreq    = @TaskFreq,   
			TaskType	= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_TaskType', 'Variables'),  
			EntryOn     = @CurrentEntryOn,   
			Criteria	= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_Criteria', 'Variables'),  
			Hazards		= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_Hazards', 'Variables'),  
			Method		= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_Method', 'Variables'),  
			PPE			= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_PPE', 'Variables'),  
			Tools		= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_Tools', 'Variables'),  
			Lubricant	= dbo.fnLocal_STI_Cmn_GetUDP(Var_Id, 'eCIL_Lubricant', 'Variables')  
FROM   dbo.Variables_Base WITH (NOLOCK)  
WHERE  Var_Id	= @VarId;  

