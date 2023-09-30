CREATE procedure [dbo].[spSDK_AU_AlarmTemplateVariableData]
@AppUserId int,
@Id int OUTPUT,
@AlarmTemplate varchar(100) ,
@AlarmTemplateId int ,
@AlarmTemplateSPCRuleDataId int ,
@AlarmTemplateVariableRuleDataId int ,
@CommentId int OUTPUT,
@CommentText text,
@EG varchar(100) ,
@EGId int ,
@ReasonTreeDataId int ,
@OverrideActionTree varchar(100) ,
@OverrideActionTreeId int ,
@OverrideCauseTree varchar(100) ,
@OverrideCauseTreeId int ,
@OverrideCustomText varchar(100) ,
@OverrideDefaultAction1 varchar(100) ,
@OverrideDefaultAction1Id int ,
@OverrideDefaultAction2 varchar(100) ,
@OverrideDefaultAction2Id int ,
@OverrideDefaultAction3 varchar(100) ,
@OverrideDefaultAction3Id int ,
@OverrideDefaultAction4 varchar(100) ,
@OverrideDefaultAction4Id int ,
@OverrideDefaultCause1 varchar(100) ,
@OverrideDefaultCause1Id int ,
@OverrideDefaultCause2 varchar(100) ,
@OverrideDefaultCause2Id int ,
@OverrideDefaultCause3 varchar(100) ,
@OverrideDefaultCause3Id int ,
@OverrideDefaultCause4 varchar(100) ,
@OverrideDefaultCause4Id int ,
@OverrideDQCriteria tinyint ,
@OverrideDQTag varchar(100) ,
@OverrideDQValue varchar(100) ,
@OverrideDQVarId int ,
@ProductionLine varchar(100) ,
@ProductionLineId int ,
@ProductionUnit varchar(100) ,
@ProductionUnitId int ,
@Variable varchar(100) ,
@VariableId int 
AS
Declare
  @Status int,
  @ErrorMsg varchar(500)
  Select @ErrorMsg = 'Object does not support Add/Update.' 
  Select @Status = 0
  -- Call to Import/Export SP goes here
  If (@Status <> 1)
    Select @ErrorMsg
  Return(@Status)
