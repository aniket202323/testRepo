
CREATE PROCEDURE dbo.spMES_GetPaths
		 @LineId	int = null				-- filter paths for a certain line
		,@UnitIds	nvarchar(max) = Null	-- only include paths which contain one of these units
		,@UserId	Int						-- user must have rights to read on the paths
		,@PathId	Int = Null				-- filter to only this path
AS

----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good user
----------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Declares
----------------------------------------------------------------------------------------------------------------------------------
Declare @AllUnits Table (UnitId Int)
Declare @Paths table (PathId int, PathCode nvarchar(50), PathDescription nvarchar(50), LineId int,
                      CommentId int null, IsLineProduction bit, IsScheduleControlled bit,
					  ScheduleControlType tinyint null)

----------------------------------------------------------------------------------------------------------------------------------
-- Verify the Line exists
----------------------------------------------------------------------------------------------------------------------------------
if (@LineId is not null) and (NOT EXISTS(SELECT 1 FROM Prod_Lines_Base WHERE @LineId = PL_Id))
BEGIN
	SELECT Error = 'ERROR: Line not found', Code = 'ResourceNotFound', ErrorType = 'LineNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Grab the initial set of paths
----------------------------------------------------------------------------------------------------------------------------------
insert into @Paths (PathId, PathCode, PathDescription, LineId, CommentId, IsLineProduction, IsScheduleControlled, ScheduleControlType)
  Select Path_Id, Path_Code, Path_Desc, PL_Id, Comment_Id, Is_Line_Production, Is_Schedule_Controlled, Schedule_Control_Type
  from   Prdexec_Paths
  where  ((@LineId is null) or (@LineId = PL_Id))
    and  ((@PathId is null) or (@PathId = Path_Id))

if (@PathId is not null) and (NOT EXISTS(SELECT 1 FROM @Paths WHERE @PathId = PathId))
BEGIN
	SELECT Error = 'ERROR: Path not found', Code = 'ResourceNotFound', ErrorType = 'PathNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Eliminate paths if there is a units filter
----------------------------------------------------------------------------------------------------------------------------------
if (@UnitIds is not null)
Begin
    INSERT INTO @AllUnits (UnitId)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units', @UnitIds, ',')
	delete
	  from  @Paths
	  where PathId not in (
	    select Path_Id
		  from PrdExec_Path_Units
		  where PU_Id in (select UnitId from @AllUnits)
		    and Path_Id in (select PathId from @Paths)
	  )
End

if (@PathId is not null) and (NOT EXISTS(SELECT 1 FROM @Paths WHERE @PathId = PathId))
BEGIN
	SELECT Error = 'ERROR: Path not found (Filtered)', Code = 'ResourceNotFound', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Eliminate paths if user doesn't have read access to it
----------------------------------------------------------------------------------------------------------------------------------
declare @PathIds nvarchar(max)
select @PathIds = coalesce(@PathIds + ',', '') +  convert(nvarchar(12), PathId) from @Paths order by PathId

declare @Security Table (PathId Int, ReadSecurity Int)
insert into @Security (PathId, ReadSecurity)
	select Path_Id, ReadSecurity from dbo.fnMES_GetScheduleSecurity (null,null,@PathIds,@UserId)

Delete from @Paths where PathId not in (Select PathId from @Security where ReadSecurity = 1)

if (@PathId is not null) and (NOT EXISTS(SELECT 1 FROM @Paths WHERE @PathId = PathId))
BEGIN
	SELECT Error = 'ERROR: Path not visible to user', Code = 'InsufficientPermission', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Return final results
----------------------------------------------------------------------------------------------------------------------------------
Select     PathId, PathCode, PathDescription, LineId, CommentId, IsLineProduction, IsScheduleControlled, ScheduleControlType
  from     @Paths
  order by PathId

Select     Path_Id as PathId,
           PEPU_Id as ExecutionPathUnitId,
           Is_Production_Point as IsProductionPoint,
	       Is_Schedule_Point as IsSchedulePoint,
	       PU_Id as UnitId,
	       Unit_Order as UnitOrder
  from     Prdexec_Path_Units
  where    Path_Id in (Select PathId from @Paths)
  order by Path_Id, Unit_Order

