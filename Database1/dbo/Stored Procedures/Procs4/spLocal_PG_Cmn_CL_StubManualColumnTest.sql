
----------------------------------------[Creation Of SP]-----------------------------------------  
CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_CL_StubManualColumnTest]  
/*  
--------------------------------------------------------------------------------------------------------  
Stored procedure  : spLocal_PG_Cmn_CL_StubManualColumnTest  
Author     : Alexandre Turgeon, STI  
Date created   : 18-Apr-2006  
SP Type     : Model 602  
Called by    : Trigged every 5 minutes  
Version     : 1.3.1   
Editor tab spacing : 3  
  
Description:      
============   
If a shift change is detected, it calls a stored procedure that creates a user-defined event  
  
  
Revision	Date			Who					What  
========	=====			====				=====  
1.0.0		18-Apr-2006		Alexandre Turgeon	SP Creation  
  
1.1.0		07-Aug-2006		Ugo Lapierre		Get STLS unit for Crew Schedule search  
  
1.2.0		05-Jan-2009		Normand Carbonneau	Added WITH (NOLOCK) and reformatted.  
  
1.3.0		07-Apr-2009		Normand Carbonneau	Modified to retrieve STLS_ST_MASTER_UNIT_ID UDP  
												instead of only STLS  
  
1.3.1		23-Apr-2009		Normand Carbonneau	Using standard function to retrieve STLS unit  
  
1.3.2		02-Jun-2006		Humberto Abrahão	As the function fnLocal_STI_Cmn_GetUDP was   
												returning NULL values, I changed the   
												CrewSchedulePUId condition to test if is NULL  
1.3			04-May-2015		Nilesh Panpaliya	Updated version to match Serena VM version
1.4			07-May-2015		Nilesh Panpaliya	Enable Encryption   
1.5			22-Jul-2016		Megha Lohana(TCS)	Removed the register SP and update AppVersions section
1.6			3-Oct-2016		Megha Lohana		FO-02657 Update Centerline SPs to look for correct Eventfield Property Desc Column Offset
1.7			03-Apr-2019		Santiago (Arido)	Add capabilty to not add columns when the line is not scheduled
3.1			24-Jun-2021		Cristian Alexandru	Version Control for Centerline 3.1
3.1.1		29-Dec-2021		Bruno Velazquez		Add try catch and sections
--------------------------------------------------------------------------------------------------------  
*/
  
@Success  int output,  
@ErrorMsg varchar(255) OUTPUT,  
@ECId   int  
  
--WITH ENCRYPTION 
AS 
SET NOCOUNT ON  
  
BEGIN TRY 

DECLARE  
@Timestamp			datetime,  
@CsStartTime		datetime,  
@PuId				int,  
@LastUDETimestamp	datetime,  
@Offset				varchar(50),
@IntOffset			int,  
@EventSubType		int,  
@CrewSchedulePUId	int,  
@PlId				int,
@Section			VARCHAR(20)

----------------------------------------------------------------------------------
SET @Section = 'StubShiftChangeColumn'
----------------------------------------------------------------------------------
-- Get timestamp  
SET @Timestamp = getdate()  
  
-- Retrieve puid and event subtype from event configuration  
SELECT @PuId = PU_Id,  
	@EventSubType = Event_Subtype_Id  
FROM  dbo.Event_Configuration WITH (NOLOCK)  
WHERE  EC_Id = @ECId  
  
--Get line Id  
SET @PlId = (SELECT Pl_Id FROM dbo.Prod_Units_Base WHERE PU_Id = @PuId)  
  
-- Look for STLS UDP on the Unit  
SET @CrewSchedulePUId = dbo.fnLocal_STI_Cmn_GetUDP(@PuId, 'STLS_ST_MASTER_UNIT_ID', 'Prod_Units')  
  
--If the UDP is not found on the unit itself, look on the line  
IF @CrewSchedulePUId IS NULL  
BEGIN  
	SET @CrewSchedulePUId = dbo.fnLocal_STI_Cmn_GetUDP(@PlId, 'STLS_ST_MASTER_UNIT_ID', 'Prod_Lines')  
END  
  
-- If the Crew Schedule is still not found, set it to the unit itself  
IF @CrewSchedulePUId IS NULL  
BEGIN  
	SET @CrewSchedulePUId = @PuId  
END  

IF @CrewSchedulePUId IS NULL  
BEGIN  
	SELECT TOP 1 @CrewSchedulePUId = cs.PU_Id
		FROM	dbo.Crew_Schedule cs WITH (NOLOCK)
		JOIN	dbo.Prod_Units_Base u WITH (NOLOCK) ON cs.PU_Id = u.PU_Id
		JOIN	dbo.Prod_Units_Base lu WITH (NOLOCK) ON u.PL_Id = lu.PL_Id
		WHERE	lu.PU_Id = @PUId
		AND		Start_Time <= @Timestamp
END

IF @CrewSchedulePUId IS NULL  
BEGIN 
	SELECT   @Success = 2,
           @ErrorMsg = 'No crew schedule for unit id ' + @PuId
	RETURN
END
  
-- Find last beginning of shift timestamp  
SET @CsStartTime =  
	(  
	SELECT max(Start_Time)  
	FROM  dbo.Crew_Schedule WITH (NOLOCK)  
	WHERE  (PU_Id = @CrewSchedulePUId)  
		AND  
		(Start_Time < @Timestamp)  
	)  
  
-- Find last event timestamp  
SET @LastUDETimestamp =  
	(  
	SELECT max(End_Time)   
	FROM  dbo.User_Defined_Events WITH (NOLOCK)  
	WHERE  (PU_Id = @PuId)  
	AND  (Event_Subtype_Id = @EventSubType)  
	AND  (End_Time < @Timestamp)  
	)  
-- No last event or last event was before beginning of shift, create a new event  
IF (@LastUDETimestamp IS NULL) OR (@LastUDETimestamp < @CsStartTime)  
BEGIN  
	-- Retrieve offset if any 
	--FO-02657 Update Centerline SPs to look for correct Eventfield Property Desc Column Offset 
	EXEC spCmn_ModelParameterLookup @Offset OUTPUT, @ECId, 'Column Offset', 0  
  
	SET @IntOffset = SUBSTRING (@Offset, 6, 3)
  
	IF @IntOffset IS NOT NULL  
	BEGIN  
		SET @CsStartTime = dateadd(mi, @IntOffset, @CsStartTime)  
	END  
	----------------------------------------------------------------------------------
	SET @Section = 'ExecManualColumn'
	----------------------------------------------------------------------------------
	EXEC dbo.spLocal_PG_Cmn_CL_CreateManualColumnTest 'Shift Change', @PuId, @EventSubType, @CsStartTime  
	
END  
  
SET @Success = 1  
SET @ErrorMsg = ''  
  
END TRY
BEGIN CATCH

	SET @ErrorMsg = @Section + ' ErrorMsg: '+ ERROR_MESSAGE () + ' LineError: '+Convert(varchar,ERROR_LINE())  

END CATCH
SET NOCOUNT OFF  
  

