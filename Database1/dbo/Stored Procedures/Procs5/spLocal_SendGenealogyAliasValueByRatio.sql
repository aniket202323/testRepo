   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SendGenealogyAliasValueByRatio  
Author:   Matthew Wells (MSI)  
Date Created:  06/25/02  
  
Description:  
=========  
For the triggering variable it sends the value to any aliased variables associated with the next level in the event components.  
  
Change Date Who What  
=========== ==== =====  
06/25/02 MKW Created.  
10/03/03 MKW Removed Event_Type from the Variables Join as it was too expensive and causing the query to occasionally  
   take a really long time to execute.  
*/  
  
CREATE procedure dbo.spLocal_SendGenealogyAliasValueByRatio  
@Output_Value    varchar(25) OUTPUT,  
@Turnover_TimeStamp  datetime,  
@Var_Id   int  
As  
  
/* Testing   
Select  @Var_Id   = 5239, --4738, --4629,  
-- @Turnover_Event_Id =326400,  
 @Turnover_TimeStamp = '2002-06-03 15:42:57'  
*/  
SET NOCOUNT ON  
Declare @Value_Str   varchar(25),  
 @Value    float,  
 @CalcMgr_User_Id  int,  
 @EventMgr_User_Id  int,  
 @Turnover_Event_Id  int,  
 @Turnover_PU_Id  int,  
 @Event_Type   int,  
 @Production_Event_Type_Id int,  
 @Data_Type_Id   int,  
 @User_Id   int  
   
  
Select  @Output_Value    = Null,  
 @CalcMgr_User_Id  = 26,  
 @EventMgr_User_Id  = 6,  
 @User_Id   = Null,  
 @Value_Str   = Null,  
 @Turnover_PU_Id  = Null,  
 @Turnover_Event_Id  = Null,  
 @Event_Type   = Null,  
 @Production_Event_Type_Id = 1,  
 @Data_Type_Id   = Null  
  
Select  @Turnover_PU_Id = coalesce(pu.Master_Unit, pu.PU_Id),  
 @Event_Type  = Event_Type,  
 @Data_Type_Id  = Data_Type_Id  
From [dbo].Variables v  
     Inner Join [dbo].Prod_Units pu On v.PU_Id = pu.PU_Id  
Where v.Var_Id = @Var_ID  
  
If @Event_Type = @Production_Event_Type_Id And @Data_Type_Id = 2  
     Begin  
     Select @Turnover_Event_Id = Event_Id  
     From [dbo].Events  
     Where PU_Id = @Turnover_PU_Id And TimeStamp = @Turnover_TimeStamp  
  
     If @Turnover_Event_Id Is Not Null  
          Begin  
      
          Select  @Value_Str  = Result,  
  @User_Id = Entry_By  
          From [dbo].tests  
          Where Var_Id = @Var_Id And Result_On = @Turnover_TimeStamp  
  
          If isnumeric(@Value_Str) = 1 And @User_Id <> @EventMgr_User_Id  
               Begin  
               Select @Value = convert(float, @Value_Str)  
     -- user id for the resulset  
     SELECT @User_id = User_id   
     FROM [dbo].Users  
     WHERE username = 'Reliability System'  
  
               /* Return test results for any other rolls associated with this turnover */  
               Select 2,       -- Result_Set_Type  
        v.Var_Id,      -- Var_Id  
        v.PU_Id,      -- PU_Id  
        @User_id,     -- User_Id  
        0,       -- Canceled  
        ltrim(str(@Value*Dimension_A/100, 15, Var_Precision)),  -- Result  
        e.TimeStamp,      -- Result_On              
        Case When t.Test_Id Is Null Then 1  
         Else 2  
         End,      -- Transaction_Type  
        0       -- Post_Update  
               From [dbo].Event_Components ec  
                    Inner Join [dbo].Events e On ec.Event_Id = e.Event_Id  
                    Inner Join [dbo].Variables v On e.PU_Id = v.PU_Id --And Event_Type = @Production_Event_Type_Id  
                    Inner Join [dbo].Variable_Alias va On v.Var_Id = va.Dst_Var_Id And va.Src_Var_Id = @Var_Id  
                    Left Join [dbo].tests t On e.TimeStamp = t.Result_On And t.Var_Id = va.Dst_Var_Id --v.Var_Id  
               Where ec.Source_Event_Id = @Turnover_Event_Id  
  
               End  
          End  
     End  
  
SET NOCOUNT OFF  
  
