CREATE PROCEDURE [dbo].[spEsignature_GetEsignatureSiteConfiguration]
AS
BEGIN

	DECLARE @All_Parameters Table (esignatureInactivityPeriod Int, esignatureRequireAuthentication BIT, approverDefaultReasonTreeId Int, approverDefaultReasonId Int,userDefaultReasonTreeId Int, userDefaultReasonId int)
    ; WITH SP AS (SELECT Parm_Id, Value from Site_Parameters WHERE parm_Id IN (70, 74, 438, 439, 440, 441))
    INSERT INTO @All_Parameters(esignatureInactivityPeriod , esignatureRequireAuthentication , approverDefaultReasonTreeId , approverDefaultReasonId ,userDefaultReasonTreeId , userDefaultReasonId )
	SELECT
        esignatureInactivityPeriod = (SELECT value FROM SP where Parm_id = 70),
        esignatureRequireAuthentication = (SELECT value FROM SP where Parm_id = 74),
        approverDefaultReasonTreeId = (SELECT value FROM SP where Parm_id = 438),
        approverDefaultReasonId = (SELECT value FROM SP where Parm_id = 439),
        userDefaultReasonTreeId = (SELECT value FROM SP where Parm_id = 440),
        userDefaultReasonId = (SELECT value FROM SP where Parm_id = 441)
	SELECT TOP 1 
		av.esignatureInactivityPeriod,
		av.esignatureRequireAuthentication,
		av.approverDefaultReasonTreeId, 
		av.approverDefaultReasonId,
		av.userDefaultReasonTreeId,
		av.userDefaultReasonId 
		FROM @All_Parameters av 

END

