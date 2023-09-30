
CREATE PROCEDURE dbo.spActivities_GetSheetInfos
		@LineIds			nVarChar(max) = Null
		,@PUIds				nVarChar(max) = null
		,@SheetIds			nVarChar(max) = Null
		,@SheetTypeIds		nVarChar(max) = Null
		,@SheetGroupIds		nVarChar(max) = Null
		,@EventTypeIds		nVarChar(max) = Null
		,@UserId			Int

AS


IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required'
	RETURN
END

DECLARE @AllLines Table (PL_Id Int)
DECLARE @AllUnits Table (PU_Id Int, MasterUnit Int)
DECLARE @AllSheets Table (Sheet_Id Int, PU_Id Int)
DECLARE @AllSheetTypes Table (Sheet_Type_Id Int)
DECLARE @AllSheetGroups Table (Sheet_Group_Id Int)
DECLARE @AllEventTypes Table (ET_Id Int)

If @LineIds Is NULL and @PUIds is NULL
BEGIN
	INSERT INTO @AllUnits(PU_Id, MasterUnit)
		SELECT a.PU_Id, a.Master_Unit 
		FROM Prod_Units_Base a
END
ELSE If @LineIds Is Not NULL
BEGIN
	INSERT INTO @AllLines(PL_Id) 
		SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines', @LineIds,',')
	INSERT INTO @AllUnits(PU_Id, MasterUnit)
		SELECT a.PU_Id, Coalesce(a.Master_Unit, a.PU_Id)
		FROM Prod_Units_Base a
		JOIN @AllLines c on c.PL_Id = a.PL_Id 
	INSERT INTO @AllUnits(PU_Id, MasterUnit)
		SELECT a.PU_Id, a.Master_Unit 
		FROM Prod_Units_Base a
		JOIN @AllUnits b On b.PU_Id = a.Master_Unit  
END
ELSE If @PUIds is not NULL
BEGIN
	INSERT INTO @AllUnits(PU_Id) 
		SELECT DiSTINCT Id FROM dbo.fnCMN_IdListToTable('Prod_Units', @PUIds, ',')
	UPDATE @AllUnits Set MasterUnit = Coalesce(b.Master_Unit, b.PU_Id)
		FROM @AllUnits a
		JOIN Prod_Units_Base b on b.PU_Id = a.PU_Id 
END

If @SheetIds is not NULL
BEGIN
	INSERT INTO @AllSheets(Sheet_Id) 
		SELECT Id FROM dbo.fnCMN_IdListToTable('Sheets', @SheetIds, ',')

	-- By Master Unit
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, s.Master_Unit
		FROM Sheets s
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)
		  and s.Master_Unit is not null

	-- By Sheet Units
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, su.PU_Id
		FROM Sheets s
		join Sheet_Unit su on su.Sheet_Id = s.Sheet_Id
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)

	-- By Sheet Display Options
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, do.value
		FROM Sheets s
		join Sheet_Display_options do on do.Sheet_id = s.Sheet_Id and do.Display_Option_Id = 446
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)

	-- By Variables
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, v.PU_Id
		FROM Sheets s
		join Sheet_Variables sv on sv.Sheet_Id = s.Sheet_Id and sv.Var_Id is not null
		join Variables_Base v on v.Var_Id = sv.Var_Id
		where s.Sheet_Id in (Select Sheet_Id from @AllSheets where PU_Id is null)

	delete from @AllSheets where PU_Id is null
END
ELSE
BEGIN
	-- By Master Unit
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, s.Master_Unit
		FROM Sheets s
		join @AllUnits u on u.PU_Id = s.Master_Unit and u.PU_Id not in (select PU_Id from @AllSheets where Sheet_Id = s.Sheet_Id)

	-- By Sheet Units
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, su.PU_Id
		FROM Sheets s
		join Sheet_Unit su on su.Sheet_Id = s.Sheet_Id
		join @AllUnits u on u.PU_Id = su.PU_Id and u.PU_Id not in (select PU_Id from @AllSheets where Sheet_Id = s.Sheet_Id)

	-- By Sheet Display Options
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, do.value
		FROM Sheets s
		join Sheet_Display_options do on do.Sheet_id = s.Sheet_Id and do.Display_Option_Id = 446
		join @AllUnits u on u.PU_Id = do.value and u.PU_Id not in (select PU_Id from @AllSheets where Sheet_Id = s.Sheet_Id)

	-- By Variables
	INSERT INTO @AllSheets(Sheet_Id, PU_Id)
		SELECT distinct s.Sheet_Id, v.PU_Id
		FROM Sheets s
		join Sheet_Variables sv on sv.Sheet_Id = s.Sheet_Id and sv.Var_Id is not null
		join Variables_Base v on v.Var_Id = sv.Var_Id
		join @AllUnits u on u.PU_Id = v.PU_Id and u.PU_Id not in (select PU_Id from @AllSheets where Sheet_Id = s.Sheet_Id)
END

-- Eliminate Sheets User is not allowed to see
delete from @AllSheets
  where sheet_id not in (
          select s.sheet_id
            from sheets s
            left join user_security us on us.Group_Id = s.Group_Id and us.User_Id = @UserId
            where s.Group_Id is null or us.access_level >= 1
        )

IF NOT EXISTS(SELECT 1 FROM @AllSheets)
BEGIN
	SELECT  Error = 'ERROR: No Valid Sheets Found'
	RETURN
END	

If @SheetTypeIds Is Not NULL
BEGIN
	INSERT INTO @AllSheetTypes(Sheet_Type_Id) 
		SELECT Id FROM dbo.fnCMN_IdListToTable('Sheet_Type', @SheetTypeIds, ',')
END

If @SheetGroupIds Is Not NULL
BEGIN
	INSERT INTO @AllSheetGroups(Sheet_Group_Id) 
		SELECT Id FROM dbo.fnCMN_IdListToTable('Sheet_Groups', @SheetGroupIds, ',')
END

If @EventTypeIds Is Not NULL
BEGIN
	INSERT INTO @AllEventTypes(ET_Id) 
		SELECT Id FROM dbo.fnCMN_IdListToTable('Event_Types', @EventTypeIds, ',')
END

Select  DISTINCT
		s.Sheet_Id, d.Dept_Id, d.Dept_Desc, l.PL_Id, l.PL_Desc, u.PU_Id, u.PU_Desc,
		s.Sheet_Desc, st.Sheet_Type_Id, st.Sheet_Type_Desc, sg.Sheet_Group_Id, sg.Sheet_Group_Desc,
		et.ET_Id, et.ET_Desc, est.Event_Subtype_Id, est.Event_Subtype_Desc, s.Interval, s.Offset
  from sheets s
  join @AllSheets a on a.Sheet_Id = s.Sheet_Id
  join prod_units_base u on u.PU_Id = a.PU_Id
  join prod_lines_base l on l.PL_Id = u.PL_Id
  join departments_base d on d.Dept_Id = l.Dept_Id
  join Sheet_Type st on st.Sheet_Type_Id = s.Sheet_Type
  join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
  join Event_Types et on et.ET_Id = s.Event_Type
  left join Event_SubTypes est on est.Event_Subtype_Id = s.Event_SubType_Id
  where (@SheetTypeIds is null or s.Sheet_Type in (select Sheet_Type_Id from @AllSheetTypes))
    and (@SheetGroupIds is null or s.Sheet_Group_Id in (select Sheet_Group_Id from @AllSheetGroups))
    and (@EventTypeIds is null or s.Event_Type in (select ET_Id from @AllEventTypes))
  order by d.Dept_Desc, l.PL_Desc, u.PU_Desc, s.Sheet_Desc

