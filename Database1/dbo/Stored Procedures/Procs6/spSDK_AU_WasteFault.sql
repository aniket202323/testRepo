CREATE procedure [dbo].[spSDK_AU_WasteFault]
 	 @AppUserId int,
 	 @Id int OUTPUT,
 	 @Department varchar(100) ,
 	 @DepartmentId int,
 	 @ProductionLine varchar(100)  ,
 	 @ProductionLineId int ,
 	 @ProductionUnit varchar(100)  ,
 	 @ProductionUnitId int ,
 	 @ReasonLevel1 varchar(100) ,
 	 @ReasonLevel1Id int ,
 	 @ReasonLevel2 varchar(100) ,
 	 @ReasonLevel2Id int ,
 	 @ReasonLevel3 varchar(100) ,
 	 @ReasonLevel3Id int ,
 	 @ReasonLevel4 varchar(100) ,
 	 @ReasonLevel4Id int ,
 	 @SourceDepartment varchar(100) ,
 	 @SourceDepartmentId int,
 	 @SourceProductionLine varchar(100)  ,
 	 @SourceProductionLineId int ,
 	 @SourceProductionUnit varchar(100)  ,
 	 @SourceProductionUnitId int ,
 	 @Value varchar(100) ,
 	 @WasteFault varchar(100) 
AS
DECLARE @OldPuDesc VarChar(100)
DECLARE @OldFault 	  VarChar(100)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @Sql Varchar(1000)
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId  OUTPUT
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @SourceDepartment 	 OUTPUT,
 	  	  	  	 @SourceDepartmentId OUTPUT, 	 
 	  	  	  	 @SourceProductionLine OUTPUT, 	 
 	  	  	  	 @SourceProductionLineId OUTPUT,
 	  	  	  	 @SourceProductionUnit OUTPUT,
 	  	  	  	 @SourceProductionUnitId  OUTPUT
IF @SourceProductionUnitId IS Null
BEGIN
 	 SELECT 'Waste event fault Location not found'
 	 RETURN(-100)
END
IF @Id is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Waste_Event_Fault WHERE WEFault_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Waste event fault not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldPuDesc = PU_Desc,@OldFault = a.WEFault_Name 
 	  	 FROM Waste_Event_Fault a 
 	  	 JOIN Prod_Units_Base b ON b.PU_Id = a.PU_Id 
 	  	 WHERE a.WEFault_Id = @Id
 	 IF @OldPuDesc <> @ProductionUnit
 	 BEGIN
 	  	 SELECT 'Changing of the Production Unit is not supported'
 	  	 RETURN(-100)
 	 END
 	 IF @OldFault <> @WasteFault
 	 BEGIN
 	  	 If Exists (select * from dbo.syscolumns where name = 'WEFault_Name_Local' and id =  object_id(N'[Waste_Event_Fault]'))
 	  	  	 Select @Sql = 'UPDATE Waste_Event_Fault SET WEFault_Name_Local = ''' + @WasteFault + ''''
    Else
 	  	  	 Select @Sql = 'UPDATE Waste_Event_Fault SET WEFault_Name = ''' + @WasteFault + ''''
 	  	 Select @Sql = @Sql + ' WHERE WEFault_Id = ' + Convert(varchar(10),@Id)
 	  	 Execute (@Sql)
 	 END
END
ELSE
BEGIN
 	 IF EXISTS(Select 1 From Waste_Event_Fault a WHERE a.Source_PU_Id = @SourceProductionUnitId and a.WEFault_Name = @WasteFault)
 	 BEGIN
 	  	 SELECT 'Fault Value Already Exists - Add Failed'
 	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportWasteEventFault @ProductionLine,@ProductionUnit,@Value,@WasteFault,@SourceProductionUnit,
 	  	  	  	  	 @ReasonLevel1,@ReasonLevel2,@ReasonLevel3,@ReasonLevel4,0,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
SELECT @Id = WEFault_Id 
 	 FROM Waste_Event_Fault a
 	 WHERE a.PU_Id = @ProductionUnitId and WEFault_Name = @WasteFault
IF @Id IS NULL
BEGIN
 	 SELECT 'Create Fault failed'
 	 RETURN(-100)
END
Return(1)
