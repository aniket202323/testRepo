
CREATE PROCEDURE dbo.spMES_GetUnitSecurity
		@PUIds	nvarchar(max) = null
		,@LineIds	nvarchar(max) = Null
		,@UserId	Int
		,@Type Int 

AS

/* spMES_GetUnitSecurity  null,null,1,1 */
/* spMES_GetUnitSecurity  null,null,1,2 */

IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT  Code = 'InsufficientPermission', Error = 'ERROR: Valid User Required'
	RETURN
END
IF @Type = 1 -- Downtime
BEGIN

	SELECT UnitId = PU_Id, PermissionName, PermissionValue from dbo.fnMES_GetDowntimeSecurity( @PUIds,@LineIds,@UserId)
	UNPIVOT
	(
			PermissionValue
			FOR [PermissionName] IN (AddSecurity,DeleteSecurity,CloseSecurity,OpenSecurity,
									EditStartTimeSecurity,AddComments,AssignReasons,ChangeComments,ChangeFault,
									ChangeLocation,OverlapRecords,SplitRecords,[CopyPasteReasons&Fault],CopyFault,CopyReasons)
	) AS P

	ORDER BY UnitId,PermissionName
END
ELSE IF @Type = 2 -- NPT
BEGIN

	SELECT UnitId = PU_Id, PermissionName, PermissionValue from dbo.fnMES_GetNonProductiveTimeSecurity( @PUIds,@LineIds,@UserId)
	UNPIVOT
	(
			PermissionValue
			FOR [PermissionName] IN (AddSecurity,EditSecurity)
	) AS P

	ORDER BY UnitId,PermissionName
END
ELSE
BEGIN
	SELECT  Error = 'ERROR: Invalid Type'
	RETURN
END


