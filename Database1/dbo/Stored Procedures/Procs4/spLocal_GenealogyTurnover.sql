      /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-31  
Version  : 1.0.1  
Purpose  : Removed useless code and commented code.  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
  
CREATE procedure dbo.spLocal_GenealogyTurnover  
@Success Int  Output,  
@ErrMsg VarChar(255) Output,  
@ECId  Int,  
@TableName VarChar(255),  
@Id  Int   
AS  
  
SET NOCOUNT ON  
  
Declare  
  
  @SourceId  Int,  
  @EventStatus  Int  
  
  
Select @ErrMsg = @TableName  
Select @Success = 0  
  
If @TableName = 'PrdExec_Input_Event'   
     Begin  
     Select @ErrMsg = ''  
     Select @Success = 1  
     End  
Else If  @TableName = 'PrdExec_Input_Event_History'  
     Begin  
  
     Select @ErrMsg = ''  
     Select @Success = 1  
     End  
Else If  @TableName = 'Events'  
     Begin  
  
     Select @SourceId = Source_Event, @EventStatus = Event_Status  
     From [dbo].Events  
     Where Event_Id = @Id  
  
     /* Link To Source */  
     If (@SourceId is Not Null) And ((Select Source_Event_Id From [dbo].Event_Components Where Event_Id = @Id) Is Null)  
          Begin  
  
          -- Refresh parent and child events  
          Exec spServer_CmnAddScheduledTask @Id, 1  
          Exec spServer_CmnAddScheduledTask @SourceId, 1  
  
          End  
  
     Select @ErrMsg = ''  
     Select @Success = 1  
  
     End  
  
SET NOCOUNT OFF  
  
  
  
