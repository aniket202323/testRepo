--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnMobileAppGetPrIMELocation
--------------------------------------------------------------------------------------------------
-- Author				: Linda Hudon, Symasol
-- Date created			: 2019-01-09
-- Version 				: Version <1.0>
-- SP Type				: Mobile App, 
-- Caller				: FROm PrimeDataView
-- Description			: get Prime Proficy location wherept
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------



--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2019-01-09	linda Hudon		Initial Release -

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXEC [dbo].[spLocal_CmnMobileAppGetPrIMELocation] 	
--*/

----------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppDebug] 	


--WITH ENCRYPTION	
AS
SET NOCOUNT ON


DECLARE
		--For debug 
		@CurrentTime					datetime,
		@ErrMsg							varchar(1000),	
		@TimeStamp						datetime,
		@CallingSP						varchar(50),
		@DebugOnline					int


DECLARE 
@TablePathID		int,
@TableProdUnit		int, 
@wMSMANAGEDUDP		int,
@TablePRDEXECInput	int,
@VartoSP			varchar(50)

DECLARE @Path TABLE(
pathId			int)


CREATE TABLE  #ProdUnits (

PUId			int,
PUDesc			varchar(50))

			
SET @DebugOnline = 1
SET @CurrentTime = GETDATE()
SET @CallingSP = 'spLocal_CmnMobileAppDebug'
SEt @VartoSP =  'First'

INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
VALUES(	getdate(), 
		@CallingSP,
		'0001 SP started' 
			)

SET @TablePathID   =  (SELECT TableID FROM dbo.Tables  WHERE TableName = 'PrdExec_Paths')
SET @TableProdUnit   =  (SELECT TableID FROM dbo.Tables  WHERE TableName = 'Prod_Units')
SET @TablePRDEXECInput   =  (SELECT TableID FROM dbo.Tables  WHERE TableName = 'PrdExec_Inputs')
SET @wMSMANAGEDUDP = (SELECT  Table_Field_Id FROM Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc ='PE_WMS_System' AND TableID = @TablePRDEXECInput) -- 1.1


-- get prod units  setup on a path
INSERT INTO #ProdUnits(PUID)
SELECT	DISTINCT pei.PU_ID
FROM	dbo.PrdExec_Input_Sources pei WITH(NOLOCK)
JOIN	dbo.Table_Fields_Values TFV WITH(NOLOCK) ON pei.pei_id = tfv.keyid
JOIN dbo.Prod_Units_Base pu on pei.PU_Id = pu.PU_Id
WHERE	tfv.Table_Field_Id = @wMSMANAGEDUDP
AND		UPPER(tfv.Value) ='PRIME'




UPDATE p
SET PUdesc = pu.PU_Desc
FROM #ProdUnits p 
JOIN dbo.Prod_Units_Base pu on p.PUId = pu.PU_Id

-- Encrypted SP
EXEC spLocal_CmnMobileAppGetProficyLocation 

-- non Encrypted SP
EXEC [spLocal_CmnMobileAppDebug1] @VartoSP OUTPUT


SELECT	PUID,
		PUDesc
FROM #ProdUnits
SET NOCOUNT OFF


