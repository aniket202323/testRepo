CREATE PROCEDURE [dbo].[spMESCore_GetGenealogyData]
 	 @RootId 	  	 int,
 	 @Levels 	  	 int,
 	 @Direction 	 bit,
 	 @MaterialProperties varchar(4000) = null,
 	 @LotProperties varchar(4000) = null,
 	 @EquipmentProperties varchar(4000) = null
AS
/*
Execute spMESCore_GetGenealogyData 8046406,5,1,null,null
*/
IF @Direction = Null 
 	 SET @Direction = 1
IF @Levels IS Null
 	 SET @Levels = 10
IF @Levels < 1 or @Levels > 20
 	 Set @Levels = 20
create table #Genealogy  (Level int, Parent_Event_Id int, Event_Id int, Start_Time DateTime, Timestamp DateTime)
create table #Genealogy2 (Event_Id int)
DECLARE @Cmd varchar(4000)
DECLARE @PropSel  varchar(4000)
DECLARE @PropJOIN varchar(4000)
DECLARE @PropName varchar(100)
DECLARE @Varid VarChar(20)
DECLARE @End Int
DECLARE @VarName VarChar(2)
DECLARE @MLPName VarChar(100)
 	 
CREATE  TABLE #PropNames (Id Int Identity (1,1),Name varchar(100) COLLATE database_default ,VarId VarChar(10) COLLATE database_default)
SET @PropSel  = ''
SET @PropJOIN = ''
DECLARE @Counter Int
SET @Counter = 0
if (LEN(@MaterialProperties) > 0) 
BEGIN
 	 SET @Cmd = 'INSERT INTO #PropNames (Name) Values ' + @MaterialProperties
 	 EXEC (@Cmd)
 	 Update #PropNames Set VarId = CONVERT(varchar(10),Var_Id)
 	  	 FROM Variables v
 	  	 WHERE Var_Desc = Name and PU_Id = -100
 	 SELECT @End = MAX(id) - 1  from #PropNames
 	 IF @End > 10 SET @End = 10
 	 WHILE  @Counter <= @End
 	 BEGIN
 	  	 SET @PropName = 'P' + CONVERT(Varchar(4),@Counter)
 	  	 SELECT @Varid = VarId FROM #PropNames WHERE Id = @Counter +  1
 	  	 IF  @Varid Is Not Null
 	  	 BEGIN 
 	  	  	 SET @PropSel  = @PropSel  + ', ' + @PropName + '.Result as ' + @PropName
 	  	  	 SET @PropJOIN = @PropJOIN + ' LEFT JOIN Tests ' + @PropName + ' with( index(Tests_IDX_EventIdVarId)) on ' + @PropName + '.Var_Id = ' + @Varid + ' And ' + @PropName  + '.Event_Id = e.Event_Id' + CHAR(10)  
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SET @PropSel  = @PropSel  + ',P' + CONVERT(Varchar(4),@Counter) + '= Null'
 	  	 END
 	  	 SET @Counter = @Counter + 1
 	 END
