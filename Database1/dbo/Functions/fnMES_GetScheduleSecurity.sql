
CREATE Function dbo.fnMES_GetScheduleSecurity(
		 @PUIds	nvarchar(max) = null
		,@LineIds	nvarchar(max) = Null
		,@PathIds	nvarchar(max) = Null
		,@UserId	Int)

RETURNS @DisplayOptions TABLE (Id Int Identity (1,1), Path_Id Int, ReadSecurity Int, AddSecurity Int, DeleteSecurity Int, EditSecurity Int, ArrangeSecurity Int)

AS

BEGIN
	DECLARE @SchedSecurityTableId int = 2 -- Table ID Used to identify Schedule Security Lookups

	DECLARE @AllUnits Table (PU_Id Int)
	DECLARE @AllLines Table (PL_Id Int)
	DECLARE @AllPaths Table (Path_Id Int)
	DECLARE @End Int, @Start Int, @PathId Int, @ActualSecurity Int, @UsersSecurity Int

	If @PathIds Is Not NUll
	BEGIN
		INSERT INTO @AllPaths(Path_Id) 
			SELECT Id FROM dbo.fnCMN_IdListToTable('PrdExec_Paths',@PathIds,',')
	END
	ELSE If @LineIds Is Not NUll
	BEGIN
		INSERT INTO @AllLines(PL_Id) 
			SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines',@LineIds,',')
		INSERT INTO @AllPaths(Path_Id)
			SELECT Path_Id
			FROM PrdExec_Paths
			WHERE PL_Id in (Select PL_Id from @AllLines)
	END
    ELSE If @PUIds Is Not NUll
	BEGIN
		INSERT INTO @AllUnits(PU_Id) 
			SELECT DISTINCT Id 
				FROM dbo.fnCMN_IdListToTable('Prod_Units',@PUIds,',')
		INSERT INTO @AllLines(PL_Id)
			SELECT PL_Id
			FROM Prod_Units_Base
			WHERE PU_Id in (Select PU_Id from @AllUnits)
		INSERT INTO @AllPaths(Path_Id)
			SELECT Path_Id
			FROM PrdExec_Paths
			WHERE PL_Id in (Select PL_Id from @AllLines)
	END
 
	IF NOT EXISTS(SELECT 1 FROM @AllPaths)
	BEGIN
		RETURN
	END

	INSERT INTO @DisplayOptions(Path_Id, ReadSecurity, AddSecurity, DeleteSecurity, EditSecurity, ArrangeSecurity)
		SELECT Distinct Path_Id,0,0,0,0,0 FROM @AllPaths
	select @End = max(Id) from @DisplayOptions
	SET @Start = 1
	WHILE @Start <= @End
	BEGIN
		SELECT @PathId = Path_Id From @DisplayOptions WHERE Id = @Start
		SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@PathId,@UserId,2)
		Update @DisplayOptions SET ReadSecurity  = Case When @UsersSecurity > 0 Then 1 else 0 end WHERE Path_Id =  @PathId
		SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurityV2(@PathId,@SchedSecurityTableId,8,null,4,@UsersSecurity)
		Update @DisplayOptions SET AddSecurity  = @ActualSecurity WHERE Path_Id =  @PathId
		SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurityV2(@PathId,@SchedSecurityTableId,7,null,4,@UsersSecurity)
		Update @DisplayOptions SET DeleteSecurity  = @ActualSecurity WHERE Path_Id =  @PathId
		SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurityV2(@PathId,@SchedSecurityTableId,46,null,4,@UsersSecurity)
		Update @DisplayOptions SET EditSecurity  = @ActualSecurity WHERE Path_Id =  @PathId
		SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurityV2(@PathId,@SchedSecurityTableId,45,null,3,@UsersSecurity)
		Update @DisplayOptions SET ArrangeSecurity  = @ActualSecurity WHERE Path_Id =  @PathId
		SET @Start = @Start + 1
	END
	RETURN
END

