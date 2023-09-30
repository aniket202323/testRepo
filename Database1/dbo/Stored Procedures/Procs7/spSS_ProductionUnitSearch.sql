Create Procedure dbo.spSS_ProductionUnitSearch
 @ProductionLine int = NULL,
 @ProductionUnitString nVarChar(100),
 @EventSubtypeId int,
 @EquipmentTypeNotNull int = NULL,
 @NPUnitsOnly int = NULL,
 @Product int=NULL
AS
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @FlgFirst int
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @SQLCOnd0 = NULL
If @ProductionLine = 0 Select @ProductionLine = Null
If @EventSubtypeId = 0 Select @EventSubtypeId = Null
If @EquipmentTypeNotNull = 0 Select @EquipmentTypeNotNull = Null
If @NPUnitsOnly = 0 Select @NPUnitsOnly = Null
-- Any modification to this select statement should also be done on the #alarm table
  Select @SQLCommand = 'Select PU.PU_Id, PU.PU_Desc, PU.Equipment_Type, PU.Group_Id, PU.PL_Id, PU.Non_Productive_Reason_Tree ' + 
                       'From Prod_Units PU ' + 
                       'Join Prod_Lines PL on PL.PL_Id = PU.PL_Id '
-- ECR #29378 Move Where clause to after Join clause for @EventSubtypeId 
                       --'Where PU.PU_Id > 0' 	  	       
if @Product is not null and @Product<>0
 	 set @SQLCommand=@SQLCommand+'join PU_Products pup on PU.PU_Id=pup.PU_Id'
--------------------------------------------------------------------
-- Event Subtype Id (Join only)
--------------------------------------------------------------------
 If (@EventSubtypeId is Not NULL and @EventSubtypeId <> 0)
  Begin
   Select @SQLCond0 = "Join Event_Configuration EC on EC.PU_Id = PU.PU_Id "
   Select @SQLCommand =  @SQLCommand + @SQLCond0
  End
-- ECR #29378
Select @SQLCommand =  @SQLCommand + ' Where PU.PU_Id > 0 '
if @Product is not null and @Product<>0
 	 set @SQLCommand=@SQLCommand+'and pup.Prod_Id='+cast(@Product as varchar)
 	 
--------------------------------------------------------------------
-- Production Line
--------------------------------------------------------------------
 If (@ProductionLine Is Not NULL and @ProductionLine <> 0)
  Begin
   Select @SQLCond0 = "PL.PL_Id =" + Convert(nVarChar(05),@ProductionLine)  
   Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')'
  End
-------------------------------------------------------------------
-- PU Description
-----------------------------------------------------------------------
 If (@ProductionUnitString Is Not Null and Len(@ProductionUnitString)>0)
  Begin
   Select @SQLCond0 = "PU.PU_Desc Like '%" + @ProductionUnitString + "%'"
   Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                    
  End
-------------------------------------------------------------------
-- Equipment Type not null
-----------------------------------------------------------------------
 If (@EquipmentTypeNotNull Is Not Null and Len(@EquipmentTypeNotNull)>0)
  Begin
   Select @SQLCond0 = "PU.Equipment_Type is not NULL"
   Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')'
  End  
--------------------------------------------------------------------
-- Event Subtype Id (Where clause only)
--------------------------------------------------------------------
 If (@EventSubtypeId is Not NULL and @EventSubtypeId <> 0)
  Begin
   Select @SQLCond0 = "EC.Event_Subtype_Id =" + Convert(nVarChar(05), @EventSubtypeId)
   Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')'
   End
--------------------------------------------------------------------
-- NP Units only (Where clause only)
--------------------------------------------------------------------
 If (@NPUnitsOnly is Not NULL)
  Begin
   Select @SQLCond0 = "PU.Non_Productive_Category = 7 and PU.Non_Productive_Reason_Tree is not Null"
   Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')'
   End
--select Command = @SQLCommand
----------------------------------------------------------------
--  Output partial result to a temp table
-----------------------------------------------------------------
 Create Table #UnitTemp (
  PU_Id Int NULL,
  PU_Desc nVarChar(50) Null,
  Equipment_Type nVarChar(50) Null,
  Group_Id Int NULL,
  PL_Id Int NULL,
  Non_Productive_Reason_Tree Int NULL
 )
 Select @SQLCommand = 'Insert Into #UnitTemp ' + @SQLCommand 
 Exec (@SQLCommand)
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
 Select Distinct PU_Desc as 'Unit Desc', PU_Id as 'Unit Id', Equipment_Type as 'Equipment Type', Tree_Name as 'Tree Name',
        #UnitTemp.Group_Id as 'Group Id', PL_Id as 'PL Id', Non_Productive_Reason_Tree as 'Non Productive Reason Tree'
   From #UnitTemp
    Left Outer Join Event_Reason_Tree er on er.Tree_Name_Id = Non_Productive_Reason_Tree
    Order By PU_Desc
 Drop Table #UnitTemp
