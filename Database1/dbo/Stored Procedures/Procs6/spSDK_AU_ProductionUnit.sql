CREATE procedure [dbo].[spSDK_AU_ProductionUnit]
@AppUserId int,
@Id int OUTPUT,
@ChainStartTime tinyint ,
@CommentId int OUTPUT,
@CommentText text ,
@DefaultPath varchar(100) ,
@DefaultPathId int ,
@DefEventSheetId int ,
@DefMeasurement int ,
@DefProductionDest int ,
@DefProductionSrc int ,
@DeleteChildEvents bit ,
@Department varchar(200) ,
@DepartmentId int ,
@DowntimeExternalCategory varchar(100) ,
@DowntimeExternalCategoryId int ,
@DowntimePercentAlarmInterval int ,
@DowntimePercentAlarmWindow int ,
@DowntimePercentSpecification varchar(100) ,
@DowntimePercentSpecificationId int ,
@DowntimeScheduledCategory varchar(100) ,
@DowntimeScheduledCategoryId int ,
@EfficiencyCalculationType tinyint ,
@EfficiencyPercentAlarmInterval int ,
@EfficiencyPercentAlarmWindow int ,
@EfficiencyPercentSpecification varchar(100) ,
@EfficiencyPercentSpecificationId int ,
@EfficiencyVariable varchar(100) ,
@EfficiencyVariableId int ,
@EquipmentType varchar(100) ,
@ExtendedInfo varchar(255) ,
@ExternalLink varchar(100) ,
@MasterUnit nvarchar(50) ,
@MasterUnitId int ,
@NonProductiveCategory varchar(100) ,
@NonProductiveCategoryId int ,
@NonProductiveReasonTree varchar(100) ,
@NonProductiveReasonTreeId int ,
@PerformanceDowntimeCategory int ,
@ProductionAlarmInterval int ,
@ProductionAlarmWindow int ,
@ProductionEventAssociation varchar(100) ,
@ProductionEventAssociationId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionRateSpecification varchar(100) ,
@ProductionRateSpecificationId int ,
@ProductionRateTimeUnits tinyint ,
@ProductionType tinyint ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitOrder tinyint ,
@ProductionVariable varchar(100) ,
@ProductionVariableId int ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int ,
@Sheet varchar(100) ,
@SheetId int ,
@Tag varchar(100) ,
@TimedEventAssociation tinyint ,
@UnitType varchar(100) ,
@UnitTypeId int ,
@UserDefined1 varchar(100) ,
@UserDefined2 varchar(100) ,
@UserDefined3 varchar(100) ,
@UsesStartTime tinyint ,
@WasteEventAssociation tinyint ,
@WastePercentAlarmInterval int ,
@WastePercentAlarmWindow int ,
@WastePercentSpecification varchar(100) ,
@WastePercentSpecificationId int 
AS
DECLARE 
 	  	  	  	 @MyComment 	  	  	  	 Varchar(1000),
 	  	  	  	 @CurrentCommentId 	 Int,
 	  	  	  	 @OldDesc 	  	  	  	  	 VarChar(50)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @Id OUTPUT
If (@UnitTypeId Is NULL) And (NOT(@UnitType Is NULL))
 	 Select @UnitTypeId = Unit_Type_Id From Unit_Types Where UT_Desc = @UnitType
 	 
If (@Department Is NULL)
 	 Begin
 	  	 SELECT 'Incomplete Information, Department not found.'
 	  	 RETURN(-100) 	  	  	 
 	 End
/* @ProductionUnitOrder not supported (need to sync all units if changed) */
IF @Id is Not Null
BEGIN
 	 IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @Id)
 	 BEGIN
 	  	  	 SELECT 'Production Unit Not Found For Update'
 	  	  	 RETURN(-100) 	  	  	 
 	 END
 	 SELECT @OldDesc = PU_Desc 
 	  	 FROM Prod_Units_Base  a
 	  	 WHERE Pu_Id = @Id 
 	 IF @OldDesc <> @ProductionUnit
 	 BEGIN
 	  	  	 SELECT 'Changing the description field of an aspected equipment is not supported'
 	  	  	 RETURN(-100) 	  	  	 
 	 END
END
ELSE
BEGIN
 	 IF EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PL_Id = @ProductionLineId and PU_Desc = @ProductionUnit)
 	 BEGIN
 	  	  	 SELECT 'Production Unit already exists - Add Failed'
 	  	  	 RETURN(-100) 	  	  	 
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportUnits
 	  	  	  	  	  	  	  	  	  	  	  	 @Department,@ProductionLine,@ProductionUnit,@MasterUnit,
 	  	  	  	  	  	  	  	  	  	  	  	 @ExternalLink,@SecurityGroup,@ExtendedInfo,@UsesStartTime,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
