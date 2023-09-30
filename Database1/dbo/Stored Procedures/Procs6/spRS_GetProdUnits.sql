/*
Declare @ProdLine int, @UnitListString varchar(7000), @IncludeUnitList int, @ShowSlaveUnits int, @OnlyUnitsWithEvents int
Select @ProdLine=2, @UnitListString='3', @IncludeUnitList=0, @ShowSlaveUnits=1, @OnlyUnitsWithEvents=1
exec sprs_getProdUnits @ProdLine, @UnitListString, @IncludeUnitList, @ShowSlaveUnits, @OnlyUnitsWithEvents
*/
CREATE PROCEDURE dbo.spRS_GetProdUnits
@ProdLine int = NULL,
@UnitListString varchar(7000) = NULL,
@IncludeUnitList int = NULL,
@ShowSlaveUnits int = NULL,
@OnlyUnitsWithEvents int = NULL
 AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
If @ShowSlaveUnits Is Null
  Select @ShowSlaveUnits = 0
If @IncludeUnitList Is Null
  Select @IncludeUnitList=1
If @OnlyUnitsWithEvents Is Null
  Select @OnlyUnitsWithEvents = 0
---------------------------------------
-- Units With Events Associated
---------------------------------------
Create Table #UnitsWithEvents(PU_Id int)
Insert Into #UnitsWithEvents(PU_ID)
Select Distinct Id = ec.pu_id
  From Event_Configuration ec
Join Prod_Units pu on pu.pu_id = ec.pu_id
Join Event_Types et on et.et_Id = ec.et_Id
where pu.pu_id > 0
Declare @SQL VarChar(6000)
Declare @Where varchar(3000)
--Declare @UnitsWithEvents varchar(2000)
--Select @UnitsWithEvents = ''
--Select @UnitsWithEvents = @UnitsWithEvents +
--  Case When @UnitsWithEvents = '' Then Convert(varchar(5), PU_Id) Else ',' + Convert(varchar(5), PU_Id) end
--From #UnitsWithEvents
---------------------------------------
-- Build SQL String
---------------------------------------
Select @SQL = 'Select pu.PU_ID, pu.PU_Desc From Prod_Units pu '
Select @Where = 'Where pu.pu_id <> 0 '
If @ProdLine Is Not Null
  Select @Where = @Where + 'AND pu.PL_ID = ' + convert(varchar(5), @ProdLine) + ' '
If (@UnitListString Is Not Null) and ( LTrim(RTrim(@UnitListString)) <> '')
  Begin
    If @IncludeUnitList = 1
      Select @Where = @Where + 'AND pu.PU_ID in (' + @UnitListString + ') '
    Else
      Select @Where = @Where + 'AND pu.PU_ID not in (' + @UnitListString + ') '
  End
If @OnlyUnitsWithEvents = 1
  Select @Where = @Where + 'AND pu.PU_ID in ( select PU_ID from #UnitsWithEvents) '
If @ShowSlaveUnits = 0
  Select @Where = @Where + 'AND pu.Master_Unit Is null '
select @SQL = @SQL + @Where
Select @SQL = @SQL + ' Order By pu.pu_desc '
Print @SQL
exec( @SQL )
