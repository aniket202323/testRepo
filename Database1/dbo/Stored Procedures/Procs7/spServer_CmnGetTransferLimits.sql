CREATE PROCEDURE dbo.spServer_CmnGetTransferLimits
@PU_Id int,
@Prod_Id int,
@TimeStamp datetime
AS
Declare
  @DefaultHistorian nVarChar(1000)
if (@TimeStamp is null)
 	 return
Select @DefaultHistorian = NULL
Select @DefaultHistorian = COALESCE(Alias,Hist_Servername) From Historians Where Hist_Default = 1
If (@DefaultHistorian Is NULL)
  Select @DefaultHistorian = ''
-------------------------------------------------------------------------------------------------------------
-- Get the specs for normal variables
-------------------------------------------------------------------------------------------------------------
Select Var_Id            = a.Var_Id,
       Var_Type          = a.Data_Type_Id,
       Spec_Id           = NULL,
       Spec_Type         = NULL,
       Array_Size        = NULL,
       UEL_Tag           = a.UEL_Tag,
       URL_Tag           = a.URL_Tag,
       UWL_Tag           = a.UWL_Tag,
       UUL_Tag           = a.UUL_Tag,
       Target_Tag        = a.Target_Tag,
       LUL_Tag           = a.LUL_Tag,
       LWL_Tag           = a.LWL_Tag,
       LRL_Tag           = a.LRL_Tag,
       LEL_Tag           = a.LEL_Tag,
       U_Entry           = vs.U_Entry,
       U_Reject          = vs.U_Reject,
       U_Warning         = vs.U_Warning,
       U_User            = vs.U_User,
       Target            = vs.Target,
       L_User            = vs.L_User,
       L_Warning         = vs.L_Warning,
       L_Reject          = vs.L_Reject,
       L_Entry           = vs.L_Entry,
       UELTagOnly        = CASE CharIndex('\\',a.UEL_Tag)    When 0 Then a.UEL_Tag         When 1 Then SubString(a.UEL_Tag,CharIndex('\',SubString(a.UEL_Tag,3,1000)) + 3,1000)       Else '' END,
       UELNodeName       = CASE CharIndex('\\',a.UEL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.UEL_Tag,3,CharIndex('\',SubString(a.UEL_Tag,3,1000)) - 1)         Else '' END,
       URLTagOnly        = CASE CharIndex('\\',a.URL_Tag)    When 0 Then a.URL_Tag         When 1 Then SubString(a.URL_Tag,CharIndex('\',SubString(a.URL_Tag,3,1000)) + 3,1000)       Else '' END,
       URLNodeName       = CASE CharIndex('\\',a.URL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.URL_Tag,3,CharIndex('\',SubString(a.URL_Tag,3,1000)) - 1)         Else '' END,
       UWLTagOnly        = CASE CharIndex('\\',a.UWL_Tag)    When 0 Then a.UWL_Tag         When 1 Then SubString(a.UWL_Tag,CharIndex('\',SubString(a.UWL_Tag,3,1000)) + 3,1000)       Else '' END,
       UWLNodeName       = CASE CharIndex('\\',a.UWL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.UWL_Tag,3,CharIndex('\',SubString(a.UWL_Tag,3,1000)) - 1)         Else '' END,
       UULTagOnly        = CASE CharIndex('\\',a.UUL_Tag)    When 0 Then a.UUL_Tag         When 1 Then SubString(a.UUL_Tag,CharIndex('\',SubString(a.UUL_Tag,3,1000)) + 3,1000)       Else '' END,
       UULNodeName       = CASE CharIndex('\\',a.UUL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.UUL_Tag,3,CharIndex('\',SubString(a.UUL_Tag,3,1000)) - 1)         Else '' END,
       TargetTagOnly     = CASE CharIndex('\\',a.Target_Tag) When 0 Then a.Target_Tag      When 1 Then SubString(a.Target_Tag,CharIndex('\',SubString(a.Target_Tag,3,1000)) + 3,1000) Else '' END,
       TargetNodeName    = CASE CharIndex('\\',a.Target_Tag) When 0 Then @DefaultHistorian When 1 Then SubString(a.Target_Tag,3,CharIndex('\',SubString(a.Target_Tag,3,1000)) - 1)   Else '' END,
       LULTagOnly        = CASE CharIndex('\\',a.LUL_Tag)    When 0 Then a.LUL_Tag         When 1 Then SubString(a.LUL_Tag,CharIndex('\',SubString(a.LUL_Tag,3,1000)) + 3,1000)       Else '' END,
       LULNodeName       = CASE CharIndex('\\',a.LUL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LUL_Tag,3,CharIndex('\',SubString(a.LUL_Tag,3,1000)) - 1)         Else '' END,
       LWLTagOnly        = CASE CharIndex('\\',a.LWL_Tag)    When 0 Then a.LWL_Tag         When 1 Then SubString(a.LWL_Tag,CharIndex('\',SubString(a.LWL_Tag,3,1000)) + 3,1000)       Else '' END,
       LWLNodeName       = CASE CharIndex('\\',a.LWL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LWL_Tag,3,CharIndex('\',SubString(a.LWL_Tag,3,1000)) - 1)         Else '' END,
       LRLTagOnly        = CASE CharIndex('\\',a.LRL_Tag)    When 0 Then a.LRL_Tag         When 1 Then SubString(a.LRL_Tag,CharIndex('\',SubString(a.LRL_Tag,3,1000)) + 3,1000)       Else '' END,
       LRLNodeName       = CASE CharIndex('\\',a.LRL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LRL_Tag,3,CharIndex('\',SubString(a.LRL_Tag,3,1000)) - 1)         Else '' END,
       LELTagOnly        = CASE CharIndex('\\',a.LEL_Tag)    When 0 Then a.LEL_Tag         When 1 Then SubString(a.LEL_Tag,CharIndex('\',SubString(a.LEL_Tag,3,1000)) + 3,1000)       Else '' END,
       LELNodeName       = CASE CharIndex('\\',a.LEL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LEL_Tag,3,CharIndex('\',SubString(a.LEL_Tag,3,1000)) - 1)         Else '' END
  From Variables_Base a 
  Left Outer Join Var_Specs vs
        on (vs.Var_Id = a.Var_Id) And 
           (vs.Prod_Id = @Prod_Id) And
           (vs.Effective_Date <= @TimeStamp) And 
           ((vs.Expiration_Date > @TimeStamp) Or (vs.Expiration_Date Is Null))
  Where (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @PU_Id) Or (Master_Unit = @PU_Id))) And
        ((a.UEL_Tag Is Not Null) Or 
         (a.URL_Tag Is Not Null) Or 
         (a.UWL_Tag Is Not Null) Or 
         (a.UUL_Tag Is Not Null) Or 
         (a.Target_Tag Is Not Null) Or 
         (a.LUL_Tag Is Not Null) Or 
         (a.LWL_Tag Is Not Null) Or 
         (a.LRL_Tag Is Not Null) Or 
         (a.LEL_Tag Is Not Null)) And
        (not (a.Data_Type_Id In (6,7,8) and a.Spec_Id is not null)) and
((a.Write_Group_DS_Id < 50000) or (a.Write_Group_DS_Id is Null))
-------------------------------------------------------------------------------------------------------------
-- Get the parent specs for array specs
-------------------------------------------------------------------------------------------------------------
union
Select Var_Id            = a.Var_Id,
       Var_Type          = a.Data_Type_Id,
       Spec_Id           = s.Spec_Id,
       Spec_Type         = s.Data_Type_Id,
       Array_Size        = s.Array_Size,
       UEL_Tag           = a.UEL_Tag,
       URL_Tag           = a.URL_Tag,
       UWL_Tag           = a.UWL_Tag,
       UUL_Tag           = a.UUL_Tag,
       Target_Tag        = a.Target_Tag,
       LUL_Tag           = a.LUL_Tag,
       LWL_Tag           = a.LWL_Tag,
       LRL_Tag           = a.LRL_Tag,
       LEL_Tag           = a.LEL_Tag,
       U_Entry           = NULL,
       U_Reject          = NULL,
       U_Warning         = NULL,
       U_User            = NULL,
       Target            = NULL,
       L_User            = NULL,
       L_Warning         = NULL,
       L_Reject          = NULL,
       L_Entry           = NULL,
       UELTagOnly        = CASE CharIndex('\\',a.UEL_Tag)    When 0 Then a.UEL_Tag         When 1 Then SubString(a.UEL_Tag,CharIndex('\',SubString(a.UEL_Tag,3,1000)) + 3,1000)       Else '' END,
       UELNodeName       = CASE CharIndex('\\',a.UEL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.UEL_Tag,3,CharIndex('\',SubString(a.UEL_Tag,3,1000)) - 1)         Else '' END,
       URLTagOnly        = CASE CharIndex('\\',a.URL_Tag)    When 0 Then a.URL_Tag         When 1 Then SubString(a.URL_Tag,CharIndex('\',SubString(a.URL_Tag,3,1000)) + 3,1000)       Else '' END,
       URLNodeName       = CASE CharIndex('\\',a.URL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.URL_Tag,3,CharIndex('\',SubString(a.URL_Tag,3,1000)) - 1)         Else '' END,
       UWLTagOnly        = CASE CharIndex('\\',a.UWL_Tag)    When 0 Then a.UWL_Tag         When 1 Then SubString(a.UWL_Tag,CharIndex('\',SubString(a.UWL_Tag,3,1000)) + 3,1000)       Else '' END,
       UWLNodeName       = CASE CharIndex('\\',a.UWL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.UWL_Tag,3,CharIndex('\',SubString(a.UWL_Tag,3,1000)) - 1)         Else '' END,
       UULTagOnly        = CASE CharIndex('\\',a.UUL_Tag)    When 0 Then a.UUL_Tag         When 1 Then SubString(a.UUL_Tag,CharIndex('\',SubString(a.UUL_Tag,3,1000)) + 3,1000)       Else '' END,
       UULNodeName       = CASE CharIndex('\\',a.UUL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.UUL_Tag,3,CharIndex('\',SubString(a.UUL_Tag,3,1000)) - 1)         Else '' END,
       TargetTagOnly     = CASE CharIndex('\\',a.Target_Tag) When 0 Then a.Target_Tag      When 1 Then SubString(a.Target_Tag,CharIndex('\',SubString(a.Target_Tag,3,1000)) + 3,1000) Else '' END,
       TargetNodeName    = CASE CharIndex('\\',a.Target_Tag) When 0 Then @DefaultHistorian When 1 Then SubString(a.Target_Tag,3,CharIndex('\',SubString(a.Target_Tag,3,1000)) - 1)   Else '' END,
       LULTagOnly        = CASE CharIndex('\\',a.LUL_Tag)    When 0 Then a.LUL_Tag         When 1 Then SubString(a.LUL_Tag,CharIndex('\',SubString(a.LUL_Tag,3,1000)) + 3,1000)       Else '' END,
       LULNodeName       = CASE CharIndex('\\',a.LUL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LUL_Tag,3,CharIndex('\',SubString(a.LUL_Tag,3,1000)) - 1)         Else '' END,
       LWLTagOnly        = CASE CharIndex('\\',a.LWL_Tag)    When 0 Then a.LWL_Tag         When 1 Then SubString(a.LWL_Tag,CharIndex('\',SubString(a.LWL_Tag,3,1000)) + 3,1000)       Else '' END,
       LWLNodeName       = CASE CharIndex('\\',a.LWL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LWL_Tag,3,CharIndex('\',SubString(a.LWL_Tag,3,1000)) - 1)         Else '' END,
       LRLTagOnly        = CASE CharIndex('\\',a.LRL_Tag)    When 0 Then a.LRL_Tag         When 1 Then SubString(a.LRL_Tag,CharIndex('\',SubString(a.LRL_Tag,3,1000)) + 3,1000)       Else '' END,
       LRLNodeName       = CASE CharIndex('\\',a.LRL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LRL_Tag,3,CharIndex('\',SubString(a.LRL_Tag,3,1000)) - 1)         Else '' END,
       LELTagOnly        = CASE CharIndex('\\',a.LEL_Tag)    When 0 Then a.LEL_Tag         When 1 Then SubString(a.LEL_Tag,CharIndex('\',SubString(a.LEL_Tag,3,1000)) + 3,1000)       Else '' END,
       LELNodeName       = CASE CharIndex('\\',a.LEL_Tag)    When 0 Then @DefaultHistorian When 1 Then SubString(a.LEL_Tag,3,CharIndex('\',SubString(a.LEL_Tag,3,1000)) - 1)         Else '' END
  From Variables_Base a 
  Join Specifications s
        on (a.Spec_Id = s.Spec_Id) 
  Join PU_Characteristics c
        on ((c.PU_id   = a.PU_Id) AND
           (c.Prod_Id = @Prod_Id) AND
           (c.Prop_Id = s.Prop_Id))
  Where (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @PU_Id) Or (Master_Unit = @PU_Id))) And
        ((a.UEL_Tag Is Not Null) Or 
         (a.URL_Tag Is Not Null) Or 
         (a.UWL_Tag Is Not Null) Or 
         (a.UUL_Tag Is Not Null) Or 
         (a.Target_Tag Is Not Null) Or 
         (a.LUL_Tag Is Not Null) Or 
         (a.LWL_Tag Is Not Null) Or 
         (a.LRL_Tag Is Not Null) Or 
         (a.LEL_Tag Is Not Null)) And
        (a.Data_Type_Id In (6,7,8)) and
((a.Write_Group_DS_Id < 50000) or (a.Write_Group_DS_Id is Null))
-------------------------------------------------------------------------------------------------------------
-- Get the specs for normal variables and the parent variable for array specs
-------------------------------------------------------------------------------------------------------------
Select Parent_Spec_Id   = s.Parent_Id,
       Spec_Id          = s.Spec_Id,
       Array_Order      = s.Spec_Order,
       Element_Type     = s.Data_Type_Id,
       U_Entry          = act.U_Entry,
       U_Reject         = act.U_Reject,
       U_Warning        = act.U_Warning,
       U_User           = act.U_User,
       Target           = act.Target,
       L_User           = act.L_User,
       L_Warning        = act.L_Warning,
       L_Reject         = act.L_Reject,
       L_Entry          = act.L_Entry
  From Specifications s 
  join PU_Characteristics c
         on (c.PU_id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @PU_Id) Or (Master_Unit = @PU_Id)) and
             (c.Prod_Id = @Prod_Id) AND
             (c.Prop_Id = s.Prop_Id))
  Join Active_Specs act 
            on (act.Spec_Id = s.Spec_Id) And 
               (act.Char_Id = c.Char_Id) And
           (act.Effective_Date <= @TimeStamp) And 
           ((act.Expiration_Date > @TimeStamp) Or (act.Expiration_Date Is Null))
  Where (s.Parent_Id in (Select s.Spec_Id From Variables_Base a Join Specifications s on (a.Spec_Id = s.Spec_Id)
                                               join PU_Characteristics c on ((c.PU_id   = a.PU_Id) AND
                                                                            (c.Prod_Id = @Prod_Id) AND
                                                                            (c.Prop_Id = s.Prop_Id))
                          Where (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @PU_Id) Or (Master_Unit = @PU_Id))) And
                                ((a.UEL_Tag Is Not Null) Or (a.URL_Tag Is Not Null) Or (a.UWL_Tag Is Not Null) Or (a.UUL_Tag Is Not Null) Or 
                                 (a.Target_Tag Is Not Null) Or (a.LUL_Tag Is Not Null) Or (a.LWL_Tag Is Not Null) Or (a.LRL_Tag Is Not Null) Or 
                                 (a.LEL_Tag Is Not Null)) And (s.Array_Size Is Not Null)))
  order by Parent_Id, Array_Order
