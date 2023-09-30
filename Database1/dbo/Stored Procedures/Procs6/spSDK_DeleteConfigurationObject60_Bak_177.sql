CREATE procedure [dbo].[spSDK_DeleteConfigurationObject60_Bak_177]
 	 @Objectname varchar(100),
 	 @KeyValue varchar(100),
 	 @UserId int,
 	 @ErrorMsg varchar(1000) output
AS
-- Attention: if code is added or removed from this sp for a particular object
--            the ExposeDeleteMethod column in the SDK Access Database (Table:Objects) will 
--            need to be updated for that object
 	  	  	  	  	  	  	 
-- Retuns
-- < 0  unsuccessful
-- >= 0 Success
DECLARE @Id Int,@RC int
Select @ErrorMsg = @Objectname + ' does not currently support delete.'
IF isnumeric(@KeyValue) = 1
 	 SET  @Id = Convert(int,@KeyValue)
IF (@Objectname = 'PABOM')
BEGIN
 	 EXECUTE spEM_BOMSave Null,Null,Null,Null,'',@Id
 	 RETURN(0) 
END
ELSE IF (@Objectname = 'PABOMFamily') 
BEGIN
 	 IF Exists(SELECT 1 FROM Bill_Of_Material  WHERE BOM_Family_Id  = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PABOMFamily - PABOM are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE spEM_BOMSaveFamily 	 Null,Null,'',@Id
 	  	 RETURN(0)
 	 END
END
ELSE IF (@Objectname = 'PABOMFormulation')
BEGIN
 	 EXECUTE spEM_BOMSaveFormulation 	 Null,Null,Null,Null,Null,Null,Null,Null,Null,'',@Id
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PABOMFormulationItem')
BEGIN
 	 EXECUTE spEM_BOMSaveFormulationItem 	 @UserId,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,@Id
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PABOMProduct')
BEGIN
 	 DELETE FROM 
 	  	 Bill_Of_Material_Product 
 	 WHERE
 	  	 BOM_Product_Id=@Id
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PABOMStarts')
BEGIN
 	 RETURN(-1)
END
ELSE IF (@Objectname = 'PABOMSubstitution')
BEGIN
 	 EXECUTE spEM_BOMSaveSubstitution 	 Null,Null,Null,Null,Null,@Id
 	 RETURN(0) 
END
ELSE IF (@Objectname = 'PACentralSpecification')
BEGIN
 	 RETURN(-1)
END
ELSE IF (@Objectname = 'PACharacteristic')
BEGIN
 	 EXECUTE 	 spEM_DropChar  @Id, @UserId
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PACharacteristicAssignment')
BEGIN
 	 RETURN(-1)
END
ELSE IF (@Objectname = 'PAComment')
BEGIN 
 	 DELETE FROM Comments Where TopOfChain_Id = @Id 
 	 DELETE FROM Comments Where Comment_Id = @Id 
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PACommentAttachment')
BEGIN
 	 DELETE FROM comment_attachments Where att_id = @Id 
END
ELSE IF (@Objectname = 'PACommentSource')
BEGIN
 	 RETURN(-1)
END
ELSE IF (@Objectname = 'PACrew')
BEGIN
 	 EXECUTE 	 spEMCSC_PutCrewSched 1,@UserId,Null,Null,Null,Null,Null,Null,@Id
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PACustomer')
BEGIN
 	 IF Exists(SELECT 1 FROM Customer_Orders WHERE Customer_Id  = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PACustomer - PACustomerOrder are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE 	 spEMCU_DeleteCustomer @Id,@UserId
 	  	 RETURN(0)
 	 END
END
ELSE IF (@Objectname = 'PACustomerOrder')
BEGIN
 	 EXECUTE 	 spEMCO_DeleteOrder @ID,@UserId
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PACustomerOrderLine')
BEGIN
 	 EXECUTE 	 spEMCO_DeleteLineItem @Id, @UserId
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PACustomerOrderLineSpec')
BEGIN
 	 EXECUTE 	 spEMCO_DeleteLineSpec @Id, @UserId
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PADataSource')
BEGIN
 	 IF @Id <= 50000
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete system data sources'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 IF Exists(SELECT 1 from Variables_Base as Variables  WHERE DS_Id = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PADataSource - PAVariables are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE 	 spEM_DropDataSource @Id, @UserId
 	  	 RETURN(0)
 	 END
END
ELSE IF (@Objectname = 'PADataType')
BEGIN
 	 IF @Id <= 50
 	 Begin
 	  	 SET @ErrorMsg = 'Can not delete system data type'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 IF Exists(SELECT 1 from Variables_Base as Variables  WHERE Data_Type_Id = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PADataType - PAVariables are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE 	 spEM_DropDataType @Id, @UserId
 	  	 RETURN(0)
 	 END
END
ELSE IF (@Objectname = 'PADataTypePhrase')
BEGIN
 	 EXECUTE 	 spEM_DropPhrase @Id, @UserId
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PADepartment')
BEGIN
 	 IF Exists(SELECT 1 FROM Prod_Lines_Base WHERE Dept_Id = @Id)
 	 Begin
 	  	 SET @ErrorMsg = 'Can not delete PADepartment - PAProductionLine are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	 EXECUTE 	 spEM_DropDepartment @Id, @UserId
 	  	 RETURN(0)
 	 END
END
ELSE IF (@Objectname = 'PADowntimeStatus')
BEGIN
 	 EXECUTE 	 spEMSEC_PutTimedEventStatus  Null,Null,Null,@UserId,@Id
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PAEngineeringUnit')
BEGIN
 	 IF @Id <= 50000
 	 Begin
 	  	 SET @ErrorMsg = 'Can not delete system engineering units'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE 	 @RC = spEM_EUDropEU @Id, @UserId
 	  	 IF @RC = -100
 	  	 BEGIN
 	  	  	 SET @ErrorMsg = 'Can not delete engineering unit in use'
 	  	  	 RETURN (-1)
 	  	 END
 	  	 RETURN(0)
 	 END
END
ELSE IF (@Objectname = 'PAESignature')
BEGIN
 	 RETURN(-1)
END
ELSE IF (@Objectname = 'PAEventConfiguration')
BEGIN
 	 EXECUTE 	 spEMEC_DELETEEC  @Id,2,@UserId,Null
 	 RETURN(0)
END
ELSE IF (@Objectname = 'PAEventSubType')
BEGIN
 	 EXECUTE spEMEC_DeleteEventSubtype @Id,2,@UserId
END
ELSE IF (@Objectname = 'PAEventType')
BEGIN
 	 RETURN (-1)
END
ELSE IF (@Objectname = 'PAParameter')
BEGIN
 	 RETURN (-1)
END
ELSE IF (@Objectname = 'PAPath')
BEGIN
 	 EXECUTE spEMEPC_PutExecPaths Null,Null,Null,Null,Null,Null,Null,@UserId,@Id
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAPathInput')
BEGIN
 	 EXECUTE spEMEPC_PutPathInputs Null,Null,Null,Null,Null,Null,Null,Null,@UserId,@Id
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAPathProductAssignment')
BEGIN
 	 EXECUTE spEMEPC_PutPathProducts Null,Null,@UserId,@Id
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAProduct')
BEGIN
 	 RETURN (-1)
 	 --EXECUTE spEM_DropProd  @Id,@UserId
 	 --RETURN (0)
END
ELSE IF (@Objectname = 'PAProductAssignment')
BEGIN
 	 RETURN (-1)
END
ELSE IF (@Objectname = 'PAProductFamily')
BEGIN
 	 If @Id = 1
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete default family'
 	  	 Return(-1)
 	 END
 	 EXECUTE  spEM_DropProductFamily  @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAProductionLine')
BEGIN
 	 If @Id = 0
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete the [0] Production Line'
 	  	 Return(-1)
 	 END
 	 IF Exists(SELECT 1 FROM Prod_Units_Base WHERE PL_Id = @Id)
 	 Begin
 	  	 SET @ErrorMsg = 'Can not delete PAProductionLine - PAProductionUnits are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE spEM_DropLine @Id,@UserId
 	  	 RETURN (0)
 	 END
END
ELSE IF (@Objectname = 'PAProductionSetupDetail')
BEGIN
 	 EXECUTE spSV_PutPattern 3,Null,@Id,Null,Null,Null,Null,Null,Null,Null,Null,Null,@UserId,Null
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAProductionStatus')
BEGIN
 	 RETURN (-1)
END
ELSE IF (@Objectname = 'PAProductionUnit')
BEGIN
 	 If @Id < 0
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete system units'
 	  	 Return(-1)
 	 END
 	 IF Exists(SELECT 1 FROM PU_Groups  WHERE PU_Id = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PAProductionUnit - PAVariableGroup are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE spEM_DropUnit @Id,@UserId
 	  	 RETURN (0)
 	 END
END
ELSE IF (@Objectname = 'PAProductProperty')
BEGIN
 	 IF Exists(SELECT 1 FROM Specifications  WHERE Prop_Id  = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PAProductProperty - PAPropertySpecification are still attached'
 	  	 RETURN (-1)
 	 END
 	 IF Exists(SELECT 1 FROM Characteristics  WHERE Prop_Id  = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PAProductProperty - PACharacteristic are still attached'
 	  	 RETURN (-1)
 	 END
 	 EXECUTE spEM_DropProp @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAPropertySpecification')
BEGIN
 	 EXECUTE spEM_DropSpec @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAPropertyType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAReason')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAReasonTree')
BEGIN
 	 EXECUTE spEM_DropReasonTree @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAReasonTreeAssignment')
BEGIN
 	 RETURN(-1)
END
ELSE IF (@Objectname = 'PAReasonTreeData')
BEGIN
 	 EXECUTE spEM_DropEventReasonTreeData @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PASecurityGroup')
BEGIN
 	 If @Id in(-1, 1)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete default Security groups'
 	  	 Return(-1)
 	 END
 	 EXECUTE spEM_DropUserGroup @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PASecurityGroupMember')
BEGIN
 	 If @Id = @UserId
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete your own security'
 	  	 Return(-1)
 	 END
 	 EXECUTE spEM_DropUserSecurity @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PASiteParameterValue')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAUnitLocation')
BEGIN 
 	 EXECUTE spEMUP_PutUnitLocations @Id,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,@UserId,Null
 	 RETURN(0) 
END
ELSE IF (@Objectname = 'PAUnitSpecification')
BEGIN 
 	 RETURN(-1)
END
ELSE IF (@Objectname = 'PAUser')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAUserParameterValue')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAVariable')
BEGIN 
 	 EXECUTE spEM_DropVariable @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAVariableGroup')
BEGIN 
 	 IF Exists(SELECT 1 from Variables_Base as Variables WHERE PUG_Id  = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PAVariableGroup - PAVariables are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE spEM_DropGroup @Id,@UserId
 	  	 RETURN (0)
 	 END
END
ELSE IF (@Objectname = 'PAWasteMeasurement')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAWasteType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAAlarmPriority')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAAlarmSPCRule')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAAlarmTemplate')
BEGIN 
 	 EXECUTE spEMAC_DeleteAT @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAAlarmTemplateSPCRuleData')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAAlarmTemplateVariableData')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAAlarmTemplateVariableRuleData')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAAlarmType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PACalculation')
BEGIN 
 	 IF Exists(SELECT 1 from Variables_Base as Variables  WHERE Calculation_Id  = @Id)
 	 BEGIN
 	  	 SET @ErrorMsg = 'Can not delete PACalculation - PAVariables are still attached'
 	  	 RETURN (-1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE spEMCC_ByCalcIDUpdate 29,@Id,@UserId
 	  	 RETURN (0)
 	 END
END
ELSE IF (@Objectname = 'PAParameterCategory')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAColor')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAControlType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PACustomerType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PADowntimeFault')
BEGIN 
 	 EXECUTE spEM_PutTimedEventFault Null,@Id,Null,Null,Null,Null,Null,Null,Null,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAFieldType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAModel')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAParameterType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAPathInputPosition')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAProductionPlanStatus')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAProductionPlanType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAResearchStatus')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAShipment')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PASpecificationType')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PATestingStatus')
BEGIN 
 	 RETURN(-1) 
END
ELSE IF (@Objectname = 'PAWasteFault')
BEGIN 
 	 EXECUTE spEM_PutWasteEventFault  Null,@Id,Null,Null,Null,Null,Null,Null,Null,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAReasonCategory')
BEGIN 
 	 EXECUTE spEM_DropReasonCategory  @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAReasonCategoryData')
BEGIN 
 	 EXECUTE spEM_DropCategoryData @Id,@UserId
 	 RETURN (0)
END
ELSE IF (@Objectname = 'PAPathStatusTransition')
BEGIN 
 	 DELETE FROM Production_Plan_Status WHERE PPS_Id = @Id
 	 RETURN (0)
END
RETURN(-1)
