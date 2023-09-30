

CREATE Function [dbo].[fnWaste_GetWasteSecurity](
		 @PUIds	nvarchar(max) = null
		,@LineIds	nvarchar(max) = Null
		,@UserId	Int)
/*

Select PU_Id,MasterUnit,AddSecurity,DeleteSecurity,AddComments,AssignReasons,CloseSecurity ChangeAmount,ChangeComments,ChangeFault
,ChangeLocation,Opensecurity ChangeTime,[CopyPasteReasons&Fault],SplitRecords FilterDisplay,CopyReasons,copyfault
from dbo.fnWaste_GetWasteSecurity('1017',NULL,1)
*/
RETURNS @DisplayOptions TABLE (Id Int Identity (1,1),PU_Id Int,MasterUnit Int,AddSecurity Int,DeleteSecurity Int,
								CloseSecurity Int,OpenSecurity Int,EditStartTimeSecurity Int,
								AddComments Int,AssignReasons Int,ChangeComments Int,
								ChangeFault Int,ChangeLocation int,OverlapRecords Int,
								SplitRecords Int, [CopyPasteReasons&Fault] Int , CopyFault Int , CopyReasons Int)

AS

BEGIN
	DECLARE @AllUnits Table (PU_Id Int,MasterUnit Int)
	DECLARE @AllLines Table (PL_Id Int,MasterUnit Int)
	DECLARE @SecurityUnits Table (PU_Id Int)
	DECLARE @UnitsToProcess Table (Id Int Identity (1,1),MasterId Int)
	DECLARE @End Int, @Start Int,@PUId Int,@ActualSecurity Int
	DECLARE @UsersSecurity Int


	If @LineIds Is Not NUll
	BEGIN
		INSERT INTO @AllLines(PL_Id) 
			SELECT Id FROM dbo.fnCMN_IdListToTable('xxx',@LineIds,',')
		INSERT INTO @AllUnits(PU_Id,MasterUnit)
			SELECT a.PU_Id,Coalesce(a.Master_Unit, a.PU_Id)
			FROM Prod_Units_Base a
			JOIN @AllLines c on c.PL_Id = a.PL_Id 
			Join Event_Configuration  b on b.ET_Id = 3 and b.PU_Id = a.PU_Id
		INSERT INTO @AllUnits(PU_Id,MasterUnit)
			SELECT a.PU_Id,a.Master_Unit 
			FROM Prod_Units_Base a
			JOIN @AllUnits b On b.PU_Id = a.Master_Unit  
		IF NOT EXISTS(SELECT 1 FROM @AllUnits)
		BEGIN
			RETURN
		END	
	END
    ELSE If @PUIds Is Not NUll
	BEGIN
		INSERT INTO @AllUnits(PU_Id) 
			SELECT DiSTINCT Id 
				FROM dbo.fnCMN_IdListToTable('xxx',@PUIds,',')
		UPDATE @AllUnits Set MasterUnit = Coalesce(b.Master_Unit, b.PU_Id)
			FROM @AllUnits a
			JOIN Prod_Units_Base b on b.PU_Id = a.PU_Id 
			JOIN Event_Configuration  c on c.ET_Id = 3 and c.PU_Id =  Coalesce(b.Master_Unit, b.PU_Id)
		IF NOT EXISTS(SELECT 1 FROM @AllUnits)
		BEGIN
			RETURN
		END	
	END
 

	--INSERT INTO @SecurityUnits(PU_Id)
	--	SELECT DISTINCT PU_Id FROM dbo.fnMES_GetDowntimeAvailableUnits(@UserId)

	--IF EXISTS(SELECT 1 FROM @AllUnits)
	--	DELETE FROM @AllUnits WHERE ISNULL(MasterUnit,0) NOT IN (SELECT PU_ID FROM @SecurityUnits)
	--ELSE
	--BEGIN
	--	INSERT INTO @AllUnits(PU_Id,MasterUnit)  SELECT DISTINCT PU_Id,PU_Id FROM @SecurityUnits
	--	INSERT INTO @AllUnits(PU_Id,MasterUnit)  
	--		SELECT a.PU_Id,a.Master_Unit 
	--		FROM Prod_Units_Base a
	--		JOIN @AllUnits b On b.PU_Id = a.Master_Unit  
	--END
	/*
	
	Need to check for Waste Available Units
	*/
	IF EXISTS (Select 1 from @AllUnits)
	Begin
			INSERT INTO @AllUnits(PU_Id,MasterUnit)  
			SELECT a.PU_Id,a.Master_Unit 
			FROM Prod_Units_Base a
			JOIN @AllUnits b On b.PU_Id = a.Master_Unit  
	End

	IF NOT EXISTS(SELECT 1 FROM @AllUnits)
	BEGIN
		RETURN
	END
	
	declare @DisplayOptionsTuned dbo.DisplayOptions
	Insert Into @DisplayOptionsTuned(PU_Id,MasterUnit,AddSecurity,DeleteSecurity,CloseSecurity,OpenSecurity,
								EditStartTimeSecurity,AddComments,AssignReasons,ChangeComments,ChangeFault
									,ChangeLocation,OverlapRecords,	SplitRecords, [CopyPasteReasons&Fault],CopyFault,CopyReasons,UsersSecurity)
	SELECT Distinct PU_Id,MasterUnit,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,dbo.fnBF_CmnGetUserAccessLevel(ISNULL(MasterUnit,PU_Id),@UserId,4) FROM @AllUnits


	Declare @SheetSecurityOptions dbo.SheetSecurityOptions
	Insert Into @SheetSecurityOptions(SecurityType,DtOption,DtpOption,Defaultlevel,Pu_id)
	Select DISTINCT 'AddSecurity',8,393,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all /* 8 - "AddSecurity" Display Option for Classic DT :: 393 - "Insert Records" Display Option for DT+ */
	Select DISTINCT 'DeleteSecurity',7,392,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all/* 7 - "DeleteSecurity" Display Option for Classic DT :: 392 - "Delete Records" Display Option for DT+ */
	Select DISTINCT 'OpenSecurity',129,397,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all/* 129 - "OpenSecurity" Display Option for Classic DT :: 397 - "Change Time" Display Option for DT+ */
    Select DISTINCT 'CloseSecurity',130,397,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all/* 130 - "CloseSecurity" Display Option for Classic DT :: 397 - "Change Amount" Display Option for DT+ */
	Select DISTINCT 'AddComments',NULL,388,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--present
	Select DISTINCT 'AssignReasons',NULL,389,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--present
	Select DISTINCT 'ChangeAmount',NULL,403,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--close security/ChangeAmount
	Select DISTINCT 'ChangeComments',NULL,390,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--present
	Select DISTINCT 'ChangeFault',NULL,400,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--present
	Select DISTINCT 'ChangeLocation',NULL,401,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--present
	Select DISTINCT 'ChangeTime',NULL,397,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--opensecurity/ChangeTime
	Select DISTINCT 'CopyPasteReasons&Fault',NULL,391,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--present
	Select DISTINCT 'FilterDisplay',NULL,402,3,ISNULL(MasterUnit,PU_Id) from @AllUnits union all--splitrecords/FilterDisplay
	SELECT DISTINCT 'CopyReasons',null,467,3,ISNULL(MasterUnit,PU_Id) from @AllUnits--present
	
	
	Insert Into @DisplayOptions(PU_Id,MasterUnit,AddSecurity,DeleteSecurity,CloseSecurity,OpenSecurity,EditStartTimeSecurity,AddComments,AssignReasons,ChangeComments,ChangeFault,ChangeLocation,OverlapRecords,	SplitRecords, [CopyPasteReasons&Fault],CopyFault,CopyReasons) 
	Select PU_Id,MasterUnit,AddSecurity,DeleteSecurity,CloseSecurity,OpenSecurity,EditStartTimeSecurity,AddComments,AssignReasons,ChangeComments,ChangeFault,ChangeLocation,OverlapRecords,SplitRecords,[CopyPasteReasons&Fault],CopyFault,CopyReasons
	From
		dbo.fnWT_CheckSheetSecurityTbl(@DisplayOptionsTuned,@SheetSecurityOptions,1,1,1,1,1)

	RETURN
END