DECLARE @DefPath 	  	  	 VarChar(100),
 	  	  	  	 @DwnPropSpec 	 VarChar(250),
 	  	  	  	 @EffLine 	  	  	 VarChar(100),
 	  	  	  	 @EffUnit 	  	  	 VarChar(100),
 	  	  	  	 @EffPropSpec 	 VarChar(250),
 	  	  	  	 @PerfDowntimeCategory VarChar(100),
 	  	  	  	 @ProdPropSpec VarChar(250),
 	  	  	  	 @WstPropSpec 	 VarChar(250)
 	  	  	  	 
SELECT @DefPath = Path_Code FROM PrdExec_Paths WHERE Path_Id = @DefaultPathId
SELECT @PerfDowntimeCategory = ERC_Desc FROM Event_Reason_Catagories WHERE ERC_Id = @PerformanceDowntimeCategory
SELECT @DwnPropSpec = Prop_Desc + '/' + a.Spec_Desc
 	 FROM Specifications a
 	 JOIN Product_Properties b ON b.Prop_Id = a.Prop_Id 
 	 WHERE a.Spec_Id =  @DowntimePercentSpecificationId
SELECT @EffPropSpec = Prop_Desc + '/' + a.Spec_Desc
 	 FROM Specifications a
 	 JOIN Product_Properties b ON b.Prop_Id = a.Prop_Id 
 	 WHERE a.Spec_Id =  @EfficiencyPercentSpecificationId
SELECT @ProdPropSpec = Prop_Desc + '/' + a.Spec_Desc
 	 FROM Specifications a
 	 JOIN Product_Properties b ON b.Prop_Id = a.Prop_Id 
 	 WHERE a.Spec_Id =  @ProductionRateSpecificationId
SELECT @WstPropSpec = Prop_Desc + '/' + a.Spec_Desc
 	 FROM Specifications a
 	 JOIN Product_Properties b ON b.Prop_Id = a.Prop_Id
 	 WHERE a.Spec_Id =  @WastePercentSpecificationId
 	 
SELECT @EffLine = PL_Desc,@EffUnit = PU_Desc
 	 from Variables_Base as a
 	 Join Prod_Units_Base b ON b.PU_Id = a.PU_Id 
 	 JOIN Prod_Lines_Base c ON c.PL_Id = b.PL_Id
 	 WHERE Var_Id = @EfficiencyVariableId 	 
 	 
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportUnitProperties
 	  	  	  	  	  	  	  	 @ProductionLine,@ProductionUnit,@DeleteChildEvents,@UnitType,@EquipmentType,
 	  	  	  	  	  	  	  	 @Sheet,@DefPath,@DowntimeScheduledCategory,@DowntimeExternalCategory,@DwnPropSpec,
 	  	  	  	  	  	  	  	 @DowntimePercentAlarmInterval,@DowntimePercentAlarmWindow,@EffLine,@EffUnit,@EfficiencyVariable,
 	  	  	  	  	  	  	  	 @EffPropSpec,@EfficiencyPercentAlarmInterval,@EfficiencyPercentAlarmWindow,@ProductionLine,@ProductionUnit,
 	  	  	  	  	  	  	  	 @ProductionVariable,@PerfDowntimeCategory,@ProdPropSpec,@ProductionRateTimeUnits,@ProductionAlarmInterval,
 	  	  	  	  	  	  	  	 @ProductionAlarmWindow,@WstPropSpec,@WastePercentAlarmInterval,@WastePercentAlarmWindow,@NonProductiveCategory,
 	  	  	  	  	  	  	  	 @NonProductiveReasonTree,@ChainStartTime,@TimedEventAssociation,@WasteEventAssociation,@UsesStartTime,
 	  	  	  	  	  	  	  	 @AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id is null
BEGIN
 	 SELECT @Id = a.PU_Id,@CurrentCommentId = Comment_Id
 	  	 FROM Prod_Units_Base  a
 	  	 WHERE PU_Desc = @ProductionUnit and a.PL_Id = @ProductionLineId
END
UPDATE Prod_Units_Base SET Def_Measurement = @DefMeasurement,
 	  	  	  	  	  	  	  	  	  	  	 User_Defined1 = @UserDefined1,
 	  	  	  	  	  	  	  	  	  	  	 User_Defined2 = @UserDefined2,
 	  	  	  	  	  	  	  	  	  	  	 User_Defined3 = @UserDefined3,
 	  	  	  	  	  	  	  	  	  	  	 Def_Event_Sheet_Id = @DefEventSheetId,
 	  	  	  	  	  	  	  	  	  	  	 Production_Event_Association = @ProductionEventAssociationId 
 	 WHERE PU_Id = @Id
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'ae',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'ae',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
