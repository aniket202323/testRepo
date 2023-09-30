
-------------------------------------------------------------------------------------------------------------
-- 										OPS Database Stored Procedure									   --	
--						This stored procedure will feed the OpsDB_Reject_Data table						   --
-------------------------------------------------------------------------------------------------------------
-- 										SET TAB SPACING TO 4											   --	
-------------------------------------------------------------------------------------------------------------
-- 2016-10-20		Fernando Rio			Initial Development											   --
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_OpsDataStore_ETL_GetRejects]
@Table_MaxTEDetid4Unit dbo.TT_OpsDB_RejLastTransf_by_Unit READONLY
--WITH ENCRYPTION 
AS

------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
------------------------------------------------------------------------------------------------------------------
 

DECLARE @PLIDList TABLE (	
				RcdIdx	 				INT		,
				PLId 					INT		,
				RejectUnit				INT		,
				MaxRejectTime			DATETIME,
				MaxRejectId				INT	)

CREATE TABLE #Rejects (
				Timestamp				Datetime		,
				TimestampUTC			Datetime		,
				Amount					Float			,
				Units					Varchar(30)		,
				Type					Varchar(30)		,
				Fault					Varchar(30)		,
				FaultGlobal				Varchar(30)		,
				FaultCode				Varchar(30)		,
				Reason1					Varchar(100)	,
				Reason1Global			Varchar(100)	,
				ReasonCode				Varchar(30)		,				
				Location				Varchar(75)		,
				ProdCode				Varchar(50)		,
				ProdDesc				nvarchar(100)	,
				ProdFam					nvarchar(100)	,
				ProdGroup				nvarchar(100)	,
				ProcessOrder			nvarchar(50)	,
				Team					varchar(25)		,
				Shift					varchar(25)		,
				Status					varchar(50)		,
				Comments				varchar(255)	,
				LineDesc				varchar(75)		,
				UnitID					int				,
				SourceUnitId			INT				,
				UnitDesc				varchar(75)		,
				PlId					int				,
				TransferFlag			int				,
				WedId					int				,
				Site					varchar(50)		)

-----------------------------------------------------------------------------------------------------------------
-- Get Site
-----------------------------------------------------------------------------------------------------------------
DECLARE @Site VARCHAR(50)
SELECT  @Site = (SELECT sp.value FROM Site_parameters sp 
				JOIN parameters pp ON pp.parm_id = sp.parm_id WHERE pp.parm_name = 'SiteName')
-----------------------------------------------------------------------------------------------------------------
-- Get the Proficy Database Version
-----------------------------------------------------------------------------------------------------------------
DECLARE @AppVersion NVARCHAR(50)

SELECT @AppVersion = App_Version FROM dbo.AppVersions WITH(NOLOCK) WHERE App_Name = 'Database'
-----------------------------------------------------------------------------------------------------------------
-- 											REJECT DATA
-----------------------------------------------------------------------------------------------------------------
INSERT INTO @PLIDList (PLId, RejectUnit)
SELECT pu.PL_Id, pu.PU_Id 
FROM dbo.Event_Configuration ec WITH(NOLOCK)
JOIN dbo.Prod_Units pu			WITH(NOLOCK)	ON ec.PU_Id = pu.PU_Id
WHERE EC_Desc LIKE '%P&G Waste Model%'


 UPDATE pl
	SET MaxRejectId = (SELECT MAX(WedId) FROM @Table_MaxTEDetid4Unit
								WHERE UnitId = pl.RejectUnit)
FROM @PLIDList pl
--
-- If this is the first time:
 UPDATE pl
	SET MaxRejectId = (SELECT MIN(WED_ID) FROM dbo.Waste_Event_Details WITH(NOLOCK)
										WHERE Timestamp > DATEADD(hh,-82,GETDATE())
										AND PU_Id = pl.RejectUnit )
FROM @PLIDList pl
WHERE MaxRejectId IS NULL

-----------------------------------------------------------------------------------------------------------------
-- Get Rejects
-----------------------------------------------------------------------------------------------------------------

INSERT INTO  #Rejects 		(
				WedId									,
				Timestamp								,				
				Amount									,
				Units									,
				Fault									,
				FaultGlobal								,
				FaultCode								,
				Reason1									,
				Reason1Global							,
				ReasonCode								,
				SourceUnitId							,
				UnitID									,				
				PlId									,
				TransferFlag							,				
				Site									)
SELECT			top 5000 
				Wed_Id									,
				Timestamp								,
				Amount									,
				'Pads'									,
				wef.WEFault_Name						,
				wef.WEFault_Name_Global					,
				WEFault_Value							,
				Event_Reason_Name						,
				Event_Reason_Name_Global				,
				Event_Reason_Id							,
				wed.Source_PU_id						,
				wed.PU_Id								,
				PLId									,
				0										,
				@Site									
	FROM dbo.Waste_Event_Details wed	WITH(NOLOCK)  
	JOIN @PLIDList pl 					ON wed.pu_id = pl.RejectUnit   
										AND wed.WED_Id > pl.MaxRejectId  
	LEFT JOIN dbo.Event_Reasons r1		WITH(NOLOCK) ON r1.event_Reason_id = wed.Reason_Level1
	LEFT JOIN dbo.Waste_Event_Fault wef WITH(NOLOCK) ON (wef.weFault_id = wed.WeFault_Id)	