END
if (LEN(@LotProperties) > 0) 
BEGIN
 	 SET @Cmd = 'INSERT INTO #PropNames (Name) Values ' + @LotProperties
 	 EXEC (@Cmd)
 	 SELECT @End = MAX(id) - 1  from #PropNames
 	 IF @End > 10 SET @End = 10
 	 WHILE  @Counter <= @End
 	 BEGIN
 	  	 SET @PropName = 'P' + CONVERT(Varchar(4),@Counter)
 	  	 SELECT @MLPName = Ltrim(Rtrim(Name)) FROM #PropNames WHERE Id = @Counter +  1
 	  	 SET @PropSel  = @PropSel  + ', ' + @PropName + '.Value as ' + @PropName
 	  	 SET @PropJOIN = @PropJOIN + ' LEFT JOIN MaterialLotProperty ' + @PropName + ' on ' + @PropName + '.MaterialLotId = l.MaterialLotId and ' + @PropName + '.Name = ''' + @MLPName + ''''
 	  	 SET @Counter = @Counter + 1
 	 END
END
if (LEN(@EquipmentProperties) > 0) 
BEGIN
 	 SET @Cmd = 'INSERT INTO #PropNames (Name) Values ' + @EquipmentProperties
 	 EXEC (@Cmd)
 	 SELECT @End = MAX(id) - 1  from #PropNames
 	 IF @End > 10 SET @End = 10
 	 WHILE  @Counter <= @End
 	 BEGIN
 	  	 SET @PropName = 'P' + CONVERT(Varchar(4),@Counter)
 	  	 SET @VarName = 'V' + CONVERT(Varchar(4),@Counter)
 	  	 SELECT @MLPName = Ltrim(Rtrim(Name)) FROM #PropNames WHERE Id = @Counter +  1
 	  	 SET @PropSel  = @PropSel  + ', ' + @PropName + '.Result as ' + @PropName
 	  	 SET @PropJOIN = @PropJOIN + ' LEFT JOIN Variables ' + @VarName + ' on ' + @VarName + '.Var_Desc = ''' + @MLPName + ''' And ' + @VarName  + '.PU_Id = e.PU_Id' + CHAR(10)  
 	  	 SET @PropJOIN = @PropJOIN + ' LEFT JOIN Tests ' + @PropName + ' with( index(Tests_IDX_EventIdVarId)) on ' + @PropName + '.Var_Id = ' + @VarName + '.Var_Id And ' + @PropName  + '.Event_Id = e.Event_Id' + CHAR(10)  
 	  	 SET @Counter = @Counter + 1
 	 END
END
BEGIN
 	 WHILE  @Counter  < 10
 	 BEGIN
 	  	 SET @PropSel  = @PropSel  + ',P' + CONVERT(Varchar(2),@Counter) + '= Null'
 	  	 SET @Counter = @Counter + 1
 	 END
END
drop table #PropNames
SET @Cmd = 'DECLARE @FoundRows int' + CHAR(10)
SET @Cmd = @Cmd + 'DECLARE @Level int'+ CHAR(10)
SET @Cmd = @Cmd + 'DECLARE @RootId int'+ CHAR(10)
SET @Cmd = @Cmd + 'DECLARE @LevelLimit int'+ CHAR(10)
SET @Cmd = @Cmd + 'SET @RootId = ' + STR(@RootId) +  CHAR(10)
SET @Cmd = @Cmd + 'SET @LevelLimit = ' + STR(@Levels) + CHAR(10)
SET @Cmd = @Cmd + 'INSERT INTO #Genealogy (Level, Parent_Event_Id, Event_Id, Start_Time, Timestamp)'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 SELECT 0 as level, ec.Source_Event_Id, e.Event_Id, ec.Start_Time, ec.Timestamp'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 FROM Events e'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN Event_Components ec with (index(Event_Components_IDX_Event)) on ec.Event_Id = e.Event_Id'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 WHERE e.Event_Id = @RootId'+ CHAR(10)
SET @Cmd = @Cmd + 'TRUNCATE TABLE #Genealogy2'+ CHAR(10)
IF @Direction = 1
BEGIN
 	 SET @Cmd = @Cmd + 'INSERT INTO #Genealogy2 (Event_Id) SELECT Event_Id FROM #Genealogy WHERE level = 0'+ CHAR(10)
END
ELSE
BEGIN
 	 SET @Cmd = @Cmd + 'INSERT INTO #Genealogy2 (Event_Id) SELECT Parent_Event_Id FROM #Genealogy WHERE level = 0'+ CHAR(10)
END
SET @Cmd = @Cmd + 'SELECT @FoundRows = @@RowCount'+ CHAR(10)
SET @Cmd = @Cmd + 'SET @Level = 1'+ CHAR(10)
SET @Cmd = @Cmd + 'WHILE (@FoundRows > 0 and @Level < 25 and @Level <= @LevelLimit)'+ CHAR(10)
SET @Cmd = @Cmd + 'BEGIN'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 INSERT INTO #Genealogy (Level, Parent_Event_Id, Event_Id, Start_Time, Timestamp)'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	  	 SELECT @Level, ec.Source_Event_Id, ec.Event_Id, ec.Start_Time, ec.Timestamp'+ CHAR(10)
IF @Direction = 1
BEGIN
 	 SET @Cmd = @Cmd + ' 	  	  	 FROM Event_Components ec with (index(Event_Components_IDX_Source))'+ CHAR(10)
 	 SET @Cmd = @Cmd + ' 	  	  	 JOIN #Genealogy2 g on ec.Source_Event_Id = g.Event_Id'+ CHAR(10)
END
ELSE
BEGIN
 	 SET @Cmd = @Cmd + ' 	  	  	 FROM Event_Components ec with (index(Event_Components_IDX_Event))'+ CHAR(10)
 	 SET @Cmd = @Cmd + ' 	  	  	 JOIN #Genealogy2 g on ec.Event_Id = g.Event_Id'+ CHAR(10)
END
SET @Cmd = @Cmd + ' 	  	 TRUNCATE TABLE #Genealogy2'+ CHAR(10)
IF @Direction = 1
BEGIN
 	 SET @Cmd = @Cmd + ' 	  	 INSERT INTO #Genealogy2 (Event_Id) SELECT Event_Id FROM #Genealogy WHERE level = @Level'+ CHAR(10)
END
ELSE
BEGIN
 	 SET @Cmd = @Cmd + ' 	  	 INSERT INTO #Genealogy2 (Event_Id) SELECT Parent_Event_Id FROM #Genealogy WHERE level = @Level'+ CHAR(10)
END
SET @Cmd = @Cmd + ' 	  	 SELECT @FoundRows = @@RowCount'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 SET @Level = @Level + 1'+ CHAR(10)
SET @Cmd = @Cmd + 'END'+ CHAR(10)
SET @Cmd = @Cmd + 'SELECT Level = g.level, ParentEventId = g.Parent_Event_Id,ParentMaterialLotId =  l1.MaterialLotId,ParentMaterialLotS95Id = l1.S95Id,ParentMaterialLotDescription = l1.Description,'+ CHAR(10)
SET @Cmd = @Cmd + 'EventId = g.Event_Id, ChildMaterialLotId =  l.MaterialLotId,ChildMaterialLotS95Id = l.S95Id,ChildMaterialLotDescription = l.Description,StartTime = g.Start_Time,EndTime = g.Timestamp, '+ CHAR(10)
SET @Cmd = @Cmd + 'MaterialLotStatus = l.Status,EventStatus = ps.ProdStatus_Desc,EventType = Event_Subtype_Desc,' + CHAR(10)
SET @Cmd = @Cmd + 'EventNum = e.Event_Num,FinalDimension = ed.Final_Dimension_X,MaterialDefinationS95Id = d.S95Id,MaterialDefinationDescription = d.Description, MaterialDefinationId = d.MaterialDefinitionId' + CHAR(10)
SET @Cmd = @Cmd +  @PropSel + CHAR(10)
SET @Cmd = @Cmd + ' 	  	 FROM #Genealogy g'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 JOIN Events e on e.Event_Id = g.Event_Id'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN Production_Status ps on ps.ProdStatus_Id = e.Event_Status'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN Event_Configuration ec on ec.pu_Id =  e.PU_Id and ec.ET_Id = 1'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN Event_Subtypes es on es.Event_Subtype_Id =  ec.Event_Subtype_Id'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN Event_Details ed on ed.Event_Id = e.Event_Id'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN Events_Xref_Lots xr on xr.EventId = e.Event_Id'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN Events_Xref_Lots xr1 on xr1.EventId = g.Parent_Event_Id'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN MaterialLot l on l.MaterialLotId = xr.LotId'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN MaterialLot l1 on l1.MaterialLotId = xr1.LotId'+ CHAR(10)
SET @Cmd = @Cmd + ' 	  	 LEFT JOIN MaterialDefinition d on d.MaterialDefinitionId = l.MaterialDefinitionId'+ CHAR(10)
SET @Cmd = @Cmd + @PropJOIN 
SET @Cmd = @Cmd + ' order by  g.level,g.Parent_Event_Id,g.Event_Id'
exec (@Cmd)
drop table #Genealogy
drop table #Genealogy2
