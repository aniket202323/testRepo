CREATE procedure [dbo].[spSDK_AU_Calculation_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@Calculation varchar(100) ,
@CalculationDescription varchar(100) ,
@CalculationType varchar(100) ,
@CalculationTypeId int ,
@CommentId int OUTPUT,
@CommentText text,
@Equation varchar(100) ,
@LagTime int ,
@Locked bit ,
@MaxRunTime int ,
@OptimizeCalcRuns bit ,
@Script text ,
@StoredProcedureName varchar(100) ,
@SystemCalculation int ,
@TriggerType varchar(100) ,
@TriggerTypeId int ,
@Version varchar(100) 
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
