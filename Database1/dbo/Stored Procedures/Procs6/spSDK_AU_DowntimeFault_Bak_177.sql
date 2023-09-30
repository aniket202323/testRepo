CREATE procedure [dbo].[spSDK_AU_DowntimeFault_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@Department varchar(100) ,
@DepartmentId int ,
@DowntimeFault varchar(100) ,
@ProductionLine varchar(100) ,
@ProductionLineId int ,
@ProductionUnit varchar(100) ,
@ProductionUnitId int ,
@ReasonLevel1Id int ,
@ReasonLevel1Name varchar(100) ,
@ReasonLevel2Id int ,
@ReasonLevel2Name varchar(100) ,
@ReasonLevel3Id int ,
@ReasonLevel3Name varchar(100) ,
@ReasonLevel4Id int ,
@ReasonLevel4Name varchar(100) ,
@ReasonTreeDataId int ,
@SourceDepartment varchar(100) ,
@SourceDepartmentId int ,
@SourceProductionLine varchar(100) ,
@SourceProductionLineId int ,
@SourceProductionUnit varchar(100) ,
@SourceProductionUnitId int ,
@Value varchar(100) 
AS
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT
 	  	  	  	 
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @SourceDepartment 	 OUTPUT,
 	  	  	  	 @SourceDepartmentId OUTPUT, 	 
 	  	  	  	 @SourceProductionLine OUTPUT, 	 
 	  	  	  	 @SourceProductionLineId OUTPUT,
 	  	  	  	 @SourceProductionUnit OUTPUT,
 	  	  	  	 @SourceProductionUnitId OUTPUT
DECLARE @OldPuDesc VarChar(100)
DECLARE @OldFault 	  VarChar(100)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @Sql Varchar(1000)
IF @Id is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Timed_Event_Fault a WHERE TEFault_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Timed event fault not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldPuDesc = PU_Desc,@OldFault = a.TEFault_Name
 	  	 FROM Timed_Event_Fault a 
 	  	 JOIN Prod_Units_Base b ON b.PU_Id = a.PU_Id 
 	  	 WHERE a.TEFault_Id = @Id
 	 IF @OldPuDesc <> @ProductionUnit
 	 BEGIN
 	  	 SELECT 'Changing of the Production Unit is not supported'
 	  	 RETURN(-100)
 	 END
 	 IF @OldFault <> @DowntimeFault
 	 BEGIN
 	  	 If Exists (select * from dbo.syscolumns where name = 'TEFault_Name_Local' and id =  object_id(N'[Timed_Event_Fault]'))
 	  	  	 Select @Sql = 'UPDATE Timed_Event_Fault SET TEFault_Name_Local = ''' + @DowntimeFault + ''''
    Else
 	  	  	 Select @Sql = 'UPDATE Timed_Event_Fault SET TEFault_Name = ''' + @DowntimeFault + ''''
 	  	 Select @Sql = @Sql + ' WHERE TEFault_Id = ' + Convert(varchar(10),@Id)
 	  	 Execute (@Sql)
 	  	 Return(1)
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Timed_Event_Fault a WHERE TEFault_Name = @DowntimeFault and Source_PU_Id = @SourceProductionUnitId )
 	 BEGIN
 	  	 SELECT 'Timed event fault already exists add not allowed'
 	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportTimedEventFault @ProductionLine,@ProductionUnit,@Value,@DowntimeFault,@SourceProductionUnit,
 	  	  	  	  	  	 @ReasonLevel1Name,@ReasonLevel2Name,@ReasonLevel3Name,@ReasonLevel4Name,0,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
SELECT @Id = TEFault_Id 
 	 FROM Timed_Event_Fault a
 	 WHERE a.PU_Id = @ProductionUnitId and TEFault_Name = @DowntimeFault
IF @Id IS NULL
BEGIN
 	 SELECT 'Create Fault failed'
 	 RETURN(-100)
END
 	  	  	  	  	 
Return(1)