-----------------------------------------------------------------------------------------------------------------
-- Update Team Information
-----------------------------------------------------------------------------------------------------------------
UPDATE r
		SET Team		=		cs.Crew_Desc			,
			Shift		=		cs.Shift_Desc		
FROM #Rejects   r
JOIN dbo.Crew_Schedule cs WITH(NOLOCK) ON r.UnitId = cs.PU_id
WHERE r.Timestamp > cs.Start_Time
	AND r.Timestamp <= cs.End_Time

-----------------------------------------------------------------------------------------------------------------
-- Update Line Status Information
-----------------------------------------------------------------------------------------------------------------
UPDATE r
		SET Status		=		phr.Phrase_Value			
FROM #Rejects   r
JOIN dbo.Local_PG_Line_Status ls  WITH(NOLOCK) ON r.UnitId = ls.Unit_Id
LEFT JOIN dbo.Phrase phr WITH(NOLOCK) ON ls.Line_Status_ID = phr.Phrase_ID
WHERE r.Timestamp > ls.Start_DateTime 
AND   (r.Timestamp <= ls.End_DateTime OR ls.End_DateTime IS NULL)

-----------------------------------------------------------------------------------------------------------------
-- Update Product Information
-----------------------------------------------------------------------------------------------------------------
UPDATE r
		SET ProdDesc		=		p.Prod_Desc		,
			ProdCode		= 		p.Prod_Code		,
			ProdGroup		=		pg.Product_Grp_Desc	,
			ProdFam			=		pf.Product_Family_Desc
FROM #Rejects   r
JOIN dbo.Production_Starts ps		WITH(NOLOCK)	ON r.UnitId = ps.PU_Id
JOIN dbo.Products p					WITH(NOLOCK)	ON p.Prod_Id = ps.Prod_Id
JOIN dbo.Product_Group_Data pgd		WITH(NOLOCK)	ON p.Prod_Id = pgd.Prod_Id
JOIN dbo.Product_Groups pg			WITH(NOLOCK)	ON pgd.Product_Grp_Id = pg.Product_Grp_Id
JOIN dbo.Product_Family pf			WITH(NOLOCK)	ON pf.Product_Family_Id = p.Product_Family_Id
WHERE r.Timestamp > ps.Start_Time
AND   (r.Timestamp <= ps.End_Time OR ps.End_Time IS NULL)

-----------------------------------------------------------------------------------------------------------------
-- Update Line Information
-----------------------------------------------------------------------------------------------------------------
UPDATE r
		SET LineDesc	= pl.PL_Desc		,
			UnitDesc	= pu.PU_Desc		,
			Location	= pu2.PU_Desc
FROM #Rejects   r
JOIN dbo.Prod_Units		pu		WITH(NOLOCK) ON  pu.PU_Id = r.UnitId
JOIN dbo.Prod_Lines		pl		WITH(NOLOCK) ON	pl.PL_Id = pu.PL_Id
JOIN dbo.Prod_Units		pu2		WITH(NOLOCK) ON	pu2.PU_Id = r.SourceUnitId

-----------------------------------------------------------------------------------------------------------------
-- Update Product Run Information
-----------------------------------------------------------------------------------------------------------------
UPDATE r
		SET ProcessOrder = pp.Process_Order
FROM #Rejects   r
JOIN dbo.Production_Plan_Starts		pps	WITH(NOLOCK) ON r.UnitId = pps.PU_Id
JOIN dbo.Production_Plan			pp	WITH(NOLOCK) ON pps.PP_Id = pp.PP_Id
WHERE r.Timestamp > pp.Actual_Start_Time AND (r.Timestamp <= pp.Actual_End_Time OR pp.Actual_End_Time IS NULL)

-----------------------------------------------------------------------------------------------------------------
--SELECT '#Rejects',COUNT(*) FROM #Rejects
-----------------------------------------------------------------------------------------------------------------

SELECT 			Timestamp						,
				CONVERT(DATETIME,dateadd(minute,datediff(minute,getdate(),getutcdate()),Timestamp)) AS TimestampUTC					,
				Amount							,
				Units							,
				Type							,
				Fault							,
				FaultGlobal						,
				FaultCode						,
				Reason1							,
				Reason1Global					,
				ReasonCode						,				
				Location						,
				ProdCode						,
				ProdDesc						,
				ProdFam							,
				ProdGroup						,
				ProcessOrder					,
				Team							,
				Shift							,
				Status							,
				Comments						,
				LineDesc						,
				UnitID							,
				SourceUnitId					,
				UnitDesc						,
				PLID							,
				TransferFlag					,
				WedId							,				
				Site	
FROM			#Rejects

-----------------------------------------------------------------------------------------------------------------
-- DROP Tables
-----------------------------------------------------------------------------------------------------------------
DROP TABLE #Rejects
RETURN

